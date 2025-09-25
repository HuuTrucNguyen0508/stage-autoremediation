#!/bin/bash

# Script to push custom images to Docker Hub
# Usage: ./push-to-dockerhub.sh <dockerhub-username>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}[HEADER]${NC} $1"
}

# Check if username is provided
if [ $# -eq 0 ]; then
    print_error "Please provide your Docker Hub username"
    echo "Usage: $0 <dockerhub-username>"
    echo "Example: $0 huutrucnguyen"
    exit 1
fi

DOCKERHUB_USERNAME=$1
print_header "Pushing custom images to Docker Hub as user: $DOCKERHUB_USERNAME"

# List of images to push (only the custom images we built)
IMAGES=(
    "truh1-nginx-frontend:latest"
    "truh1-nginx-backend:latest"
    "truh1-prometheus:latest"
    "truh1-loki:latest"
    "truh1-promtail:latest"
    "truh1-grafana:latest"
)

# Check if images exist locally
print_status "Checking if all images exist locally..."
for image in "${IMAGES[@]}"; do
    if ! docker image inspect "$image" >/dev/null 2>&1; then
        print_error "Image $image not found locally. Please run ./deploy-simplified.sh first."
        exit 1
    fi
done

print_status "All images found locally. Proceeding with push..."

# Tag and push each image
for image in "${IMAGES[@]}"; do
    # Extract image name without tag
    image_name=$(echo "$image" | cut -d':' -f1)
    
    # Create Docker Hub tag
    dockerhub_tag="${DOCKERHUB_USERNAME}/${image_name}:latest"
    
    print_status "Tagging $image as $dockerhub_tag"
    docker tag "$image" "$dockerhub_tag"
    
    print_status "Pushing $dockerhub_tag to Docker Hub..."
    docker push "$dockerhub_tag"
    
    print_status "✅ Successfully pushed $dockerhub_tag"
done

print_header "🎉 All images pushed successfully to Docker Hub!"
print_status "Images pushed:"
for image in "${IMAGES[@]}"; do
    image_name=$(echo "$image" | cut -d':' -f1)
    echo "  - ${DOCKERHUB_USERNAME}/${image_name}:latest"
done

print_status "📋 Next steps:"
echo "  1. Update your docker-compose.yaml files to use the Docker Hub images:"
echo "     Replace 'truh1-*:latest' with '${DOCKERHUB_USERNAME}/truh1-*:latest'"
echo ""
echo "  2. On your EC2 instances, you can now pull and run:"
echo "     docker compose up -d"
echo ""
echo "  3. The images will be automatically pulled from Docker Hub" 