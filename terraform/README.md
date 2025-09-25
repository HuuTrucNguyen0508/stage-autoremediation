# Terraform Infrastructure for Auto-Remediation Stage

This Terraform configuration deploys a secure, scalable infrastructure for the auto-remediation stage project using a modular approach with enhanced security features.

## Architecture

```text
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   Load Balancer │
│   (EC2)         │    │   (EC2)         │    │   (Internal)    │
│                 │    │                 │    │                 │
│ - t2.large      │    │ - t2.large      │    │ - ALB           │
│ - Public subnet │    │ - Private subnet│    │ - Private subnet│
│ - Elastic IP    │    │ - IMDSv2        │    │ - Health checks │
│ - IMDSv2        │    │ - Security      │    │ - SSL/TLS       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Route53 DNS   │
                    │   Configuration │
                    └─────────────────┘
```

## Security Features

### 🔒 **IMDSv2 (Instance Metadata Service v2)**

- **Enhanced Security**: Protection against SSRF attacks
- **Token-based Access**: Requires session tokens for metadata access
- **Hop Limit Protection**: Prevents token forwarding between instances
- **AWS Best Practices**: Follows current AWS security recommendations

### 🛡️ **Security Groups**

- **Frontend**: HTTP/HTTPS/SSH inbound, all outbound
- **ALB**: HTTP from Frontend SG, SSH from your IP, all outbound to Backend SG
- **Backend**: ALB SG inbound, SSH from your IP, all outbound

### 🏷️ **Resource Tagging**

- All resources prefixed with "truh1"
- Environment tags for resource management
- Role-based tagging for automation

## Modular Structure

```text
terraform/
├── main.tf                     # Main configuration
├── variables.tf                # Variable definitions
├── outputs.tf                  # Output values
├── terraform.tfvars            # Variable values
├── README.md                   # This file
├── README_IMDSV2.md           # IMDSv2 implementation guide
└── modules/                    # Terraform modules
    ├── network/                # VPC and networking
    │   ├── network.tf
    │   ├── network_variables.tf
    │   └── network_outputs.tf
    ├── security/               # Security groups
    │   ├── security.tf
    │   ├── security_variables.tf
    │   └── security_outputs.tf
    ├── compute/                # EC2 instances
    │   ├── compute.tf
    │   ├── compute_variables.tf
    │   └── compute_outputs.tf
    ├── loadbalancer/           # Application Load Balancer
    │   ├── loadbalancer.tf
    │   ├── loadbalancer_variables.tf
    │   └── loadbalancer_outputs.tf
    ├── automation-iam/         # Auto-remediation IAM roles
    │   ├── automation-iam.tf
    │   ├── automation-iam_variables.tf
    │   └── automation-iam_outputs.tf
    └── dns/                    # Route53 configuration
        ├── dns.tf
        ├── dns_variables.tf
        └── dns_outputs.tf
```

## Prerequisites

1. **Terraform** (>= 1.0)
2. **AWS CLI** configured with credentials
3. **AWS Region**: us-east-1 (default)

## Configuration

### 1. Set up terraform.tfvars

Create a `terraform.tfvars` file with your configuration:

```hcl
# AWS Configuration
aws_region = "us-east-1"
name_prefix = "truh1"

# Network Configuration
my_ip = "your-ip-address/32"  # e.g., "192.168.1.1/32"

# EC2 Configuration
key_name = "your-ec2-key-pair-name"
frontend_instance_type = "t2.large"
backend_instance_type = "t2.large"

# Application Configuration
backend_port = 80
frontend_port = 80

# Tags
tags = {
  Environment = "dev"
  Project     = "truh1-autoremediation"
  Owner       = "your-name"
}
```

### 2. Verify Variables

Check `variables.tf` for all available variables and their descriptions.

## IMDSv2 Configuration

The infrastructure includes IMDSv2 for enhanced security:

```hcl
# IMDSv2 configuration in compute module
metadata_options {
  http_endpoint               = "enabled"
  http_tokens                 = "required"  # Enforces IMDSv2
  http_put_response_hop_limit = 1
  instance_metadata_tags      = "enabled"
}
```

For detailed IMDSv2 information, see [README_IMDSV2.md](README_IMDSV2.md).

## Deployment

### Initialize Terraform

```bash
terraform init
```

### Plan the Deployment

```bash
terraform plan
```

### Apply the Configuration

```bash
terraform apply
```

### Destroy Infrastructure

```bash
terraform destroy
```

## Outputs

After successful deployment, you'll get:

```hcl
# Instance Information
frontend_instance_id = "i-xxxxxxxxxxxxxxxxx"
backend_instance_id  = "i-xxxxxxxxxxxxxxxxx"
frontend_public_ip   = "x.x.x.x"
frontend_private_ip  = "10.x.x.x"
backend_private_ip   = "10.x.x.x"

# Load Balancer Information
internal_alb_dns_name = "internal-truh1-internal-alb-xxxxxxxx.us-east-1.elb.amazonaws.com"
internal_alb_zone_id  = "ZXXXXXXXXX"

# DNS Information
frontend_url = "http://truhauto.aws.ocho.ninja"
```

## Module Details

### Network Module

- VPC with public and private subnets
- Internet Gateway and NAT Gateway
- Route tables for proper traffic routing

### Security Module

- Security groups for frontend, backend, and ALB
- Proper ingress and egress rules
- SSH access from your IP only

### Compute Module

- EC2 instances with IMDSv2 enabled
- Elastic IP for frontend
- Proper instance tagging

### Load Balancer Module

- Internal Application Load Balancer
- Target group with health checks
- SSL/TLS termination support

### Automation IAM Module

- IAM roles for auto-remediation runner
- Policies for Terraform operations
- EBS volume management permissions
- S3 state file access

### DNS Module

- Route53 hosted zone configuration
- A records for frontend and backend
- ALIAS records for load balancer

## Security Best Practices

1. **IMDSv2**: All instances use IMDSv2 for enhanced security
2. **Private Subnets**: Backend services in private subnets
3. **Security Groups**: Minimal required access
4. **SSH Access**: Restricted to your IP address
5. **Resource Tagging**: Proper tagging for cost management
6. **Load Balancer**: Internal ALB for backend services

## Auto-Remediation Integration

The infrastructure includes auto-remediation capabilities:

### **EBS Volume Management**

- **Automated Expansion**: Terraform-based volume scaling
- **Approval Workflow**: Manual operator confirmation required
- **Mattermost Integration**: Real-time notifications and approvals
- **Safe Operations**: Backup and rollback capabilities

### **IAM Configuration**

- **Dedicated Role**: Auto-remediation runner IAM role
- **Minimal Permissions**: Least privilege for Terraform operations
- **Secure Access**: State file and resource management

### **Variable Configuration**

```hcl
# Auto-remediation configuration
backend_ebs_volume_size = 20      # Initial EBS volume size
auto_remediation_enabled = true   # Enable auto-remediation
max_volume_size = 100            # Maximum allowed volume size
```

## Monitoring and Logging

The infrastructure supports:

- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **Loki**: Log aggregation
- **Promtail**: Log shipping
- **Alertmanager**: Alert routing to auto-remediation

## Troubleshooting

### Common Issues

1. **IMDSv2 Compatibility**: Ensure applications support IMDSv2
2. **Security Group Rules**: Verify IP addresses and ports
3. **Key Pair**: Ensure EC2 key pair exists in AWS
4. **VPC Configuration**: Check subnet configurations

### Debug Commands

```bash
# Check IMDSv2 status
aws ec2 describe-instances --instance-ids i-xxxxxxxxx --query 'Reservations[*].Instances[*].MetadataOptions'

# Verify security groups
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx

# Check load balancer health
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:...

# Check EBS volume status
aws ec2 describe-volumes --volume-ids vol-xxxxxxxxx

# Verify IAM role for auto-remediation
aws iam get-role --role-name truh1-automation-role

# Check Terraform state
terraform show | grep ebs_volume
```

## Next Steps

After infrastructure deployment:

1. **Configure Ansible**: Use the ansible playbooks for application deployment
2. **Deploy Applications**: Run `ansible-playbook -i inventory/hosts.yml playbooks/deploy-and-start-apps.yml`
3. **Setup Auto-Remediation**: Deploy the auto-remediation runner
4. 
```bash
   ansible-playbook -i inventory/hosts.yml playbooks/deploy-automation-runner-ubuntu.yml
```
5. **Configure Mattermost**: Set up webhook integration for notifications
6. **Test Workflow**: Verify auto-remediation workflow with test alerts
7. **Monitor**: Access Grafana dashboards for monitoring and alerting
8. **Scale**: Use the modular structure to add more instances or services

## Resources

- [AWS IMDSv2 Documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [IMDSv2 Implementation Guide](README_IMDSV2.md) 