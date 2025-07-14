#!/bin/bash

# Install VPA (Vertical Pod Autoscaler)
echo "Installing Vertical Pod Autoscaler..."

# Clone VPA repository
git clone https://github.com/kubernetes/autoscaler.git /tmp/autoscaler

# Install VPA
cd /tmp/autoscaler/vertical-pod-autoscaler/
./hack/vpa-install.sh

# Verify installation
echo "Verifying VPA installation..."
kubectl get pods -n kube-system | grep vpa

# Cleanup
rm -rf /tmp/autoscaler

echo "VPA installation completed!"