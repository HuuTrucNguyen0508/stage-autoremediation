# Auto-Remediation System for EBS Volume Expansion

This auto-remediation system provides automated infrastructure response to resource constraints with operator oversight through Mattermost notifications and approval workflows.

## 🚀 Features

- **EBS Volume Auto-Scaling**: Automatic disk space management with Terraform
- **Mattermost Integration**: Real-time operator notifications and approval requests
- **Approval Workflow**: Manual confirmation required before infrastructure changes
- **Terraform Automation**: Safe infrastructure modifications after operator approval
- **Webhook Integration**: Seamless Alertmanager to auto-remediation pipeline
- **Comprehensive Logging**: Detailed audit trail of all remediation activities

## 📁 Files

- `auto-remediation-playbook.yml` - Main Ansible playbook
- `extend-backend-disk-ubuntu` - Playbook to extend the file system
- `mattermost-config.yml` - File containing Mattermost URL
- `hooks.yaml` - Webhook configuration for triggering auto-remediation

## 🛠️ Prerequisites

1. **Ansible** installed on the auto-remediation runner
2. **Terraform** installed and configured with AWS provider
3. **Mattermost webhook URL** configured for notifications
4. **AWS credentials** configured for Terraform operations
5. **Alertmanager** configured to send webhooks to the runner
6. **Operator access** to Mattermost for approval workflow

## ⚙️ Configuration

### 1. Configure Mattermost Integration

Set environment variables:

```bash
export MATTERMOST_WEBHOOK_URL="https://your-mattermost-server.com/hooks/your-webhook-id"
export MATTERMOST_CHANNEL="#infrastructure-alerts"
```

Update `mattermost-config.yml` with your webhook details:

```yaml
mattermost:
  webhook_url: "{{ mattermost_webhook_url }}"
  channel: "{{ mattermost_channel | default('#infrastructure-alerts') }}"
  username: "Auto-Remediation Bot"
  icon_emoji: ":warning:"
```

### 2. Configure Alertmanager Webhooks

Update `hooks.yaml` for Alertmanager integration:

```yaml
webhook_configs:
  - url: 'http://auto-remediation-runner:8080/webhook'
    send_resolved: true
    http_config:
      basic_auth:
        username: 'alertmanager'
        password: 'your-webhook-password'
```

### 3. Verify Terraform Configuration

Ensure your Terraform configuration supports EBS volume modifications:

```bash
variable "backend_ebs_volume_size" {
  description = "Size of backend EBS volume in GB"
  type        = number
  default     = 20
}

resource "aws_ebs_volume" "backend" {
  availability_zone = aws_instance.backend.availability_zone
  size              = var.backend_ebs_volume_size
  type              = "gp3"
  encrypted         = true
  tags = {
    Name = "truh1-backend-ebs-volume"
  }
}
```

## 🚀 Usage

### Automatic Trigger (Recommended)

The system automatically triggers when:

1. **Alertmanager** detects resource constraints (e.g., high disk usage)
2. **Webhook** is sent to the auto-remediation runner
3. **Mattermost notification** is sent to operators
4. **Operator approval** is required before proceeding
5. **Terraform apply** executes after confirmation

### Manual Execution

For testing or emergency situations:

```bash
cd auto-remediation

# Test the EBS increase workflow
ansible-playbook ebs-increase-playbook.yml \
  -e "target_instance=i-1234567890abcdef0" \
  -e "new_volume_size=30"

# Process manual approval
./approve-ebs-increase.sh <request-id>

# Or deny a request
./deny-ebs-increase.sh <request-id>
```

## 📊 Auto-Remediation Workflow

### Phase 1: Detection and Notification

1. **Alert Detection**: Prometheus detects high disk usage (>80%)
2. **Alertmanager Webhook**: Sends notification to auto-remediation runner
3. **Request Generation**: Creates EBS increase request with approval requirement
4. **Mattermost Notification**: Informs operators of the pending request

### Phase 2: Approval Process

5. **Operator Review**: Team reviews the request in Mattermost
6. **Manual Approval**: Operator approves or denies via Mattermost or scripts
7. **Status Update**: Approval status is logged in `approval_status.json`

### Phase 3: Infrastructure Modification

8. **Terraform Plan**: Shows proposed infrastructure changes
9. **Terraform Apply**: Executes approved changes after confirmation
10. **Verification**: Confirms successful volume expansion
11. **Final Notification**: Reports completion status to Mattermost

## 🔔 Mattermost Notifications

### Initial Alert Notification

```text
🚨 Infrastructure Alert - Approval Required

**Action**: EBS Volume Expansion
**Instance**: i-1234567890abcdef0 (truh1-backend)
**Current Size**: 20GB
**Proposed Size**: 30GB
**Disk Usage**: 85% (trigger threshold: 80%)
**Status**: ⏳ Awaiting operator approval

**Commands**:
• Approve: `./approve-ebs-increase.sh REQ-001`
• Deny: `./deny-ebs-increase.sh REQ-001`
```

### Approval Notification

```text
✅ Auto-Remediation Approved

**Action**: EBS Volume Expansion
**Instance**: i-1234567890abcdef0 (truh1-backend)
**Approved By**: operator@company.com
**Status**: 🔄 Executing Terraform changes...
```

### Completion Notification

```text
✅ Auto-Remediation Completed Successfully

**Action**: EBS Volume Expansion
**Instance**: i-1234567890abcdef0 (truh1-backend)
**Previous Size**: 20GB → **New Size**: 30GB
**Duration**: 3 minutes 42 seconds
**Status**: ✅ Infrastructure updated successfully
```

## 🚨 Error Handling

### Automatic Error Recovery

- **Webhook Failures**: Retry mechanism with exponential backoff
- **Terraform Failures**: Automatic rollback on apply failures
- **AWS API Errors**: Graceful handling with detailed error reporting
- **Approval Timeout**: Automatic request expiration after 30 minutes

### Error Notifications

- **Mattermost Alerts**: Real-time error notifications to operators
- **Detailed Logging**: Comprehensive logs in `/var/log/auto-remediation/`
- **Status Tracking**: Error states recorded in `approval_status.json`
- **Manual Intervention**: Clear escalation paths for manual resolution

## 🔧 Customization

### Modify Volume Increment

Update the volume expansion logic in `ebs-increase-playbook.yml`:

```yaml
vars:
  volume_increment: 10  # GB to add per expansion
  max_volume_size: 100  # Maximum allowed size
  min_free_space: 20    # Minimum free space percentage
```

### Configure Approval Timeout

Modify approval workflow settings:

```yaml
approval_settings:
  timeout_minutes: 30
  auto_deny_on_timeout: false
  escalation_channels: ['#infrastructure-critical']
```

### Customize Terraform Behavior

Update Terraform execution parameters:

```yaml
terraform_config:
  plan_timeout: 300     # seconds
  apply_timeout: 600    # seconds
  auto_approve: false   # require manual confirmation
  backup_state: true    # backup state before changes
```

## 📝 Logging and Monitoring

### Log Files

- **Main Log**: `/var/log/auto-remediation/auto-remediation.log`
- **Terraform Log**: `/var/log/auto-remediation/terraform.log`
- **Webhook Log**: `auto-remediation/webhook.log`
- **Approval Log**: `/var/log/auto-remediation/approvals.log`

### Log Content

- **Request Lifecycle**: Complete audit trail from alert to completion
- **Terraform Operations**: Detailed plan and apply output
- **Approval Workflow**: Who approved/denied and when
- **Error Details**: Stack traces and remediation suggestions
- **Performance Metrics**: Execution times and resource usage

## 🔒 Security Considerations

### Access Control

- **IAM Roles**: Least privilege principle for Terraform operations
- **Webhook Authentication**: Secure webhook endpoints with authentication
- **Approval Authorization**: Verify operator permissions before approval
- **Network Segmentation**: Isolate auto-remediation runner in private subnet

### Data Protection

- **Secrets Management**: Secure storage of Mattermost webhooks and API keys
- **Audit Logging**: Immutable logs for compliance and forensics
- **State File Security**: Encrypted Terraform state with restricted access
- **Communication Encryption**: TLS for all external communications

## 🚀 Deployment Steps

### 1. Initial Setup

```bash
# Configure Mattermost webhook
export MATTERMOST_WEBHOOK_URL="https://your-mattermost-server.com/hooks/webhook-id"

# Deploy auto-remediation runner
cd ansible
ansible-playbook -i inventory/hosts.yml playbooks/deploy-automation-runner-ubuntu.yml
```

### 2. Configure Alertmanager

```bash
# Update Alertmanager configuration
cd auto-remediation
cp hooks.yaml /path/to/alertmanager/
sudo systemctl restart alertmanager
```

### 3. Test the Workflow

```bash
# Test Mattermost notifications
./test-mattermost-integration.sh

# Test approval workflow
./request-ebs-increase.sh test-instance
./approve-ebs-increase.sh REQ-TEST-001
```

### 4. Monitor and Tune

- Monitor logs for first few automated executions
- Adjust thresholds based on application behavior
- Fine-tune approval timeout settings
- Verify backup and rollback procedures

## Escalation

- **Critical Issues**: Contact infrastructure team immediately
- **Approval Failures**: Check operator availability and permissions
- **Terraform Errors**: Review state file and AWS resource status
- **Integration Issues**: Verify Mattermost and Alertmanager configurations
