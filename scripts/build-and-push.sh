#!/bin/bash

# Build and Push Script for Microservices
# Usage: ./scripts/build-and-push.sh [GITHUB_USERNAME] [IMAGE_TAG]

set -e

# Configuration
GITHUB_USERNAME=${1:-"matthewntsiful"}
IMAGE_TAG=${2:-"latest"}
GHCR_REGISTRY="ghcr.io"

# Services to build
SERVICES=(
    "frontend"
    "cartservice" 
    "productcatalogservice"
    "currencyservice"
    "paymentservice"
    "shippingservice"
    "emailservice"
    "checkoutservice"
    "recommendationservice"
    "adservice"
    "loadgenerator"
    "shoppingassistantservice"
)

echo "🚀 Starting build and push process..."
echo "📦 Registry: $GHCR_REGISTRY"
echo "👤 Username: $GITHUB_USERNAME"
echo "🏷️  Tag: $IMAGE_TAG"

# Login to GHCR (requires GITHUB_TOKEN environment variable)
echo "🔐 Logging into GitHub Container Registry..."
echo $GITHUB_TOKEN | docker login $GHCR_REGISTRY -u $GITHUB_USERNAME --password-stdin

# Build and push each service
for service in "${SERVICES[@]}"; do
    echo "🔨 Building $service..."
    
    # Navigate to service directory
    cd microservices-demo/src/$service
    
    # Build image
    docker build -t $GHCR_REGISTRY/$GITHUB_USERNAME/microservices-$service:$IMAGE_TAG .
    docker tag $GHCR_REGISTRY/$GITHUB_USERNAME/microservices-$service:$IMAGE_TAG $GHCR_REGISTRY/$GITHUB_USERNAME/microservices-$service:latest
    
    # Security scan with Trivy
    echo "🔍 Scanning $service for vulnerabilities..."
    trivy image --exit-code 0 --severity HIGH,CRITICAL $GHCR_REGISTRY/$GITHUB_USERNAME/microservices-$service:$IMAGE_TAG
    
    # Push image
    echo "📤 Pushing $service..."
    docker push $GHCR_REGISTRY/$GITHUB_USERNAME/microservices-$service:$IMAGE_TAG
    docker push $GHCR_REGISTRY/$GITHUB_USERNAME/microservices-$service:latest
    
    # Return to root directory
    cd ../../..
    
    echo "✅ Completed $service"
done

echo "🎉 All services built and pushed successfully!"
echo "📊 Summary:"
for service in "${SERVICES[@]}"; do
    echo "  - microservices-$service:$IMAGE_TAG"
done