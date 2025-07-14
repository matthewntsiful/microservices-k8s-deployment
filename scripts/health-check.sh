#!/bin/bash

# Comprehensive health check script for microservices
set -e

NAMESPACE=${1:-microservices}
TIMEOUT=${2:-300}

echo "🔍 Running health checks for namespace: $NAMESPACE"

# Check if namespace exists
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    echo "❌ Namespace $NAMESPACE does not exist"
    exit 1
fi

# Wait for all pods to be ready
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod --all -n $NAMESPACE --timeout=${TIMEOUT}s

# Check deployment status
echo "📊 Checking deployment status..."
kubectl get deployments -n $NAMESPACE

# Check service endpoints
echo "🔗 Checking service endpoints..."
kubectl get endpoints -n $NAMESPACE

# Test frontend health endpoint
echo "🏥 Testing frontend health endpoint..."
kubectl port-forward -n $NAMESPACE svc/frontend 8080:80 &
PF_PID=$!
sleep 10

if curl -f http://localhost:8080/_healthz; then
    echo "✅ Frontend health check passed"
else
    echo "❌ Frontend health check failed"
    kill $PF_PID 2>/dev/null || true
    exit 1
fi

kill $PF_PID 2>/dev/null || true

# Check HPA status
echo "📈 Checking HPA status..."
kubectl get hpa -n $NAMESPACE

# Check resource usage
echo "💾 Checking resource usage..."
kubectl top pods -n $NAMESPACE

echo "✅ All health checks passed successfully!"