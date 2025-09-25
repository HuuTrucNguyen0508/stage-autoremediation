#!/bin/bash

# Request EBS Volume Increase - Sends approval request to Mattermost
# This script is called when someone triggers /hooks/callMattermost

# Log the webhook call
echo "$(date): EBS increase request received - Text: $1, User: $2, Channel: $3, Timestamp: $4" >> webhook.log

# Load Mattermost configuration
MATTERMOST_CONFIG="/opt/automation/auto-remediation/mattermost-config.yml"
if [ ! -f "$MATTERMOST_CONFIG" ]; then
    echo "$(date): ERROR - Mattermost config file not found: $MATTERMOST_CONFIG" >> webhook.log
    exit 1
fi

# Extract webhook URL from config (simple parsing)
WEBHOOK_URL=$(grep "mattermost_webhook_url:" "$MATTERMOST_CONFIG" | cut -d':' -f2- | tr -d ' "')
if [ -z "$WEBHOOK_URL" ]; then
    echo "$(date): ERROR - Could not extract webhook URL from config" >> webhook.log
    exit 1
fi

# Create approval request ID
APPROVAL_ID=$(date +%s)
echo "$(date): Created approval request ID: $APPROVAL_ID" >> webhook.log

# Get current volume size from Terraform
TERRAFORM_DIR="/opt/automation/auto-remediation/../terraform"
JSON_FILE="$TERRAFORM_DIR/mongodb_size.auto.tfvars.json"

if [ ! -f "$JSON_FILE" ]; then
    echo "$(date): ERROR - MongoDB size config not found: $JSON_FILE" >> webhook.log
    exit 1
fi

# Read current volume size
CURRENT_SIZE=$(grep -o '"mongodb_volume_size":[[:space:]]*[0-9]*' "$JSON_FILE" | cut -d':' -f2 | tr -d ' ,')
if [ -z "$CURRENT_SIZE" ]; then
    echo "$(date): ERROR - Could not read current volume size from $JSON_FILE" >> webhook.log
    exit 1
fi

# Calculate new size (add 10GB)
NEW_SIZE=$((CURRENT_SIZE + 10))

echo "$(date): Current size: ${CURRENT_SIZE}GB, New size: ${NEW_SIZE}GB" >> webhook.log

# Create approval status file
APPROVAL_FILE="/opt/automation/auto-remediation/approval_status.json"
cat > "$APPROVAL_FILE" << EOF
{
  "approval_id": "$APPROVAL_ID",
  "status": "pending",
  "requested_at": "$(date -d '+2 hours' -Iseconds)",
  "current_size": $CURRENT_SIZE,
  "new_size": $NEW_SIZE,
  "increment": 10,
  "requested_by": "$2",
  "channel": "$3"
}
EOF

# Send approval request to Mattermost
MATTERMOST_MESSAGE="🚨 **EBS Volume Increase Request - Approval Required**

**Action**: MongoDB EBS Volume Expansion
**Current Size**: ${CURRENT_SIZE}GB
**New Size**: ${NEW_SIZE}GB
**Increment**: +10GB
**Approval ID**: ${APPROVAL_ID}
**Requested By**: $2
**Channel**: $3

**To Approve**: Reply with \`✅ APPROVE ${APPROVAL_ID}\`
**To Reject**: Reply with \`❌ REJECT ${APPROVAL_ID}\`

**Status**: ⏳ Waiting for approval
**Timestamp**: $(date -d '+2 hours' -Iseconds)

**Note**: This will trigger Terraform to increase the EBS volume size."

# Send webhook to Mattermost
curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"text\": \"$MATTERMOST_MESSAGE\",
    \"username\": \"Auto-Remediation Bot\",
    \"icon_emoji\": \":robot_face:\"
  }" >> webhook.log 2>&1

if [ $? -eq 0 ]; then
    echo "$(date): Successfully sent approval request to Mattermost for ID: $APPROVAL_ID" >> webhook.log
    echo "✅ EBS increase request sent to Mattermost. Approval ID: $APPROVAL_ID"
else
    echo "$(date): ERROR - Failed to send approval request to Mattermost" >> webhook.log
    echo "❌ Failed to send approval request to Mattermost"
    exit 1
fi

exit 0
