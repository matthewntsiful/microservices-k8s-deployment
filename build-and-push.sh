#!/bin/bash

# Set your Docker registry (replace with your registry)
REGISTRY="your-registry.com/your-username"

# Services to build
SERVICES=(
    "emailservice"
    "productcatalogservice" 
    "recommendationservice"
    "shippingservice"
    "checkoutservice"
    "paymentservice"
    "currencyservice"
    "frontend"
    "adservice"
    "loadgenerator"
)

# Special case for cartservice (different context)
echo "Building cartservice..."
docker build -t ${REGISTRY}/cartservice:latest microservices-demo/src/cartservice/src
docker push ${REGISTRY}/cartservice:latest

# Build and push other services
for service in "${SERVICES[@]}"; do
    echo "Building ${service}..."
    docker build -t ${REGISTRY}/${service}:latest microservices-demo/src/${service}
    docker push ${REGISTRY}/${service}:latest
done

echo "All images built and pushed!"