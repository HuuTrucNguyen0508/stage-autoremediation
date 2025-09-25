# Dockerfiles Directory

This directory contains all the Dockerfiles and configuration files needed to build the custom Docker images for the project.

## Contents

### Dockerfiles

- `Dockerfile.nginx` - Backend nginx with embedded configuration
- `Dockerfile.nginx.frontend` - Frontend nginx with embedded configuration
- `Dockerfile.prometheus` - Prometheus with embedded configuration
- `Dockerfile.loki` - Loki with embedded configuration
- `Dockerfile.promtail` - Promtail with embedded configuration
- `Dockerfile.grafana` - Grafana with embedded configuration

### Configuration Files

- `frontend-nginx.conf` - Frontend nginx configuration
- `backend-nginx.conf` - Backend nginx configuration
- `prometheus.yml` - Prometheus configuration
- `loki-config.yml` - Loki configuration
- `promtail-config.yml` - Promtail configuration
- `grafana/` - Grafana provisioning and dashboards

### Build Scripts

- `build-frontend-images.sh` - Build frontend custom images
- `build-backend-images.sh` - Build backend custom images
- `deploy-simplified.sh` - Build all custom images
- `push-to-dockerhub.sh` - Push images to Docker Hub

## Usage

### Build All Images

```bash
cd dockerfiles
./deploy-simplified.sh
```

### Build Frontend Images Only

```bash
cd dockerfiles
./build-frontend-images.sh
```

### Build Backend Images Only

```bash
cd dockerfiles
./build-backend-images.sh
```

### Push to Docker Hub

```bash
cd dockerfiles
./push-to-dockerhub.sh your-dockerhub-username
```

## Images Created

- `truh1-nginx-frontend:latest`
- `truh1-nginx-backend:latest`
- `truh1-prometheus:latest`
- `truh1-loki:latest`
- `truh1-promtail:latest`
- `truh1-grafana:latest`

## Deployment

For deployment instructions, see `DOCKERHUB_DEPLOYMENT.md`.
