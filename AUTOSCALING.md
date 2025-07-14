# Autoscaling Implementation Guide

## Overview
This document covers the implementation of Horizontal Pod Autoscaler (HPA) for the microservices deployment.

## Prerequisites

### 1. Install Metrics Server (Cluster-wide)
```bash
# Official installation
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# For local/development clusters (if TLS issues)
# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/high-availability.yaml
```



## Horizontal Pod Autoscaler (HPA)

### Configuration
HPA automatically scales the number of pods based on CPU/memory utilization:

```bash
kubectl apply -f k8s-manifests/16-hpa.yaml
```

### HPA Targets
| Service | Min Replicas | Max Replicas | CPU Target | Memory Target |
|---------|--------------|--------------|------------|---------------|
| Frontend | 1 | 10 | 70% | 80% |
| Cart Service | 1 | 8 | 75% | - |
| Checkout Service | 1 | 6 | 70% | - |
| Product Catalog | 1 | 5 | 80% | - |
| Recommendation | 1 | 4 | 75% | - |

### Monitor HPA
```bash
# Check HPA status
kubectl get hpa -n microservices

# Watch HPA in real-time
kubectl get hpa -n microservices -w

# Describe specific HPA
kubectl describe hpa frontend-hpa -n microservices
```



## Load Testing

### Generate Load
```bash
# Scale load generator
kubectl scale deployment loadgenerator --replicas=3 -n microservices

# Monitor resource usage
kubectl top pods -n microservices
```

### Watch Scaling Events
```bash
# Monitor HPA scaling
kubectl get events -n microservices --field-selector reason=SuccessfulRescale

# Monitor pod creation/deletion
kubectl get events -n microservices --field-selector reason=Created
```

## Troubleshooting

### HPA Issues
```bash
# Check metrics availability
kubectl top nodes
kubectl top pods -n microservices

# Verify metrics server
kubectl get pods -n kube-system | grep metrics-server
```



## Best Practices

1. **Resource Requests**: Ensure all pods have resource requests defined
2. **Monitoring**: Use monitoring tools to track scaling behavior
3. **Testing**: Test autoscaling under realistic load conditions
4. **Limits**: Set appropriate min/max values to prevent over-scaling
5. **Resource Requests**: Ensure pods have proper resource requests for accurate scaling