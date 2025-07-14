#!/bin/bash

# Deploy microservices to Kind cluster
set -e

CLUSTER_NAME=${1:-"microservices-kind"}
NAMESPACE=${2:-"microservices"}
REGISTRY=${3:-"ghcr.io"}
REPO=${4:-"$GITHUB_REPOSITORY"}
TAG=${5:-"latest"}

echo "🚀 Deploying to Kind cluster: $CLUSTER_NAME"

# Check if cluster exists
if ! kind get clusters | grep -q "$CLUSTER_NAME"; then
    echo "❌ Kind cluster '$CLUSTER_NAME' not found"
    echo "Creating cluster..."
    
    cat > kind-config.yaml << EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
- role: worker
- role: worker
EOF
    
    kind create cluster --name "$CLUSTER_NAME" --config kind-config.yaml
    rm kind-config.yaml
fi

# Set kubectl context
kubectl config use-context "kind-$CLUSTER_NAME"

# Install NGINX Ingress
echo "📦 Installing NGINX Ingress..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s

# Install Metrics Server
echo "📊 Installing Metrics Server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch -n kube-system deployment metrics-server --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Create namespace
echo "🏗️  Creating namespace: $NAMESPACE"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Update manifests if registry/repo/tag provided
if [ -n "$REPO" ] && [ "$REPO" != "" ]; then
    echo "🔄 Updating manifests..."
    ./scripts/update-manifests.sh "$REGISTRY" "$REPO" "$TAG"
fi

# Deploy services
echo "🚀 Deploying services..."
kubectl apply -f k8s-manifests/ -n "$NAMESPACE"

# Wait for deployments
echo "⏳ Waiting for deployments to be ready..."
kubectl rollout status deployment --all -n "$NAMESPACE" --timeout=600s

# Wait for pods
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod --all -n "$NAMESPACE" --timeout=300s

# Show status
echo "📊 Deployment Status:"
kubectl get pods -n "$NAMESPACE"
kubectl get svc -n "$NAMESPACE"
kubectl get ingress -n "$NAMESPACE"

echo "✅ Deployment completed successfully!"
echo "🌐 Access the application at: http://localhost"