#!/bin/bash

# Build custom nginx image for backend
echo "Building custom nginx image for backend..."
docker build -f Dockerfile.nginx -t truh1-nginx-backend:latest .

# Build custom prometheus image
echo "Building custom prometheus image..."
docker build -f Dockerfile.prometheus -t truh1-prometheus:latest .

# Build custom alertmanager image
echo "Building custom alertmanager image..."
docker build -f Dockerfile.alertmanager -t truh1-alertmanager:latest .

# Build custom loki image
echo "Building custom loki image..."
docker build -f Dockerfile.loki -t truh1-loki:latest .

# Build custom promtail image
echo "Building custom promtail image..."
docker build -f Dockerfile.promtail -t truh1-promtail:latest .

# Build custom grafana image
echo "Building custom grafana image..."
docker build -f Dockerfile.grafana -t truh1-grafana:latest .

echo "All custom images built successfully!"
echo "Images:"
echo "  - truh1-nginx-backend:latest"
echo "  - truh1-prometheus:latest"
echo "  - truh1-alertmanager:latest"
echo "  - truh1-loki:latest"
echo "  - truh1-promtail:latest"
echo "  - truh1-grafana:latest" 