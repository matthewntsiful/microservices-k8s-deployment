#!/bin/bash

# Script to update Kubernetes manifests with GHCR images
set -e

REGISTRY=${1:-"ghcr.io"}
REPO=${2:-"$GITHUB_REPOSITORY"}
TAG=${3:-"latest"}

if [ -z "$REPO" ]; then
    echo "❌ Repository not specified. Usage: $0 [registry] [repository] [tag]"
    exit 1
fi

echo "🔄 Updating manifests with:"
echo "   Registry: $REGISTRY"
echo "   Repository: $REPO"
echo "   Tag: $TAG"

# Create backup
cp -r k8s-manifests k8s-manifests-backup

# Update image references
find k8s-manifests -name '*.yaml' -type f -exec sed -i.bak \
    "s|matthewntsiful/microservices-|${REGISTRY}/${REPO}/microservices-|g" {} \;

find k8s-manifests -name '*.yaml' -type f -exec sed -i.bak \
    "s|:latest|:${TAG}|g" {} \;

# Clean up backup files
find k8s-manifests -name '*.bak' -delete

echo "✅ Manifests updated successfully"
echo "📁 Backup created at k8s-manifests-backup/"