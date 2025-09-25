# Ansible Inventory for truh1-autoremediation Project

This directory contains the Ansible configuration for managing the truh1-autoremediation infrastructure, including the auto-remediation system for automated storage expansion.

## Structure

```text
ansible/
├── ansible.cfg          # Ansible configuration
├── inventory/
│   └── hosts.yml        # Static inventory file
├── playbooks/
│   ├── ping.yml         # Test connectivity playbook
│   ├── install-docker-ubuntu.yml                  # Depedencies installation for App
│   ├── install-automation-dependencies-ubuntu.yml #Depedencies installation for runner
│   ├── deploy-automation-runner-ubuntu.yml        #Auto remediation installation
│   └── deploy-and-start-apps-ubuntu.yml           # Application deployment
├── scripts/
│   ├── update-automation-inventory.sh # Helper script to update inventory
└── README.md            # This file
```

## Inventory Overview

The inventory is organized into the following groups:

### Environment Groups

- `dev` - Development environment (all servers)

### Role-based Groups

- `frontend_servers` - Frontend web servers
- `backend_servers` - Backend API servers  
- `load_balancers` - Load balancers (ALB)

### Application Groups

- `web_servers` - All web servers (frontend)
- `api_servers` - All API servers (backend)

### Infrastructure Groups

- `infrastructure` - All infrastructure components

## Hosts

### Frontend Server

- **Hostname**: `truh1-frontend`
- **Public IP**: `changing`
- **Private IP**: `changing`
- **Instance ID**: `changing`
- **Role**: Frontend web server, bastion host
- **Access**: Direct SSH via public IP

### Backend Server

- **Hostname**: `truh1-backend`
- **Private IP**: `changing`
- **Instance ID**: `changing`
- **Role**: Backend API server, auto-remediation target
- **Access**: SSH via frontend server (bastion host)

### Load Balancer

- **Hostname**: `truh1-internal-alb`
- **DNS**: `changing`
- **Role**: Internal Application Load Balancer
- **Access**: AWS managed (not directly accessible via SSH)

## Auto-Remediation System

The infrastructure includes a Terraform-based auto-remediation system with operator approval workflow:

### **Features:**

- **EBS Volume Auto-Scaling**: Automated disk space management via Terraform
- **Mattermost Integration**: Real-time operator notifications and approval workflow
- **Webhook Processing**: Alertmanager integration for automatic triggering
- **Approval System**: Manual confirmation required before infrastructure changes
- **Terraform Automation**: Safe infrastructure modifications after operator approval
- **Comprehensive Logging**: Complete audit trail of all remediation activities

### **Components:**

- **Auto-Remediation Runner**: Dedicated EC2 instance for processing alerts
- **Webhook Receiver**: Processes Alertmanager notifications
- **Approval Workflow**: Manual approval system with Mattermost integration
- **Terraform Executor**: Applies infrastructure changes after approval
- **Notification System**: Real-time status updates via Mattermost

### **Deployment:**

```bash
# Install automation dependencies
ansible-playbook -i inventory/hosts.yml playbooks/install-automation-dependencies-ubuntu.yml

# Deploy auto-remediation runner
ansible-playbook -i inventory/hosts.yml playbooks/deploy-automation-runner-ubuntu.yml
```

## Prerequisites

1. **SSH Key**: Ensure you have the SSH private key `~/Documents/truh-autoremed.pem` with proper permissions (600)
2. **Ansible**: Install Ansible on your local machine
3. **AWS Access**: Ensure you have access to the AWS instances
4. **AWS CLI**: Configured on your local machine for auto-remediation

## Usage

### Test Connectivity

Test connectivity to all hosts:

```bash
cd ansible
ansible-playbook playbooks/ping.yml
```

### Run Commands on Specific Groups

Ping only frontend servers:

```bash
ansible frontend_servers -m ping
```

Ping only backend servers:

```bash
ansible backend_servers -m ping
```

### Run Commands on All Infrastructure

```bash
ansible infrastructure -m ping
```

## SSH Configuration

### Frontend Server

Direct SSH access via public IP:

```bash
ssh -i ~/Documents/truh-autoremed.pem ec2-user@FrontEndIP
```

### Backend Server

SSH access via frontend server (bastion host):

```bash
ssh -i ~/Documents/truh-autoremed.pem -o ProxyJump=ec2-user@FrontEndIP ec2-user@BackendEndIP
```

## Variables

### Global Variables

- `project_name`: truh1-autoremediation
- `environment`: dev
- `aws_region`: us-east-1
- `vpc_id`: changing
- `domain`: aws.ocho.ninja
- `frontend_url`: <http://truhauto.aws.ocho.ninja>

### Host-specific Variables

Each host has role-specific variables defined in the inventory.

## Security Notes

1. The SSH key file should have restricted permissions (600)
2. Host key checking is disabled for convenience in development
3. Backend server access is restricted through the frontend server
4. All servers use the `ec2-user` account
5. Auto-remediation runner uses IAM roles for secure Terraform operations
