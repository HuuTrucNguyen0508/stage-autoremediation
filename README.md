# Stage Autoremédiation dans le cloud 2025 v2

A comprehensive cloud infrastructure project demonstrating Infrastructure as Code (IaC), Configuration Management, and Auto-Remediation using Terraform, Ansible, and Docker.

## 🚀 Project Overview

This project implements a complete cloud infrastructure with auto-remediation capabilities:

- **Terraform**: Infrastructure provisioning on AWS with remote state management
- **Ansible**: Configuration management and application deployment
- **Docker**: Containerized applications with embedded configurations
- **Monitoring**: Complete observability stack (Prometheus, Grafana, Loki, Jaeger)
- **Auto-Remediation**: Automated incident response and recovery
- **CI/CD**: GitLab CI/CD pipeline with validation and testing

## 🏗️ Architecture

```text
                                   ┌────────────────────────────┐
                                   │        Terraform/IaC       │
                                   └──────────────┬─────────────┘
                                              remote state
                                                   │
                                   ┌───────────────▼────────────────┐
                                   │   S3 (tfstate) + DynamoDB lock │
                                   └─────────────────────────────────┘

User ──► Route53 ──► Elastic IP ──► Frontend EC2 (public subnet)
                                     - Nginx serves SPA
                                     - Proxies /api, /grafana, /prometheus, /jaeger
                                     - Dockerized with embedded configs
                                                   │
                                                   ▼
                                     Internal AWS ALB (private)
                                                   │
                                                   ▼
                                Backend EC2 (private subnet, Docker)
                                  - Nginx (edge for backend)
                                  - Backend API (Node.js)
                                  - Database API ⇄ MongoDB
                                  - Notification API

                                Observability (on Backend EC2)
                                  - Prometheus ◄── Node Exporter (host metrics)
                                  - Alertmanager (from Prometheus alerts)
                                  - Grafana (dashboards with embedded provisioning)
                                  - Loki + Promtail (logs with embedded configs)
                                  - Jaeger (distributed tracing)

                                Auto-Remediation Runner EC2
                                  - Receives Alertmanager webhooks
                                  - Inform the operator through Mattermost
                                  - Triggers remediation via Terraform after confirmation
                                  - EBS volume auto-scaling
```

## ✨ Key Features

### 🔧 Infrastructure (Terraform)

- **VPC** with public and private subnets across multiple AZs
- **EC2 instances** with security groups and IMDSv2 enabled
- **Application Load Balancer** with health checks
- **Route53 DNS** configuration with Elastic IP
- **Auto-scaling** capabilities
- **Remote state** in S3 with DynamoDB state locking
- **Resource naming** with 'truh1' prefix for all components

### ⚙️ Configuration Management (Ansible)

- **Automated system configuration** 
- **Application deployment** with Docker Compose
- **Security hardening** and SSH key management
- **Health checks** and validation
- **Streamlined deployment** approach

### 🐳 Applications (Docker)

- **Frontend**: React application with embedded Nginx configuration
- **Backend**: Node.js API services with embedded Nginx configuration
- **Database**: MongoDB with authentication
- **Monitoring**: Complete observability stack with embedded configs
- **Streamlined deployment**: Only docker-compose files needed

### 🔄 Auto-Remediation

- **EBS Volume Auto-Scaling**: Automatic disk space management
- **Approval Workflow**: Manual approval for critical changes
- **Webhook Integration**: Alertmanager to auto-remediation pipeline
- **Mattermost Integration**: Notifications and approval requests
- **AWS API Integration with Terraform**: Direct infrastructure management

### 📊 Monitoring & Observability

- **Prometheus**: Metrics collection with embedded configuration
- **Grafana**: Visualization with embedded dashboards and provisioning
- **Loki**: Log aggregation with embedded configuration
- **Promtail**: Log shipping with embedded configuration
- **Jaeger**: Distributed tracing
- **Alertmanager**: Alert routing and notification
- **Node Exporter**: Host metrics collection

### 🔒 Security

- **IMDSv2**: Enhanced instance metadata security
- **Security Groups**: Minimal access principle
- **Private Subnets**: Backend services isolation
- **SSH Key Authentication**: No password access
- **Docker Security**: Non-root containers and security scanning
- **HTTPS/TLS**: Configurable encryption

## 📋 Prerequisites

- **AWS CLI** configured with appropriate credentials
- **Terraform** (>= 1.0)
- **Ansible** (>= 2.12)
- **Docker** and Docker Compose
- **SSH key pair** for EC2 access
- **GitLab access token** for CI/CD
- **Mattermost webhook URL** (optional, for notifications)

## 🚀 Quick Start

### 1. Infrastructure Deployment (Terraform)

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Deploy infrastructure
terraform apply
```

### 2. Build Docker Images (Optional)

```bash
# Navigate to dockerfiles directory
cd dockerfiles

# Build all images with embedded configurations
./deploy-simplified.sh
```

### 3. Configuration Management (Ansible)

```bash
# Navigate to ansible directory
cd ansible

# Set required environment variables
export GITLAB_TOKEN="your-gitlab-token"
export AWS_ACCESS_KEY_ID="your-aws-access-key"
export AWS_SECRET_ACCESS_KEY="your-aws-secret-key"

#Run IP update script due to inventory being static
./scripts/update-automation-inventory.sh

#Update git so that Runner EC2 have the latest config
git add /inventory/host.yaml
git commit -m "IP update"
git push origin HEAD

# Run complete Ansible deployment
ansible-playbook -i inventory/hosts.yml playbooks/install-docker-ubuntu.yml
ansible-playbook -i inventory/hosts.yml playbooks/deploy-and-start-apps-ubuntu.yml
```

### 4. Auto-Remediation Setup

```bash
# Navigate to auto-remediation directory
cd auto-remediation

# Configure webhook integration
# Update hooks.yaml with your Alertmanager configuration

# Deploy auto-remediation runner
cd ../ansible
ansible-playbook -i inventory/hosts.yml playbooks/install-automation-dependencies-ubuntu.yml
ansible-playbook -i inventory/hosts.yml playbooks/deploy-automation-runner-ubuntu.yml
```

## 📁 Project Structure

```text
├── terraform/                 # Infrastructure as Code
│   ├── backend.tf            # Remote backend configuration
│   ├── bootstrap-backend.sh  # S3 bucket and DynamoDB setup
│   ├── main.tf               # Main Terraform configuration
│   ├── variables.tf          # Variable definitions
│   ├── outputs.tf            # Output values
│   └── modules/              # Terraform modules
│       ├── network/          # VPC and networking
│       ├── compute/          # EC2 instances
│       ├── loadbalancer/     # Application Load Balancer
│       ├── dns/              # Route53 configuration
│       ├── security/         # Security groups
│       └── automation-iam/   # Auto-remediation IAM roles
├── ansible/                  # Configuration Management
│   ├── playbooks/            # Ansible playbooks
│   │   ├── install-docker-ubuntu.yml
│   │   ├── deploy-and-start-apps-ubuntu.yml
│   │   ├── deploy-automation-runner-ubuntu.yml
│   │   └── install-automation-dependencies-ubuntu.yml
│   ├── inventory/            # Host inventory
│   ├── group_vars/           # Group variables
│   ├── templates/            # Jinja2 templates
│   └── scripts/              # Utility scripts
├── frontend-ec2/             # Frontend application
│   ├── frontend/             # React application
│   └── docker-compose.yaml   # Frontend services
├── backend-ec2/              # Backend services
│   ├── backend/              # Backend API
│   ├── database-api/         # Database API service
│   ├── notification-api/     # Notification service
│   └── docker-compose.yaml   # Backend services
├── auto-remediation/         # Auto-remediation system
│   ├── auto-remediation-playbook.yml
│   ├── ebs-increase-playbook.yml
│   ├── hooks.yaml            # Webhook configurations
│   ├── mattermost-config.yml # Mattermost integration
│   └── scripts/              # Remediation scripts
├── dockerfiles/              # Docker configurations
│   ├── Dockerfile.*          # Custom Dockerfiles
│   ├── *.conf               # Embedded configurations
│   ├── grafana/             # Dashboard provisioning
│   └── scripts/             # Build and deployment scripts
├── grafana/                  # Additional Grafana resources
├── nginx/                    # Nginx configurations
└── .gitlab-ci.yml           # CI/CD pipeline
```

For detailed project structure, see [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md).

## 🔄 CI/CD Pipeline

The GitLab CI/CD pipeline includes:

### Stages

1. **Test**: Validation and syntax checking
2. **Build**: Infrastructure and configuration validation

### Jobs

- **Ansible Lint**: Validates Ansible playbooks and syntax
- **Terraform Validation**: Validates Terraform configuration and formatting
- **Test Echo**: Basic pipeline testing

### Pipeline Features

- **Automated Validation**: Syntax and lint checking
- **Infrastructure Testing**: Terraform plan validation
- **Configuration Testing**: Ansible playbook validation
- **Quality Gates**: Ensures code quality before deployment

## 🔧 Configuration

### Environment Variables

Required environment variables:

```bash
# GitLab CI/CD
GITLAB_TOKEN=your-gitlab-token

# AWS Credentials
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
AWS_DEFAULT_REGION=us-east-1

# Auto-Remediation (Optional)
MATTERMOST_WEBHOOK_URL=your-mattermost-webhook-url
```

### Customization

1. **Infrastructure**: Modify `terraform/variables.tf` and `terraform/main.tf`
2. **Configuration**: Update `ansible/group_vars/` files
3. **Applications**: Modify application code in `frontend-ec2/` and `backend-ec2/`
4. **Monitoring**: Customize dashboards in `grafana/`
5. **Auto-Remediation**: Configure `auto-remediation/hooks.yaml`

## 🔄 Auto-Remediation Workflow

### EBS Volume Auto-Scaling

1. **Monitoring**: Prometheus detects low disk space
2. **Alerting**: Alertmanager sends webhook to auto-remediation runner
3. **Request**: Auto-remediation requests EBS volume increase
4. **Approval**: Mattermost notification for manual approval
5. **Execution**: Approved changes are applied via AWS API
6. **Verification**: Health checks confirm successful remediation

### Components

- **Webhook Receiver**: Processes Alertmanager notifications
- **Approval System**: Manual approval workflow
- **AWS Integration**: Direct API calls for infrastructure changes with Terraform
- **Notification System**: Mattermost integration for alerts and approvals

## 📊 Monitoring and Observability

### Metrics Collection

- **System Metrics**: CPU, memory, disk, network via Node Exporter
- **Application Metrics**: Response times, error rates, throughput
- **Docker Metrics**: Container resource usage and health
- **Custom Metrics**: Application-specific monitoring

### Log Aggregation

- **Application Logs**: Structured logging with correlation IDs
- **System Logs**: OS and service logs
- **Docker Logs**: Container logs with metadata
- **Nginx Logs**: Access and error logs

### Visualization

- **System Overview**: Host metrics and health status
- **Application Performance**: Response times and error rates
- **Infrastructure Health**: Resource utilization and capacity
- **Auto-Remediation**: Incident history and resolution times

### Alerting

- **Threshold Alerts**: Resource utilization warnings
- **Anomaly Detection**: Unusual patterns and behaviors
- **Auto-Remediation Triggers**: Automatic incident response
- **Escalation**: Manual intervention when needed

## 📚 Documentation

- [Project Structure](PROJECT_STRUCTURE.md) - Detailed project organization
- [Terraform README](terraform/README.md) - Infrastructure documentation
- [Ansible README](ansible/README.md) - Configuration management guide
- [Auto-Remediation README](auto-remediation/README.md) - Auto-remediation system guide
- [Dockerfiles README](dockerfiles/README.md) - Docker configuration guide

## 🔄 Version History

- **v2.0**: Complete rewrite with auto-remediation, streamlined deployment, and enhanced monitoring
- **v1.0**: Initial implementation with basic infrastructure and applications

---

**Note**: This project demonstrates modern cloud-native practices with Infrastructure as Code, Configuration Management, and Auto-Remediation capabilities. All resources are prefixed with 'truh1' for easy identification and management.
