# Project Structure

This document outlines the clean, organized structure of the truh1-autoremediation project with streamlined deployment.

## Root Directory

```text
stage-autoremediation-dans-le-cloud-2025-v2/
├── README.md                    # Main project documentation
├── .gitignore                   # Git ignore rules
├── compose.yaml                 # Docker Compose configuration
├── dockerfiles/                 # Docker-related files (Dockerfiles, configs, build scripts)
├── ansible/                     # Ansible automation
├── terraform/                   # Infrastructure as Code
├── backend-ec2/                 # Backend application deployment
├── frontend-ec2/                # Frontend application deployment
├── auto-remediation/            # Auto-remediation system with Terraform integration
├── grafana/                     # Grafana dashboards
└── nginx/                       # Nginx configuration
```

## Ansible Directory

```text
ansible/
├── README.md                    # Ansible documentation
├── ansible.cfg                  # Ansible configuration
├── inventory/
│   └── hosts.yml               # Static inventory
├── playbooks/
│   ├── ping.yml                # Connectivity test
│   └── deploy-and-start-apps.yml # Streamlined application deployment
└── scripts/
    └── ansible-helper.sh       # Helper scripts
```

## Terraform Directory

```text
terraform/
├── README.md                    # Terraform documentation
├── README_IMDSV2.md            # IMDSv2 implementation guide
├── main.tf                     # Main Terraform configuration
├── variables.tf                # Variable definitions
├── outputs.tf                  # Output definitions
├── terraform.tfvars            # Variable values
├── .terraform.lock.hcl         # Dependency lock file
├── terraform.tfstate           # State file
├── terraform.tfstate.backup    # State backup
└── modules/                    # Terraform modules
    ├── compute/                # EC2 instances
    ├── network/                # VPC and networking
    ├── security/               # Security groups
    ├── loadbalancer/           # Application Load Balancer
    └── dns/                    # Route53 configuration
```

## Dockerfiles Directory

```text
dockerfiles/
├── README.md                   # Dockerfiles directory guide
├── DOCKERHUB_DEPLOYMENT.md     # Deployment instructions
├── Dockerfile.nginx            # Backend nginx with embedded config
├── Dockerfile.nginx.frontend   # Frontend nginx with embedded config
├── Dockerfile.prometheus       # Prometheus with embedded config
├── Dockerfile.loki             # Loki with embedded config
├── Dockerfile.promtail         # Promtail with embedded config
├── Dockerfile.grafana          # Grafana with embedded config
├── frontend-nginx.conf         # Frontend nginx configuration
├── backend-nginx.conf          # Backend nginx configuration
├── prometheus.yml              # Prometheus configuration
├── loki-config.yml             # Loki configuration
├── promtail-config.yml         # Promtail configuration
├── grafana/                    # Grafana provisioning and dashboards
├── build-frontend-images.sh    # Frontend build script
├── build-backend-images.sh     # Backend build script
├── deploy-simplified.sh        # Build all images
└── push-to-dockerhub.sh        # Push to Docker Hub
```

## Application Directories

### Backend EC2 (Streamlined Deployment)

```text
backend-ec2/
├── backend/                    # Backend application code
├── database-api/               # Database API service
├── notification-api/           # Notification service
├── docker-compose.yaml         # Backend services (uses embedded configs)
├── dashboard_ids.txt           # Dashboard IDs
├── download_dashboards.sh      # Dashboard download script
└── package.json                # Backend dependencies
```

### Frontend EC2 (Streamlined Deployment)

```text
frontend-ec2/
├── frontend/                   # Frontend application code
├── docker-compose.yaml         # Frontend services (uses embedded configs)
├── get-docker.sh               # Docker installation script
└── package.json                # Frontend dependencies
```

## Auto-Remediation Directory

```text
auto-remediation/
├── README.md                   # Auto-remediation system documentation
├── auto-remediation-playbook.yml # Main Ansible playbook for EBS expansion
├── ebs-increase-playbook.yml   # EBS volume increase automation
├── extend-backend-disk-ubuntu.yml # Ubuntu-specific disk extension
├── hooks.yaml                  # Webhook configuration for Alertmanager
├── mattermost-config.yml       # Mattermost integration configuration
├── approval_status.json        # Approval workflow status tracking
├── webhook.log                 # Webhook activity logs
├── approve-ebs-increase.sh     # Manual approval script
├── deny-ebs-increase.sh        # Manual denial script
├── request-ebs-increase.sh     # EBS increase request script
├── process-approval.sh         # Approval processing automation
├── README_REFACTORED.md        # Refactoring documentation
└── WEBHOOK_INTEGRATION.md      # Webhook setup guide
```

## Key Features

### Security

- **IMDSv2**: Instance Metadata Service v2 enabled for enhanced security
- **Security Groups**: Properly configured network access controls
- **Private Subnets**: Backend services in private subnets

### Monitoring

- **Prometheus**: Metrics collection with embedded configuration
- **Grafana**: Visualization and dashboards with embedded provisioning
- **Loki**: Log aggregation with embedded configuration
- **Promtail**: Log shipping with embedded configuration

### Infrastructure

- **Terraform**: Infrastructure as Code
- **Ansible**: Streamlined configuration management
- **Docker**: Containerization with embedded configurations
- **AWS**: Cloud infrastructure

### Applications

- **Frontend**: React application with embedded nginx configuration
- **Backend**: Node.js API services with embedded nginx configuration
- **Database**: MongoDB
- **Load Balancer**: AWS ALB

### Auto-Remediation

- **EBS Volume Management**: Automated disk space expansion via Terraform
- **Mattermost Integration**: Operator notifications and approval workflow
- **Webhook Processing**: Alertmanager integration for automatic triggering
- **Approval System**: Manual confirmation before infrastructure changes
- **Terraform Automation**: Safe infrastructure modifications after approval

### Deployment

- **Streamlined**: Only docker-compose files needed for deployment
- **Embedded Configs**: All configurations embedded in Docker images
- **Consistent**: Same deployment approach for all services
- **Fast**: Quick deployment with minimal file copying

## Streamlined Deployment

The project has been transformed to use streamlined deployment with embedded configurations:

### **What Changed:**

- **Dockerfiles**: Moved to dedicated `dockerfiles/` directory
- **Configurations**: Embedded in custom Docker images
- **Deployment**: Only docker-compose files needed
- **Ansible**: Updated to use streamlined approach

### **Benefits:**

- **Simplified**: No need to copy multiple configuration files
- **Consistent**: Same deployment approach everywhere
- **Reliable**: Configurations versioned with Docker images
- **Fast**: Quick deployment with minimal file operations

## Getting Started

1. **Infrastructure**: `cd terraform && terraform apply`
2. **Build Images** (if needed): `cd dockerfiles && ./deploy-simplified.sh`
3. **Deploy Applications**: `cd ansible && ansible-playbook -i inventory/hosts.yml playbooks/deploy-and-start-apps.yml`
4. **Setup Auto-Remediation**: Configure Mattermost webhook and approval workflow
5. **Monitor**: Access Grafana dashboards with embedded configurations
6. **Documentation**: See individual README files in each directory
