#!/bin/bash

# Simplified deployment script that builds custom images and copies only docker-compose files
# This replaces the need for Ansible to copy configuration files

set -e

echo "🚀 Starting simplified deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Build frontend custom images
print_status "Building frontend custom images..."
./build-frontend-images.sh

# Build backend custom images
print_status "Building backend custom images..."
./build-backend-images.sh

print_status "✅ All custom images built successfully!"

print_status "📋 Deployment Summary:"
echo "  Frontend EC2 needs:"
echo "    - docker-compose.yaml"
echo "    - Custom nginx image: truh1-nginx-frontend:latest"
echo ""
echo "  Backend EC2 needs:"
echo "    - docker-compose.yaml"
echo "    - Custom images:"
echo "      - truh1-nginx-backend:latest"
echo "      - truh1-prometheus:latest"
echo "      - truh1-loki:latest"
echo "      - truh1-promtail:latest"
echo "      - truh1-grafana:latest"
echo ""
echo "🎉 Deployment ready! Just copy the docker-compose.yaml files to your EC2 instances." 