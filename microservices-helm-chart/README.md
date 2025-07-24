# Microservices Helm Chart

A Helm chart for deploying the microservices-based e-commerce application on Kubernetes.

## Prerequisites

- Kubernetes 1.20+
- Helm 3.0+
- NGINX Ingress Controller (if ingress is enabled)
- Metrics Server (if autoscaling is enabled)

## Installation

### Add the chart repository (if published)
```bash
helm repo add microservices https://your-repo-url
helm repo update
```

### Install from local directory
```bash
# Install with default values
helm install microservices ./microservices-helm-chart

# Install with custom values
helm install microservices ./microservices-helm-chart -f custom-values.yaml

# Install in specific namespace
helm install microservices ./microservices-helm-chart --namespace microservices --create-namespace
```

## Configuration

The following table lists the configurable parameters and their default values:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.namespace` | Kubernetes namespace | `microservices` |
| `global.imageRegistry` | Container image registry | `matthewntsiful` |
| `global.imageTag` | Container image tag | `latest` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.host` | Ingress hostname | `microservices.local` |
| `autoscaling.enabled` | Enable HPA | `true` |
| `services.frontend.replicas` | Frontend replica count | `1` |

## Examples

### Custom Values File
```yaml
# custom-values.yaml
global:
  imageRegistry: "your-registry"
  imageTag: "v1.2.3"

ingress:
  host: "myapp.example.com"

autoscaling:
  frontend:
    maxReplicas: 20
```

### Install with custom values
```bash
helm install microservices ./microservices-helm-chart -f custom-values.yaml
```

## Upgrading

```bash
helm upgrade microservices ./microservices-helm-chart
```

## Uninstalling

```bash
helm uninstall microservices
```

## Troubleshooting

### Check deployment status
```bash
kubectl get pods -n microservices
helm status microservices
```

### View logs
```bash
kubectl logs -f deployment/frontend -n microservices
```

### Debug template rendering
```bash
helm template microservices ./microservices-helm-chart --debug
```