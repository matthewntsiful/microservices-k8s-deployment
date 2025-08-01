# DevOps Deployment Guide - Microservices on EKS

## 📋 Table of Contents
- [Infrastructure Prerequisites](#infrastructure-prerequisites)
- [DevOps Architecture](#devops-architecture)
- [Infrastructure as Code](#infrastructure-as-code)
- [CI/CD Pipeline Setup](#cicd-pipeline-setup)
- [Automated Deployment](#automated-deployment)
- [Monitoring & Observability](#monitoring--observability)
- [Production Operations](#production-operations)
- [Disaster Recovery](#disaster-recovery)

## 🛠️ Infrastructure Prerequisites

### DevOps Toolchain
```bash
# Core Infrastructure Tools
terraform --version  # v1.0+ (Infrastructure as Code)
kubectl --version    # v1.20+ (Kubernetes CLI)
helm version        # v3.0+ (Package Manager)
eksctl version      # Latest (EKS Management)
aws --version       # v2.0+ (AWS CLI)

# CI/CD Tools
docker --version    # Container Runtime
git --version       # Version Control
jq --version        # JSON Processing
yq --version        # YAML Processing

# Monitoring & Observability
prometheus --version # Metrics Collection
grafana-cli --version # Dashboards
```

### AWS Infrastructure Requirements
- **EKS Cluster** with managed node groups
- **VPC** with public/private subnets across 3 AZs
- **IAM Roles** for EKS, ALB Controller, and service accounts
- **ECR Repository** for container images
- **CloudWatch** for logging and monitoring
- **Route53** for DNS management (production)
- **ACM** for SSL/TLS certificates

### Production Cluster Specifications
```yaml
# EKS Cluster Configuration
kubernetes_version: "1.28"
node_groups:
  - name: "system"
    instance_types: ["t3.medium"]
    min_size: 2
    max_size: 4
    desired_size: 3
  - name: "applications"
    instance_types: ["t3.large"]
    min_size: 3
    max_size: 10
    desired_size: 5
storage:
  ebs_csi_driver: enabled
  storage_classes: ["gp3", "io1"]
```

## 🏗️ DevOps Architecture

### Infrastructure Stack
```yaml
# DevOps Technology Stack
Cloud Provider: AWS
Container Orchestration: Amazon EKS
Service Mesh: AWS Load Balancer Controller + Istio (optional)
Container Registry: Amazon ECR
Secrets Management: AWS Secrets Manager + External Secrets Operator
Monitoring: Prometheus + Grafana + CloudWatch
Logging: Fluent Bit + CloudWatch Logs
Security: Pod Security Standards + OPA Gatekeeper
CI/CD: GitHub Actions + ArgoCD
Infrastructure as Code: Terraform + Helm
```

### DevOps Pipeline Components
| Component | Technology | Purpose |
|-----------|------------|----------|
| **Source Control** | Git + GitHub | Code versioning and collaboration |
| **CI/CD** | GitHub Actions | Automated build, test, deploy |
| **Image Registry** | Amazon ECR | Container image storage |
| **Infrastructure** | Terraform + Helm | Infrastructure as Code |
| **Configuration** | ConfigMaps + Secrets | Environment configuration |
| **Service Discovery** | Kubernetes DNS | Internal service communication |
| **Load Balancing** | AWS ALB + Ingress | Traffic distribution |
| **Autoscaling** | HPA + VPA + CA | Resource optimization |
| **Monitoring** | Prometheus + Grafana | Metrics and alerting |
| **Logging** | Fluent Bit + CloudWatch | Centralized logging |
| **Security** | RBAC + PSS + Network Policies | Security controls |

### Network Architecture
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Internet      │────│  AWS ALB         │────│  EKS Cluster    │
│   Gateway       │    │  (Public Subnet) │    │ (Private Subnet)│
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │                         │
                              ▼                         ▼
                       ┌──────────────┐         ┌──────────────┐
                       │   Route53    │         │ Microservices│
                       │   (DNS)      │         │   Pods       │
                       └──────────────┘         └──────────────┘
```

## 📜 Infrastructure as Code

### Terraform Infrastructure
```hcl
# terraform/main.tf
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  
  cluster_name    = "microservices-cluster"
  cluster_version = "1.28"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  node_groups = {
    system = {
      desired_capacity = 3
      max_capacity     = 5
      min_capacity     = 2
      instance_types   = ["t3.medium"]
    }
    applications = {
      desired_capacity = 5
      max_capacity     = 10
      min_capacity     = 3
      instance_types   = ["t3.large"]
    }
  }
}
```

### Helm Chart Structure
```
microservices-helm-chart/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration
├── values-prod.yaml        # Production overrides
├── values-staging.yaml     # Staging overrides
└── templates/
    ├── configmap.yaml      # Application configuration
    ├── secrets.yaml        # Sensitive data
    ├── deployments/        # Service deployments
    ├── services/           # Service definitions
    ├── ingress.yaml        # Traffic routing
    └── hpa.yaml            # Autoscaling policies
```

## 🔄 CI/CD Pipeline Setup

### GitHub Secrets Configuration

Before using the CI/CD pipeline, configure these secrets in your GitHub repository:

**Repository Settings → Secrets and variables → Actions:**

```bash
# AWS Credentials
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# AWS Configuration
AWS_REGION=us-east-1
EKS_CLUSTER_NAME=amazon-eks-cluster
```

### Pipeline Permissions

The workflow requires these permissions:
- `contents: read` - Read repository code
- `packages: write` - Push to GitHub Container Registry
- `security-events: write` - Upload security scan results
- `id-token: write` - OIDC authentication
- `actions: read` - Workflow metadata access

### Container Images

Images are automatically pushed to:
```
ghcr.io/your-username/microservices-SERVICE:COMMIT_SHA
ghcr.io/your-username/microservices-SERVICE:latest
```

### Production CI/CD Pipeline

The repository includes a complete GitHub Actions workflow that:

**Build Phase:**
- Matrix builds all 12 microservices in parallel
- Uses GitHub Container Registry (GHCR) for image storage
- Handles special cases (cartservice Dockerfile location)

**Security Phase:**
- Trivy vulnerability scanning for all images
- SARIF upload to GitHub Security tab
- Continues deployment even with security findings

**Deploy Phase:**
- Automated deployment to EKS using Helm
- Updates image tags dynamically
- Waits for deployment completion
- Runs smoke tests for health verification

**Failure Handling:**
- Automatic rollback on deployment failure
- Notification system for team alerts
- Comprehensive logging for debugging

**Trigger Conditions:**
- Push to `main` branch (full pipeline)
- Push to `develop` branch (build and scan only)
- Pull requests (build and scan only)
- Manual workflow dispatch

### GitOps with ArgoCD
```yaml
# argocd/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: microservices
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/microservices-k8s-deployment
    targetRevision: HEAD
    path: microservices-helm-chart
    helm:
      valueFiles:
      - values-prod.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: microservices
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

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