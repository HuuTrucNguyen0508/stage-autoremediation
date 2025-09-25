#!/bin/bash

# Build custom nginx image for frontend
echo "Building custom nginx image for frontend..."
docker build -f Dockerfile.nginx.frontend -t truh1-nginx-frontend:latest .

echo "Custom nginx image built successfully!"
echo "Image: truh1-nginx-frontend:latest" 