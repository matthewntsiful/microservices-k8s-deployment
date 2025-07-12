#!/bin/bash

# Set your Docker registry (replace with your registry)
REGISTRY="your-registry.com/your-username"

# Update image references in all YAML files
find microservices-demo/kubernetes-manifests -name "*.yaml" -exec sed -i '' "s|image: \([^/]*\)$|image: ${REGISTRY}/\1:latest|g" {} \;

echo "Updated all image references to use registry: ${REGISTRY}"