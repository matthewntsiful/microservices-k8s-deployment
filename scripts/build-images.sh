#!/bin/bash

# Build and push all microservice images
set -e

REGISTRY="matthewntsiful"
TAG=${1:-latest}

SERVICES=(
    "frontend"
    "cartservice" 
    "checkoutservice"
    "productcatalogservice"
    "currencyservice"
    "paymentservice"
    "shippingservice"
    "emailservice"
    "recommendationservice"
    "adservice"
)

echo "Building and pushing images with tag: $TAG"

for service in "${SERVICES[@]}"; do
    echo "Building $service..."
    docker build -t $REGISTRY/microservices-$service:$TAG ./microservices-demo/src/$service
    docker push $REGISTRY/microservices-$service:$TAG
    echo "✅ $service pushed successfully"
done

echo "🎉 All images built and pushed successfully!"