# Testing Guide

## Testing Environments

### 1. Kind (Kubernetes in Docker)
### 2. Docker Desktop Kubernetes
### 3. Minikube

## Prerequisites for Testing

```bash
# Install Kind
brew install kind

# Install Docker Desktop with Kubernetes enabled
# Enable Kubernetes in Docker Desktop settings

# Verify kubectl
kubectl version --client
```

## Test Script

```bash
#!/bin/bash
set -e

echo "🚀 Testing Microservices Deployment"
echo "Environment: $1"

# Deploy all manifests
kubectl apply -f k8s-manifests/

# Wait for pods to be ready
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod --all -n microservices --timeout=300s

# Check deployment status
echo "📊 Deployment Status:"
kubectl get pods -n microservices
kubectl get svc -n microservices
kubectl get ingress -n microservices

echo "✅ Deployment completed successfully!"
```