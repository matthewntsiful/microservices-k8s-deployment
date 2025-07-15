# Microservices Kubernetes Deployment

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com/)
[![Redis](https://img.shields.io/badge/Redis-DC382D?style=for-the-badge&logo=redis&logoColor=white)](https://redis.io/)
[![Go](https://img.shields.io/badge/Go-00ADD8?style=for-the-badge&logo=go&logoColor=white)](https://golang.org/)
[![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/)
[![.NET](https://img.shields.io/badge/.NET-512BD4?style=for-the-badge&logo=dotnet&logoColor=white)](https://dotnet.microsoft.com/)

![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)
![Status](https://img.shields.io/badge/Status-Production%20Ready-green.svg)
![Version](https://img.shields.io/badge/Version-1.0.0-blue.svg)

A production-ready Kubernetes deployment of a microservices-based e-commerce application, featuring 12 interconnected services with proper security, monitoring, and scalability configurations.

![Frontend](screenshots/frontend.png)

## 🏗️ Architecture Overview

This project demonstrates a complete microservices architecture deployed on Kubernetes, showcasing:

- **12 Microservices** written in Go, Node.js, Python, Java, and C#
- **Service Mesh Communication** via gRPC and HTTP
- **Redis Cache** for session and cart storage
- **Namespace Isolation** for security and organization
- **Ingress Controller** for external access
- **ConfigMaps & Secrets** for configuration management
- **Resource Limits & Health Probes** for reliability
- **Horizontal Pod Autoscaler (HPA)** for automatic scaling

## 🎯 Original Work Attribution

This deployment is based on the excellent [Google Cloud Microservices Demo](https://github.com/GoogleCloudPlatform/microservices-demo) (formerly known as "Hipster Shop"). The original demo was created by Google Cloud Platform team to demonstrate cloud-native application development.

**Key Enhancements Made:**
- ✅ Kubernetes-native deployment manifests
- ✅ Namespace isolation and security hardening  
- ✅ Fixed service port mappings and health probes
- ✅ Redis authentication and connection optimization
- ✅ Production-ready resource limits and configurations
- ✅ Ingress controller setup for external access

## 🚀 Services Architecture

| Service | Language | Port | Description |
|---------|----------|------|-------------|
| **Frontend** | Go | 8080 | Web UI and API gateway |
| **Cart Service** | C# | 7070 | Shopping cart management |
| **Product Catalog** | Go | 8080 | Product inventory and details |
| **Currency Service** | Node.js | 8080 | Currency conversion |
| **Payment Service** | Node.js | 8080 | Payment processing |
| **Shipping Service** | Go | 8080 | Shipping cost calculation |
| **Email Service** | Python | 8080 | Order confirmation emails |
| **Checkout Service** | Go | 5050 | Order processing workflow |
| **Recommendation** | Python | 8080 | Product recommendations |
| **Ad Service** | Java | 9555 | Contextual advertisements |
| **Redis Cart** | Redis | 6379 | Session and cart storage |
| **Load Generator** | Python | - | Traffic simulation |

## 📚 Documentation

- **[Architecture Guide](ARCHITECTURE.md)** - Detailed technical architecture and service interconnections
- **[Autoscaling Guide](AUTOSCALING.md)** - HPA implementation and monitoring

## 📋 Prerequisites

- **Kubernetes Cluster** (v1.20+)
- **kubectl** configured and connected
- **NGINX Ingress Controller** installed
- **Docker** (for custom image builds)
- **Minimum Resources**: 4 CPU cores, 8GB RAM

### Quick Setup Commands

```bash
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Install Metrics Server (for HPA)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verify installation
kubectl get pods -n ingress-nginx
kubectl get pods -n kube-system | grep metrics-server
```

## 🛠️ Deployment Instructions

### Automated CI/CD Pipeline

**Prerequisites:**
- Kind cluster running locally
- GitHub self-hosted runner configured

**Setup:**
1. **Configure Self-Hosted Runner:**
   ```bash
   ./scripts/setup-github-runner.sh
   cd ~/actions-runner
   # Follow GitHub instructions to configure runner
   ./run.sh
   ```

2. **Automatic Deployment:**
   - Push to `main` branch triggers the pipeline
   - Pipeline builds images → pushes to GHCR → deploys to Kind
   - Manual trigger via GitHub Actions UI

### Manual Deployment

```bash
# Deploy all services
kubectl apply -f k8s-manifests/

# Verify deployment
kubectl get pods -n microservices
kubectl get svc -n microservices
```

![Cart](screenshots/cart.png)

### Access the Application
```bash
# Add to /etc/hosts (for local access)
echo "127.0.0.1 microservices.local" | sudo tee -a /etc/hosts

# Access the application
http://microservices.local/
```



## 🔧 Configuration Details

### Environment Variables
Key configurations managed via ConfigMap:
- Service discovery endpoints
- Feature flags (tracing, profiling)
- Application ports and timeouts

### Secrets Management
Sensitive data stored in Kubernetes Secrets:
- Redis authentication password
- API keys for external services

### Resource Allocation
Each service configured with:
- **CPU Requests**: 100-300m
- **Memory Requests**: 64-256Mi  
- **CPU Limits**: 200-500m
- **Memory Limits**: 128-512Mi

### Autoscaling
Horizontal Pod Autoscaler (HPA) configured for:
- **Frontend**: 2-10 replicas (70% CPU, 80% memory)
- **Cart Service**: 1-8 replicas (75% CPU)
- **Checkout Service**: 1-6 replicas (70% CPU)
- **Product Catalog**: 1-5 replicas (80% CPU)
- **Recommendation**: 1-4 replicas (75% CPU)

## 🔍 Monitoring & Debugging

![Order Confirmation](screenshots/order-confirmation.png)

### Kubernetes Lens Integration
This project is monitored using [Kubernetes Lens](https://k8slens.dev/) for comprehensive cluster visualization and management.

### Health Checks
```bash
# Check pod health
kubectl describe pod <pod-name> -n microservices

# View logs
kubectl logs <pod-name> -n microservices

# Port forward for debugging
kubectl port-forward -n microservices svc/frontend 8080:80
```

### Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Pods CrashLoopBackOff | Check logs: `kubectl logs <pod> -n microservices` |
| Service connection refused | Verify port mappings in service manifests |
| Redis authentication failed | Check REDIS_ADDR connection string format |
| Ingress not accessible | Verify NGINX Ingress Controller is running |

## 🏷️ Service Tags & Images

**Container Registry:** GitHub Container Registry (GHCR)
```
ghcr.io/matthewntsiful/microservices-k8s-deployment/microservices-<service-name>:latest
```

**CI/CD Pipeline:**
- **Build:** Builds all 10 microservice images
- **Scan:** Security scans with Trivy
- **Deploy:** Deploys to Kind cluster with rolling updates

**Manual Build:**
```bash
# Build and push individual service
docker build -t ghcr.io/username/repo/microservices-frontend:tag ./microservices-demo/src/frontend
docker push ghcr.io/username/repo/microservices-frontend:tag
```

## 🔐 Security Features

- **Namespace Isolation**: All resources deployed in dedicated namespace
- **Secret Management**: Sensitive data encrypted in Kubernetes Secrets
- **Network Policies**: Service-to-service communication controls
- **Resource Limits**: Prevent resource exhaustion attacks
- **Redis Authentication**: Password-protected cache access

## 📊 Performance & Scaling

### Horizontal Pod Autoscaling
```bash
# Deploy HPA configurations
kubectl apply -f k8s-manifests/16-hpa.yaml

# Monitor scaling
kubectl get hpa -n microservices
kubectl top pods -n microservices
```

### Load Testing
Use the included load generator:
```bash
kubectl logs -f deployment/loadgenerator -n microservices
```



## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Google Cloud Platform Team** for the original microservices demo
- **Kubernetes Community** for the excellent orchestration platform
- **CNCF Projects** (Kubernetes, gRPC, etc.) for cloud-native technologies

## 📞 Support

For issues and questions:
- Create an issue in this repository
- Check the [troubleshooting guide](#-monitoring--debugging)
- Review the original [Google Cloud Microservices Demo](https://github.com/GoogleCloudPlatform/microservices-demo)

---

**⭐ Star this repository if it helped you learn Kubernetes microservices deployment!**