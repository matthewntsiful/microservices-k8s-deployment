#!/bin/bash

# Deploy updates to existing Kind cluster
set -e

REGISTRY=${1:-"ghcr.io"}
REPO=${2:-"$GITHUB_REPOSITORY"}
TAG=${3:-"latest"}
NAMESPACE=${4:-"microservices"}

echo "🚀 Deploying update to Kind cluster..."
echo "Registry: $REGISTRY"
echo "Repository: $REPO"
echo "Tag: $TAG"
echo "Namespace: $NAMESPACE"

# Update manifests
find k8s-manifests -name '*.yaml' -exec sed -i.bak \
    "s|matthewntsiful/microservices-|${REGISTRY}/${REPO}/microservices-|g" {} \;
find k8s-manifests -name '*.yaml' -exec sed -i.bak \
    "s|:latest|:${TAG}|g" {} \;

# Apply updates
kubectl apply -f k8s-manifests/ -n "$NAMESPACE"

# Restart deployments to pull new images
kubectl rollout restart deployment --all -n "$NAMESPACE"

# Wait for rollout
kubectl rollout status deployment --all -n "$NAMESPACE" --timeout=300s

# Clean up backup files
find k8s-manifests -name '*.bak' -delete

echo "✅ Update deployed successfully!"