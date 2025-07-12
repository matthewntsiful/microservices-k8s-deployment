#!/bin/bash

# Deploy to Kubernetes cluster
kubectl apply -f microservices-demo/kubernetes-manifests/

# Wait for pods to be ready
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod --all --timeout=300s

# Get frontend external IP
echo "Getting frontend external IP..."
kubectl get service frontend-external