# Microservices Kubernetes Deployment Guide

## 📋 Table of Contents
- [Prerequisites](#prerequisites)
- [Architecture Overview](#architecture-overview)
- [Deployment Methods](#deployment-methods)
- [Step-by-Step Deployment](#step-by-step-deployment)
- [Monitoring Setup](#monitoring-setup)
- [Troubleshooting](#troubleshooting)
- [Production Considerations](#production-considerations)

## 🔧 Prerequisites

### Required Tools
```bash
# Install required CLI tools
kubectl --version    # v1.20+
helm version        # v3.0+
eksctl version      # Latest
aws --version       # v2.0+
```

### AWS Requirements
- **EKS Cluster** with 3+ nodes (t3.medium or larger)
- **VPC** with public/private subnets
- **IAM permissions** for EKS, ALB, and EC2
- **AWS CLI** configured with proper credentials

### Cluster Specifications
- **Kubernetes Version**: 1.20+
- **Node Type**: t3.medium (2 vCPU, 4GB RAM) minimum
- **Node Count**: 3 nodes minimum
- **Storage**: 20GB EBS per node

## 🏗️ Architecture Overview

### Microservices Components
| Service | Language | Port | Description |
|---------|----------|------|-------------|
| Frontend | Go | 8080 | Web UI and API gateway |
| Cart Service | C# | 7070 | Shopping cart management |
| Product Catalog | Go | 8080 | Product inventory |
| Currency Service | Node.js | 8080 | Currency conversion |
| Payment Service | Node.js | 8080 | Payment processing |
| Shipping Service | Go | 8080 | Shipping calculations |
| Email Service | Python | 8080 | Order notifications |
| Checkout Service | Go | 5050 | Order processing |
| Recommendation | Python | 8080 | Product recommendations |
| Ad Service | Java | 9555 | Advertisements |
| Redis Cart | Redis | 6379 | Session storage |
| Load Generator | Python | - | Traffic simulation |

### Infrastructure Components
- **AWS Application Load Balancer (ALB)** - External traffic routing
- **ClusterIP Services** - Internal service communication
- **Horizontal Pod Autoscaler (HPA)** - Automatic scaling
- **ConfigMaps & Secrets** - Configuration management
- **Prometheus Node Exporter** - Metrics collection
- **Grafana** - Monitoring dashboards

## 🚀 Deployment Methods

This project supports two deployment approaches:

### Method 1: Helm Chart (Recommended)
- **Production-ready** with configurable values
- **AWS ALB Ingress** with proper IAM setup
- **ClusterIP services** for internal communication
- **Autoscaling** and monitoring included

### Method 2: Kubernetes Manifests
- **Direct kubectl** deployment
- **NGINX Ingress** with LoadBalancer service
- **Static configuration** for testing/development

## 📖 Step-by-Step Deployment

### Step 1: Prepare EKS Cluster

```bash
# Create EKS cluster (if not exists)
eksctl create cluster \
  --name amazon-eks-cluster \
  --region us-east-1 \
  --nodegroup-name worker-nodes \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 4 \
  --managed

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name amazon-eks-cluster

# Verify cluster access
kubectl get nodes
```

### Step 2: Install Required Controllers

#### AWS Load Balancer Controller
```bash
# Add Helm repository
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Create IAM OIDC provider
eksctl utils associate-iam-oidc-provider \
  --region us-east-1 \
  --cluster amazon-eks-cluster \
  --approve

# Download IAM policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.13.3/docs/install/iam_policy.json

# Create IAM policy
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json

# Create IAM service account
eksctl create iamserviceaccount \
  --cluster=amazon-eks-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::YOUR_ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --override-existing-serviceaccounts

# Install AWS Load Balancer Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=amazon-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-east-1 \
  --set vpcId=YOUR_VPC_ID
```

#### Metrics Server (for HPA)
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### Step 3: Deploy Microservices

#### Option A: Helm Chart Deployment (Recommended)

```bash
# Clone repository
git clone https://github.com/your-username/microservices-k8s-deployment.git
cd microservices-k8s-deployment

# Deploy with Helm
helm install microservices ./microservices-helm-chart \
  --namespace microservices \
  --create-namespace

# Verify deployment
kubectl get pods -n microservices
kubectl get svc -n microservices
kubectl get ingress -n microservices
```

#### Option B: Kubernetes Manifests

```bash
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/aws/deploy.yaml

# Deploy microservices
kubectl apply -f k8s-manifests/

# Verify deployment
kubectl get pods -n microservices
kubectl get svc -n microservices
```

### Step 4: Configure Access

#### Get Application URL
```bash
# For Helm deployment (ALB)
kubectl get ingress microservices-ingress -n microservices

# For K8s manifests (LoadBalancer)
kubectl get svc frontend -n microservices
```

#### Access Application
```bash
# Add to hosts file (for custom domain)
echo "ALB_ADDRESS microservices.local" | sudo tee -a /etc/hosts

# Access application
curl http://microservices.local
# or
curl http://LOADBALANCER_IP
```

### Step 5: Verify Autoscaling

```bash
# Check HPA status
kubectl get hpa -n microservices

# Monitor pod scaling
kubectl top pods -n microservices
kubectl get pods -n microservices -w
```

## 📊 Monitoring Setup

### Install Grafana
```bash
# Add Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Grafana
helm install grafana grafana/grafana \
  --namespace monitoring \
  --create-namespace \
  --set adminPassword=admin123 \
  --set service.type=LoadBalancer \
  --set resources.requests.cpu=100m \
  --set resources.requests.memory=128Mi
```

### Access Grafana
```bash
# Get LoadBalancer IP
kubectl get svc grafana -n monitoring

# Or use port-forwarding
kubectl port-forward svc/grafana 3000:80 -n monitoring
```

### Configure Data Sources
1. **Access Grafana**: http://LOADBALANCER_IP or http://localhost:3000
2. **Login**: admin / admin123
3. **Add Prometheus data source**: http://prometheus-node-exporter:9100
4. **Import dashboards**: Use IDs 315, 1860 for Kubernetes monitoring

## 🔧 Troubleshooting

### Common Issues

#### 1. Pods in CrashLoopBackOff
```bash
# Check pod logs
kubectl logs POD_NAME -n microservices

# Check pod events
kubectl describe pod POD_NAME -n microservices

# Common fix: Environment variable issues
kubectl get configmap microservices-config -n microservices -o yaml
```

#### 2. Ingress Not Getting Address
```bash
# Check AWS Load Balancer Controller
kubectl get pods -n kube-system | grep aws-load-balancer
kubectl logs deployment/aws-load-balancer-controller -n kube-system

# Check IAM permissions
kubectl describe serviceaccount aws-load-balancer-controller -n kube-system
```

#### 3. Service Connection Issues
```bash
# Check service endpoints
kubectl get endpoints -n microservices

# Test service connectivity
kubectl run test-pod --image=busybox -it --rm -- /bin/sh
# Inside pod: wget -qO- http://SERVICE_NAME:PORT
```

#### 4. Resource Constraints
```bash
# Check node resources
kubectl top nodes
kubectl describe nodes

# Check pod resource usage
kubectl top pods -n microservices

# Scale down if needed
kubectl scale deployment DEPLOYMENT_NAME --replicas=1 -n microservices
```

### Webhook Conflicts
```bash
# Remove conflicting webhooks
kubectl delete validatingwebhookconfiguration ingress-nginx-admission
kubectl delete mutatingwebhookconfiguration aws-load-balancer-webhook
```

## 🏭 Production Considerations

### Security
- [ ] **TLS/SSL certificates** for HTTPS
- [ ] **Network policies** for service isolation
- [ ] **Pod security policies** or Pod Security Standards
- [ ] **Secrets management** with AWS Secrets Manager
- [ ] **Image scanning** for vulnerabilities

### Scalability
- [ ] **Cluster autoscaler** for node scaling
- [ ] **Vertical Pod Autoscaler** for right-sizing
- [ ] **Resource quotas** per namespace
- [ ] **Load testing** with realistic traffic

### Monitoring & Observability
- [ ] **Distributed tracing** with Jaeger/Zipkin
- [ ] **Centralized logging** with ELK stack
- [ ] **Custom metrics** and alerts
- [ ] **SLI/SLO definitions** and monitoring

### Backup & Disaster Recovery
- [ ] **ETCD backups** for cluster state
- [ ] **Persistent volume backups**
- [ ] **Multi-region deployment** for HA
- [ ] **Disaster recovery procedures**

### CI/CD Integration
- [ ] **GitOps** with ArgoCD or Flux
- [ ] **Automated testing** in pipeline
- [ ] **Blue-green deployments**
- [ ] **Rollback procedures**

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS EKS User Guide](https://docs.aws.amazon.com/eks/)
- [Helm Documentation](https://helm.sh/docs/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Prometheus Monitoring](https://prometheus.io/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.