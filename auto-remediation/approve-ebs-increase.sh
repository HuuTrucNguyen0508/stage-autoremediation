#!/bin/bash

# Approve EBS Volume Increase - Complete approval workflow handler
# This script is called when someone triggers /hooks/proceed-to-increase

# Log the webhook call
echo "$(date): EBS increase approval received - Text: $1, User: $2, Channel: $3, Timestamp: $4" >> webhook.log

# Load Mattermost configuration
MATTERMOST_CONFIG="/opt/automation/auto-remediation/mattermost-config.yml"
if [ ! -f "$MATTERMOST_CONFIG" ]; then
    echo "$(date): ERROR - Mattermost config file not found: $MATTERMOST_CONFIG" >> webhook.log
    exit 1
fi

# Extract webhook URL from config
WEBHOOK_URL=$(grep "mattermost_webhook_url:" "$MATTERMOST_CONFIG" | cut -d':' -f2- | tr -d ' "')
if [ -z "$WEBHOOK_URL" ]; then
    echo "$(date): ERROR - Could not extract webhook URL from config" >> webhook.log
    exit 1
fi

# Check if there's a pending approval
APPROVAL_FILE="/opt/automation/auto-remediation/approval_status.json"
if [ ! -f "$APPROVAL_FILE" ]; then
    echo "$(date): ERROR - No pending approval found" >> webhook.log
    
    # Send error message to Mattermost
    ERROR_MESSAGE="❌ **No Pending EBS Increase Request Found**

**Status**: No approval request to process
**Timestamp**: $(date -d '+2 hours' -Iseconds)

**Note**: Please trigger an EBS increase request first using \`/hooks/callMattermost\`"

    curl -X POST "$WEBHOOK_URL" \
      -H "Content-Type: application/json" \
      -d "{
        \"text\": \"$ERROR_MESSAGE\",
        \"username\": \"Auto-Remediation Bot\",
        \"icon_emoji\": \":robot_face:\"
      }" >> webhook.log 2>&1
    
    exit 1
fi

# Read approval status
APPROVAL_DATA=$(cat "$APPROVAL_FILE")
echo "$(date): Debug - Raw file content: $APPROVAL_DATA" >> webhook.log

# Try different parsing methods
APPROVAL_ID=$(echo "$APPROVAL_DATA" | awk -F'"' '/"approval_id":/ {print $4}')
echo "$(date): Debug - awk result for approval_id: $APPROVAL_ID" >> webhook.log

# Alternative method using grep and cut
APPROVAL_ID_ALT=$(echo "$APPROVAL_DATA" | grep -o '"approval_id":"[^"]*"' | cut -d'"' -f4)
echo "$(date): Debug - grep/cut result for approval_id: $APPROVAL_ID_ALT" >> webhook.log

# Use the alternative method if awk failed
if [ -z "$APPROVAL_ID" ]; then
    APPROVAL_ID="$APPROVAL_ID_ALT"
    echo "$(date): Debug - Using alternative method for approval_id: $APPROVAL_ID" >> webhook.log
fi

CURRENT_STATUS=$(echo "$APPROVAL_DATA" | awk -F'"' '/"status":/ {print $4}')
echo "$(date): Debug - awk result for status: $CURRENT_STATUS" >> webhook.log

# Alternative method for status
CURRENT_STATUS_ALT=$(echo "$APPROVAL_DATA" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
echo "$(date): Debug - grep/cut result for status: $CURRENT_STATUS_ALT" >> webhook.log

# Use the alternative method if awk failed
if [ -z "$CURRENT_STATUS" ]; then
    CURRENT_STATUS="$CURRENT_STATUS_ALT"
    echo "$(date): Debug - Using alternative method for status: $CURRENT_STATUS" >> webhook.log
fi

# Final debug logging
echo "$(date): Debug - Final Approval ID: $APPROVAL_ID" >> webhook.log
echo "$(date): Debug - Final Current status: $CURRENT_STATUS" >> webhook.log

if [ "$CURRENT_STATUS" != "pending" ]; then
    echo "$(date): ERROR - Approval status is not pending: $CURRENT_STATUS" >> webhook.log
    
    # Send error message to Mattermost
    ERROR_MESSAGE="❌ **EBS Increase Request Already Processed**

**Approval ID**: $APPROVAL_ID
**Current Status**: $CURRENT_STATUS
**Timestamp**: $(date -d '+2 hours' -Iseconds)

**Note**: This request has already been processed"

    curl -X POST "$WEBHOOK_URL" \
      -H "Content-Type: application/json" \
      -d "{
        \"text\": \"$ERROR_MESSAGE\",
        \"username\": \"Auto-Remediation Bot\",
        \"icon_emoji\": \":robot_face:\"
      }" >> webhook.log 2>&1
    
    exit 1
fi

echo "$(date): Processing approval for ID: $APPROVAL_ID" >> webhook.log

# Update approval status to approved
cat > "$APPROVAL_FILE" << EOF
{
  "approval_id": "$APPROVAL_ID",
  "status": "approved",
  "requested_at": "$(echo "$APPROVAL_DATA" | grep -o '"requested_at":"[^"]*"' | cut -d'"' -f4)",
  "approved_at": "$(date -d '+2 hours' -Iseconds)",
  "approved_by": "$2",
  "current_size": $(echo "$APPROVAL_DATA" | grep -o '"current_size":[[:space:]]*[0-9]*' | cut -d':' -f2 | tr -d ' ,'),
  "new_size": $(echo "$APPROVAL_DATA" | grep -o '"new_size":[[:space:]]*[0-9]*' | cut -d':' -f2 | tr -d ' ,'),
  "increment": $(echo "$APPROVAL_DATA" | grep -o '"increment":[[:space:]]*[0-9]*' | cut -d':' -f2 | tr -d ' ,')
}
EOF

# Send approval confirmation to Mattermost
APPROVAL_MESSAGE="✅ **EBS Increase Request Approved**

**Approval ID**: $APPROVAL_ID
**Approved By**: $2
**Timestamp**: $(date -d '+2 hours' -Iseconds)

**Status**: 🚀 Starting auto-remediation process...
**Action**: Running Ansible playbook to increase EBS volume

**Note**: This process will:
1. Update Terraform configuration
2. Apply EBS volume changes
3. Extend filesystem
4. Send completion notification"

curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"text\": \"$APPROVAL_MESSAGE\",
    \"username\": \"Auto-Remediation Bot\",
    \"icon_emoji\": \":robot_face:\"
  }" >> webhook.log 2>&1

# Run the auto-remediation playbook (Terraform operations only)
echo "$(date): Starting auto-remediation playbook for approved request: $APPROVAL_ID" >> webhook.log

cd /opt/automation/auto-remediation
ansible-playbook auto-remediation-playbook.yml --connection=local -e "skip_approval=true" >> webhook.log 2>&1

AUTO_PLAYBOOK_EXIT_CODE=$?

if [ $AUTO_PLAYBOOK_EXIT_CODE -eq 0 ]; then
    echo "$(date): Auto-remediation playbook completed successfully for ID: $APPROVAL_ID" >> webhook.log

    # Run extend-backend playbook using inventory file
    ansible-playbook extend-backend-disk-ubuntu.yml -i ../ansible/inventory/hosts.yml >> webhook2.log 2>&1
    # Send success message to Mattermost
    SUCCESS_MESSAGE="🎉 **EBS Volume Increase Completed Successfully**

**Approval ID**: $APPROVAL_ID
**Status**: ✅ Auto-remediation completed
**Timestamp**: $(date -d '+2 hours' -Iseconds)

**Result**: MongoDB EBS volume has been increased and filesystem extended
**Next Steps**: Monitor application health and verify new volume size

**Note**: The volume expansion process is now complete!"

    curl -X POST "$WEBHOOK_URL" \
      -H "Content-Type: application/json" \
      -d "{
        \"text\": \"$SUCCESS_MESSAGE\",
        \"username\": \"Auto-Remediation Bot\",
        \"icon_emoji\": \":robot_face:\"
      }" >> webhook.log 2>&1
    
    echo "✅ EBS increase completed successfully for approval ID: $APPROVAL_ID"
else
    echo "$(date): ERROR - Auto-remediation playbook failed with exit code: $AUTO_PLAYBOOK_EXIT_CODE" >> webhook.log
    
    # Send failure message to Mattermost
    FAILURE_MESSAGE="❌ **EBS Volume Increase Failed**

**Approval ID**: $APPROVAL_ID
**Status**: ❌ Auto-remediation failed
**Exit Code**: $AUTO_PLAYBOOK_EXIT_CODE
**Timestamp**: $(date -d '+2 hours' -Iseconds)

**Error**: The auto-remediation playbook failed during execution
**Next Steps**: Check logs and investigate the failure

**Note**: Manual intervention may be required"

    curl -X POST "$WEBHOOK_URL" \
      -H "Content-Type: application/json" \
      -d "{
        \"text\": \"$FAILURE_MESSAGE\",
        \"username\": \"Auto-Remediation Bot\",
        \"icon_emoji\": \":robot_face:\"
      }" >> webhook.log 2>&1
    
    echo "❌ EBS increase failed for approval ID: $APPROVAL_ID"
    exit 1
fi

exit 0
