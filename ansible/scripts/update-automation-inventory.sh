#!/bin/bash

# Script to update Ansible inventory with all host details from Terraform
set -e

echo "🔧 Updating Ansible inventory with all host details from Terraform..."

# Get all host details from Terraform
cd ~/test/stage-autoremediation-dans-le-cloud-2025-v2/terraform

# Frontend details
FRONTEND_PUBLIC_IP=$(terraform output -raw frontend_ip 2>/dev/null || echo "")
FRONTEND_INSTANCE_ID=$(terraform output -raw frontend_instance_id 2>/dev/null || echo "")

# Backend details
BACKEND_PRIVATE_IP=$(terraform output -raw backend_private_ip 2>/dev/null || echo "")
BACKEND_INSTANCE_ID=$(terraform output -raw backend_instance_id 2>/dev/null || echo "")

# Automation details
AUTOMATION_PRIVATE_IP=$(terraform output -raw automation_private_ip 2>/dev/null || echo "")
AUTOMATION_INSTANCE_ID=$(terraform output -raw automation_instance_id 2>/dev/null || echo "")

# Load balancer details
INTERNAL_ALB_DNS=$(terraform output -raw internal_alb_dns 2>/dev/null || echo "")

# VPC details
VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "")

# Validate that we got all required information
if [ -z "$FRONTEND_PUBLIC_IP" ]; then
    echo "❌ Error: Could not get frontend public IP from Terraform"
    echo "   Make sure to run 'terraform apply' first"
    exit 1
fi

if [ -z "$FRONTEND_INSTANCE_ID" ]; then
    echo "❌ Error: Could not get frontend instance ID from Terraform"
    exit 1
fi

if [ -z "$BACKEND_PRIVATE_IP" ]; then
    echo "❌ Error: Could not get backend private IP from Terraform"
    exit 1
fi

if [ -z "$BACKEND_INSTANCE_ID" ]; then
    echo "❌ Error: Could not get backend instance ID from Terraform"
    exit 1
fi

if [ -z "$AUTOMATION_PRIVATE_IP" ]; then
    echo "❌ Error: Could not get automation private IP from Terraform"
    exit 1
fi

if [ -z "$AUTOMATION_INSTANCE_ID" ]; then
    echo "❌ Error: Could not get automation instance ID from Terraform"
    exit 1
fi

if [ -z "$VPC_ID" ]; then
    echo "❌ Error: Could not get VPC ID from Terraform"
    exit 1
fi

echo "📋 Host Details from Terraform:"
echo "   Frontend:"
echo "     Public IP: $FRONTEND_PUBLIC_IP"
echo "     Instance ID: $FRONTEND_INSTANCE_ID"
echo "   Backend:"
echo "     Private IP: $BACKEND_PRIVATE_IP"
echo "     Instance ID: $BACKEND_INSTANCE_ID"
echo "   Automation:"
echo "     Private IP: $AUTOMATION_PRIVATE_IP"
echo "     Instance ID: $AUTOMATION_INSTANCE_ID"
echo "   VPC:"
echo "     ID: $VPC_ID"
if [ -n "$INTERNAL_ALB_DNS" ]; then
    echo "   Internal ALB:"
    echo "     DNS: $INTERNAL_ALB_DNS"
fi

# Update the inventory file
cd ../ansible

# Create a backup of the original inventory
cp inventory/hosts.yml inventory/hosts.yml.backup

# Update frontend server details
sed -i "s/ansible_host: [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+.*/ansible_host: $FRONTEND_PUBLIC_IP/" inventory/hosts.yml
sed -i "s/private_ip: [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+.*/private_ip: $FRONTEND_PUBLIC_IP/" inventory/hosts.yml
sed -i "s/public_ip: [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+.*/public_ip: $FRONTEND_PUBLIC_IP/" inventory/hosts.yml
sed -i "s/instance_id: i-[a-zA-Z0-9]\+.*/instance_id: $FRONTEND_INSTANCE_ID/" inventory/hosts.yml

# Update backend server details
sed -i "/truh1-backend:/,/role: backend/ s/ansible_host: [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+.*/ansible_host: $BACKEND_PRIVATE_IP/" inventory/hosts.yml
sed -i "/truh1-backend:/,/role: backend/ s/private_ip: [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+.*/private_ip: $BACKEND_PRIVATE_IP/" inventory/hosts.yml
sed -i "/truh1-backend:/,/role: backend/ s/instance_id: i-[a-zA-Z0-9]\+.*/instance_id: $BACKEND_INSTANCE_ID/" inventory/hosts.yml
# Update ProxyCommand with new frontend IP (for jump host access)
sed -i "/truh1-backend:/,/role: backend/ s/ProxyCommand=\"ssh -i ~\/Documents\/truh-autoremed2.pem -o StrictHostKeyChecking=no -W %h:%p ubuntu@[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\"/ProxyCommand=\"ssh -i ~\/Documents\/truh-autoremed2.pem -o StrictHostKeyChecking=no -W %h:%p ubuntu@$FRONTEND_PUBLIC_IP\"/" inventory/hosts.yml

# Update automation server details
sed -i "/truh1-automation-runner:/,/role: automation/ s/ansible_host: [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+.*/ansible_host: $AUTOMATION_PRIVATE_IP/" inventory/hosts.yml
sed -i "/truh1-automation-runner:/,/role: automation/ s/private_ip: [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+.*/private_ip: $AUTOMATION_PRIVATE_IP/" inventory/hosts.yml
sed -i "/truh1-automation-runner:/,/role: automation/ s/instance_id: i-[a-zA-Z0-9]\+.*/instance_id: $AUTOMATION_INSTANCE_ID/" inventory/hosts.yml
# Update ProxyCommand with new frontend IP (for jump host access)
sed -i "/truh1-automation-runner:/,/role: automation/ s/ProxyCommand=\"ssh -i ~\/Documents\/truh-autoremed2.pem -o StrictHostKeyChecking=no -W %h:%p ubuntu@[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\"/ProxyCommand=\"ssh -i ~\/Documents\/truh-autoremed2.pem -o StrictHostKeyChecking=no -W %h:%p ubuntu@$FRONTEND_PUBLIC_IP\"/" inventory/hosts.yml

# Update load balancer DNS if available
if [ -n "$INTERNAL_ALB_DNS" ]; then
    sed -i "s/ansible_host: internal-truh1-internal-alb-[0-9]\+\.us-east-1\.elb\.amazonaws\.com.*/ansible_host: $INTERNAL_ALB_DNS/" inventory/hosts.yml
fi

# Update VPC ID
sed -i "s/vpc_id: vpc-[a-zA-Z0-9]\+/vpc_id: $VPC_ID/" inventory/hosts.yml

# Update VPC ID in README
sed -i "s/vpc_id: vpc-[a-zA-Z0-9]\+/vpc_id: $VPC_ID/" README.md

# Also update ~/.ssh/config HostName entries without removing blocks
echo "🔧 Updating ~/.ssh/config HostName entries..."

SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"
TIMESTAMP=$(date +%Y%m%d%H%M%S)

# Ensure ~/.ssh exists
mkdir -p "$SSH_DIR"
touch "$SSH_CONFIG"

# Backup existing config
cp "$SSH_CONFIG" "$SSH_CONFIG.backup.$TIMESTAMP"

# Prepare a temp file for safe write
TMP_FILE=$(mktemp)

# Use awk to preserve blocks and only modify HostName lines
awk \
    -v pub_ip="$FRONTEND_PUBLIC_IP" \
    -v back_ip="$BACKEND_PRIVATE_IP" \
    -v run_ip="$AUTOMATION_PRIVATE_IP" \
    -v host_pub="public-ec2" \
    -v host_pub_alt="publie-ec2" \
    -v host_back="private-ec2" \
    -v host_run="private2-ec2" '
function print_missing_hostname_if_needed() {
    if (current_block == "frontend" && seen_hostname == 0) {
        print "    HostName " pub_ip
    } else if (current_block == "backend" && seen_hostname == 0) {
        print "    HostName " back_ip
    } else if (current_block == "automation" && seen_hostname == 0) {
        print "    HostName " run_ip
    }
}

BEGIN {
    current_block = ""
    seen_hostname = 0
}

/^Host[ \t]+/ {
    # Before switching to a new block, ensure previous block had HostName
    print_missing_hostname_if_needed()

    # Reset and determine which block this is
    current_block = ""
    seen_hostname = 0
    for (i = 2; i <= NF; i++) {
        if ($i == host_pub || $i == host_pub_alt) {
            current_block = "frontend"
        } else if ($i == host_back) {
            current_block = "backend"
        } else if ($i == host_run) {
            current_block = "automation"
        }
    }

    print
    next
}

{
    if (current_block != "" && $1 == "HostName") {
        # Preserve indentation when replacing
        if (match($0, /^[ \t]*HostName[ \t]+/)) {
            prefix = substr($0, 1, RLENGTH)
            if (current_block == "frontend") {
                print prefix pub_ip
            } else if (current_block == "backend") {
                print prefix back_ip
            } else if (current_block == "automation") {
                print prefix run_ip
            } else {
                print
            }
            seen_hostname = 1
            next
        }
    }
    print
}

END {
    # End of file: ensure the last block has HostName
    print_missing_hostname_if_needed()
}
' "$SSH_CONFIG" > "$TMP_FILE" && mv "$TMP_FILE" "$SSH_CONFIG"

# Secure permissions
chmod 600 "$SSH_CONFIG"

echo "✅ ~/.ssh/config updated (backup: $SSH_CONFIG.backup.$TIMESTAMP)"

echo "✅ Ansible inventory updated successfully!"
echo "   Backup saved as: inventory/hosts.yml.backup"
echo "   README.md updated with current VPC ID"
echo ""
echo "🚀 You can now deploy to all hosts:"
echo "   ansible-playbook playbooks/deploy-and-start-apps.yml"
echo "   ansible-playbook playbooks/deploy-automation-runner.yml" 

git add ~/test/stage-autoremediation-dans-le-cloud-2025-v2/
git commit -m "Update automation inventory"
git push origin HEAD
