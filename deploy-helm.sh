#!/bin/bash

set -e

CHART_NAME="microservices"
CHART_PATH="./microservices-helm-chart"
NAMESPACE="microservices"

echo "🚀 Deploying Microservices with Helm..."

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install Helm first."
    exit 1
fi

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ kubectl is not configured or cluster is not accessible."
    exit 1
fi

# Create namespace if it doesn't exist
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Install or upgrade the Helm chart
if helm list -n $NAMESPACE | grep -q $CHART_NAME; then
    echo "📦 Upgrading existing release..."
    helm upgrade $CHART_NAME $CHART_PATH --namespace $NAMESPACE
else
    echo "📦 Installing new release..."
    helm install $CHART_NAME $CHART_PATH --namespace $NAMESPACE
fi

echo "✅ Deployment completed!"
echo ""
echo "📊 Check deployment status:"
echo "kubectl get pods -n $NAMESPACE"
echo ""
echo "🌐 Access the application:"
echo "Add '127.0.0.1 microservices.local' to /etc/hosts"
echo "Then visit: http://microservices.local"