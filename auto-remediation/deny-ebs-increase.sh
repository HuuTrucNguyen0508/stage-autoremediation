#!/bin/bash

# Deny EBS Volume Increase - Updates approval status to rejected
# This script is called when someone triggers /hooks/deny-the-increase

# Log the webhook call
echo "$(date): EBS increase denial received - Text: $1, User: $2, Channel: $3, Timestamp: $4" >> webhook.log

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

**Status**: No approval request to reject
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
APPROVAL_ID=$(echo "$APPROVAL_DATA" | awk -F'"' '/"approval_id":/ {print $4}')
CURRENT_STATUS=$(echo "$APPROVAL_DATA" | awk -F'"' '/"status":/ {print $4}')

# Debug logging
echo "$(date): Debug - Approval data: $APPROVAL_DATA" >> webhook.log
echo "$(date): Debug - Approval ID: $APPROVAL_ID" >> webhook.log
echo "$(date): Debug - Current status: $CURRENT_STATUS" >> webhook.log

if [ "$CURRENT_STATUS" != "pending" ]; then
    echo "$(date): ERROR - Approval status is not pending: $CURRENT_STATUS" >> webhook.log
    
    # Send error message to Mattermost
    ERROR_MESSAGE="❌ **EBS Increase Request Already Processed**

**Approval ID**: $APPROVAL_ID
**Current Status**: $CURRENT_STATUS
**Timestamp**: $(date -d '+2 hours' -Iseconds)

**Note**: This request has already been processed and cannot be rejected"

    curl -X POST "$WEBHOOK_URL" \
      -H "Content-Type: application/json" \
      -d "{
        \"text\": \"$ERROR_MESSAGE\",
        \"username\": \"Auto-Remediation Bot\",
        \"icon_emoji\": \":robot_face:\"
      }" >> webhook.log 2>&1
    
    exit 1
fi

echo "$(date): Processing rejection for ID: $APPROVAL_ID" >> webhook.log

# Update approval status to rejected
cat > "$APPROVAL_FILE" << EOF
{
  "approval_id": "$APPROVAL_ID",
  "status": "rejected",
  "requested_at": "$(echo "$APPROVAL_DATA" | grep -o '"requested_at":"[^"]*"' | cut -d'"' -f4)",
  "rejected_at": "$(date -d '+2 hours' -Iseconds)",
  "rejected_by": "$2",
  "current_size": $(echo "$APPROVAL_DATA" | grep -o '"current_size":[[:space:]]*[0-9]*' | cut -d':' -f2 | tr -d ' ,'),
  "new_size": $(echo "$APPROVAL_DATA" | grep -o '"new_size":[[:space:]]*[0-9]*' | cut -d':' -f2 | tr -d ' ,'),
  "increment": $(echo "$APPROVAL_DATA" | grep -o '"increment":[[:space:]]*[0-9]*' | cut -d':' -f2 | tr -d ' ,'),
  "reason": "Rejected by $2"
}
EOF

# Send rejection confirmation to Mattermost
REJECTION_MESSAGE="❌ **EBS Increase Request Rejected**

**Approval ID**: $APPROVAL_ID
**Rejected By**: $2
**Timestamp**: $(date -d '+2 hours' -Iseconds)

**Status**: ❌ Request rejected - no action taken
**Action**: EBS volume size remains unchanged

**Note**: The auto-remediation process has been cancelled
**Current Volume Size**: $(echo "$APPROVAL_DATA" | grep -o '"current_size":[[:space:]]*[0-9]*' | cut -d':' -f2 | tr -d ' ,')GB

**To request again**: Use \`/hooks/callMattermost\` to create a new request"

curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"text\": \"$REJECTION_MESSAGE\",
    \"username\": \"Auto-Remediation Bot\",
    \"icon_emoji\": \":robot_face:\"
  }" >> webhook.log 2>&1

echo "$(date): Successfully rejected EBS increase request ID: $APPROVAL_ID" >> webhook.log
echo "✅ EBS increase request rejected for approval ID: $APPROVAL_ID"

exit 0
