# Ansible Playbooks for truh1-autoremediation

This directory contains Ansible playbooks for managing the truh1-autoremediation infrastructure, including the auto-remediation system for automated storage expansion.

## Available Playbooks

### 1. `ping.yml` - Test Connectivity
Tests basic connectivity to all hosts in the inventory.

```bash
ansible-playbook playbooks/ping.yml
```

### 2. `install-docker-amazon-linux2.yml` - Install Docker and Docker Compose v2
Comprehensive playbook to install Docker and Docker Compose v2 on Amazon Linux 2 instances.

**Features:**
- Updates system packages
- Installs Docker using `amazon-linux-extras` (Amazon Linux 2 specific)
- Installs Docker Compose v2 as a CLI plugin
- Creates docker group and adds ec2-user to it
- Creates `/home/ec2-user/repo` directory
- Sets proper socket permissions (0666)
- Restarts Docker service to apply permissions
- Verifies installation and tests as ec2-user

```bash
ansible-playbook playbooks/install-docker-amazon-linux2.yml
```

### 3. `deploy-and-start-apps.yml` - Deploy Applications
Deploys the complete application stack including auto-remediation system.

**Features:**
- Copies application files to EC2 instances
- Deploys Docker Compose applications
- Sets up monitoring stack (Prometheus, AlertManager, Grafana)
- Configures auto-remediation system
- Starts all services

```bash
ansible-playbook playbooks/deploy-and-start-apps.yml
```

## Auto-Remediation System

The infrastructure includes an automated storage expansion system that:

### **Components Deployed:**
- **Timer Service**: `auto-storage-expansion.service` (runs every 10 minutes)
- **Expansion Scripts**: `auto-expand-storage-hybrid.sh` and `local-expansion-handler.sh`
- **Monitoring**: Prometheus with custom alert rules
- **Alert Management**: AlertManager with webhook configuration

### **Deployment Process:**
1. **Infrastructure Setup**: Docker, monitoring stack
2. **Auto-Remediation Deployment**: Scripts and services
3. **Configuration**: Timer service and logging
4. **Verification**: Service status and connectivity

### **Manual Deployment:**
```bash
# Deploy auto-remediation system manually
./auto-remediation/scripts/deploy-auto-remediation.sh
```

## Quick Start with Helper Script

Use the helper script for easy management:

```bash
# Check prerequisites
./scripts/ansible-helper.sh check

# Test connectivity
./scripts/ansible-helper.sh ping

# Install Docker
./scripts/ansible-helper.sh install-docker

# Deploy applications (includes auto-remediation)
./scripts/ansible-helper.sh deploy-apps

# Check auto-remediation status
./scripts/ansible-helper.sh command backend_servers 'systemctl status auto-storage-expansion.service'

# Check disk usage
./scripts/ansible-helper.sh command backend_servers 'df -h /dev/xvda1'
```

## Installation Process

### Step 1: Check Prerequisites
```bash
./scripts/ansible-helper.sh check
```

### Step 2: Test Connectivity
```bash
./scripts/ansible-helper.sh ping
```

### Step 3: Install Docker
```bash
./scripts/ansible-helper.sh install-docker
```

### Step 4: Deploy Applications (includes auto-remediation)
```bash
./scripts/ansible-helper.sh deploy-apps
```

### Step 5: Verify Auto-Remediation
```bash
# Check service status
./scripts/ansible-helper.sh command backend_servers 'systemctl status auto-storage-expansion.service'

# Check logs
./scripts/ansible-helper.sh command backend_servers 'journalctl -u auto-storage-expansion.service -f'

# Check disk usage
./scripts/ansible-helper.sh command backend_servers 'df -h /dev/xvda1'
```

## What Gets Installed

### Docker Components
- Docker CE (Community Edition)
- Docker CLI
- Containerd
- Docker Buildx Plugin
- Docker Compose Plugin

### Docker Compose v2
- Downloaded as CLI plugin to `/usr/local/lib/docker/cli-plugins/docker-compose`
- Version: v2.27.0
- Architecture: linux-x86_64

### User Configuration
- Creates `docker` group
- Adds `ec2-user` to `docker` group
- Sets proper permissions for `/home/ec2-user`
- Creates `/home/ec2-user/repo` directory

### Auto-Remediation System
- **Timer Service**: `auto-storage-expansion.service`
- **Expansion Scripts**: Located in `/home/ec2-user/auto-remediation/`
- **Logging**: Comprehensive audit trail
- **Monitoring**: Integration with Prometheus and AlertManager

## Post-Installation Steps

After running the installation playbook:

1. **Log out and log back in** for group changes to take effect
2. **Or run**: `newgrp docker` to activate the docker group
3. **Test**: `docker ps` (should work without sudo)
4. **Verify auto-remediation**: Check service status and logs

## Verification Commands

### Manual Verification
```bash
# SSH to frontend server
ssh -i ~/Documents/truh-autoremed.pem ec2-user@34.206.69.106

# Check Docker version
docker --version

# Check Docker Compose version
docker compose version

# Test Docker without sudo
docker ps

# Check user groups
groups

# Check repo directory
ls -la /home/ec2-user/repo
```

### SSH to Backend Server
```bash
# SSH to backend server (via frontend)
ssh -i ~/Documents/truh-autoremed.pem -o ProxyJump=ec2-user@34.206.69.106 ec2-user@10.0.2.70

# Run the same verification commands
docker --version
docker compose version
docker ps
groups
ls -la /home/ec2-user/repo

# Check auto-remediation status
systemctl status auto-storage-expansion.service
journalctl -u auto-storage-expansion.service -f
```

### Auto-Remediation Verification
```bash
# Check service status
systemctl status auto-storage-expansion.service

# Check logs
journalctl -u auto-storage-expansion.service -f

# Check expansion logs
tail -f /home/ec2-user/auto-remediation/auto-expand-hybrid.log

# Check expansion history
cat /home/ec2-user/auto-remediation/expansion-history.log

# Check disk usage
df -h /dev/xvda1
```

## Troubleshooting

### Common Issues

1. **Docker permission denied**
   - Solution: Log out and log back in, or run `newgrp docker`

2. **Docker service not running**
   - Solution: `sudo systemctl start docker && sudo systemctl enable docker`

3. **Docker Compose not found**
   - Solution: Check if the binary was downloaded to `/usr/local/lib/docker/cli-plugins/docker-compose`

4. **SSH connection issues**
   - Verify SSH key permissions: `chmod 600 ~/Documents/truh-autoremed.pem`
   - Check SSH config: `~/.ssh/config`

5. **Auto-remediation service not running**
   - Solution: `sudo systemctl start auto-storage-expansion.service && sudo systemctl enable auto-storage-expansion.service`

### Debug Commands

```bash
# Check Docker service status
./scripts/ansible-helper.sh command all 'systemctl status docker'

# Check Docker group membership
./scripts/ansible-helper.sh command all 'groups'

# Check Docker Compose installation
./scripts/ansible-helper.sh command all 'ls -la /usr/local/lib/docker/cli-plugins/'

# Check repo directory
./scripts/ansible-helper.sh command all 'ls -la /home/ec2-user/repo'

# Check auto-remediation service
./scripts/ansible-helper.sh command backend_servers 'systemctl status auto-storage-expansion.service'

# Check auto-remediation logs
./scripts/ansible-helper.sh command backend_servers 'journalctl -u auto-storage-expansion.service -f'
```

## Security Notes

- Docker group membership allows running Docker commands without sudo
- SSH key permissions are automatically set to 600
- Host key checking is disabled for development convenience
- Backend server access is restricted through frontend server
- Auto-remediation uses local AWS CLI credentials (no IAM roles on EC2)

## Next Steps

After installation:

1. Clone your application repository to `/home/ec2-user/repo`
2. Set up your Docker Compose files
3. Deploy your applications
4. Set up monitoring and logging
5. Verify auto-remediation system is working
6. Test storage expansion functionality 