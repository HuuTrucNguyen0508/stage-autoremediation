# Docker Hub Deployment Guide

This guide explains how to deploy your application using the custom Docker images hosted on Docker Hub.

## Overview

After building and pushing your custom images to Docker Hub, you can deploy your application on any EC2 instance by simply copying the docker-compose files and running them. The images will be automatically pulled from Docker Hub.

## Prerequisites

1. **Docker Hub Account**: You need a Docker Hub account to push and pull images
2. **Docker Installed**: Docker must be installed on your EC2 instances
3. **Custom Images Built**: Run `./deploy-simplified.sh` to build the images locally

## Step 1: Build and Push Images to Docker Hub

### 1.1 Build Images Locally

```bash
./deploy-simplified.sh
```

### 1.2 Push Images to Docker Hub

```bash
# Replace 'your-dockerhub-username' with your actual Docker Hub username
./push-to-dockerhub.sh your-dockerhub-username
```

This will push the following images to Docker Hub:

- `your-username/truh1-nginx-frontend:latest`
- `your-username/truh1-nginx-backend:latest`
- `your-username/truh1-prometheus:latest`
- `your-username/truh1-loki:latest`
- `your-username/truh1-promtail:latest`
- `your-username/truh1-grafana:latest`

## Step 2: Deploy to EC2 Instances

### Option A: Using Docker Hub Images (Recommended)

#### Frontend EC2

1. Copy the Docker Hub docker-compose file:

```bash
scp frontend-ec2/docker-compose-dockerhub.yaml ec2-user@your-frontend-ip:~/docker-compose.yaml
```

2. Set your Docker Hub username and deploy:

```bash
# On the frontend EC2 instance
export DOCKERHUB_USERNAME=your-dockerhub-username
docker compose up -d
```

#### Backend EC2

1. Copy the Docker Hub docker-compose file:

```bash
scp backend-ec2/docker-compose-dockerhub.yaml ec2-user@your-backend-ip:~/docker-compose.yaml
```

2. Set your Docker Hub username and deploy:

```bash
# On the backend EC2 instance
export DOCKERHUB_USERNAME=your-dockerhub-username
docker compose up -d
```

### Option B: Using Local Images (Alternative)

If you prefer to build images directly on the EC2 instances:

#### Frontend EC2

1. Copy the entire frontend-ec2 directory:

```bash
scp -r frontend-ec2 ec2-user@your-frontend-ip:~/
```

2. Build and deploy:

```bash
# On the frontend EC2 instance
cd frontend-ec2
./build-images.sh
docker compose up -d
```

#### Backend EC2

1. Copy the entire backend-ec2 directory:

```bash
scp -r backend-ec2 ec2-user@your-backend-ip:~/
```

2. Build and deploy:

```bash
# On the backend EC2 instance
cd backend-ec2
./build-images.sh
docker compose up -d
```

## Step 3: Verify Deployment

### Check Frontend

```bash
# Check if services are running
docker compose ps

# Check logs
docker compose logs

# Test the application
curl http://localhost/health
```

### Check Backend

```bash
# Check if services are running
docker compose ps

# Check logs
docker compose logs
```

## Environment Variables

The Docker Hub docker-compose files use the `DOCKERHUB_USERNAME` environment variable to specify which Docker Hub account to pull images from.

## Benefits of Docker Hub Deployment

1. **No Local Build Required**: Images are pre-built and ready to use
2. **Faster Deployment**: No need to build images on EC2 instances
3. **Consistent Images**: All instances use identical images
4. **Version Control**: Easy to rollback to previous versions
5. **Scalability**: Easy to deploy to multiple instances

## Troubleshooting

### Image Pull Issues

If you get "image not found" errors:

1. Verify the image exists on Docker Hub
2. Check your Docker Hub username is correct
3. Ensure you're logged into Docker Hub: `docker login`

### Permission Issues

If you get permission errors:

```bash
# Make sure you're in the docker group
sudo usermod -aG docker $USER
# Log out and back in, or run:
newgrp docker
```

### Network Issues

If containers can't communicate:

```bash
# Check if the network exists
docker network ls

# Create the network if needed
docker network create app-network
```
