# Troubleshooting Guide

## 🚨 Common Issues and Solutions

### 1. Environment Variable Issues

#### Problem: `SHOPPING_ASSISTANT_SERVICE_ADDR not set`
```bash
# Symptoms
panic: environment variable "SHOPPING_ASSISTANT_SERVICE_ADDR" not set
```

#### Solution
```bash
# Check ConfigMap
kubectl get configmap microservices-config -n microservices -o yaml | grep SHOPPING

# Fix: Set to "disabled" instead of empty string
kubectl patch configmap microservices-config -n microservices \
  --type merge -p '{"data":{"SHOPPING_ASSISTANT_SERVICE_ADDR":"disabled"}}'

# Restart affected pods
kubectl rollout restart deployment/frontend -n microservices
```

### 2. AWS Load Balancer Controller Issues

#### Problem: Webhook failures
```bash
# Symptoms
failed calling webhook "mservice.elbv2.k8s.aws": no endpoints available
```

#### Solution
```bash
# Check controller pods
kubectl get pods -n kube-system | grep aws-load-balancer

# Check service account
kubectl describe serviceaccount aws-load-balancer-controller -n kube-system

# Recreate with proper IAM
eksctl create iamserviceaccount \
  --cluster=amazon-eks-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --override-existing-serviceaccounts
```

#### Problem: EC2 metadata timeout
```bash
# Symptoms
failed to introspect region from EC2Metadata
```

#### Solution
```bash
# Reinstall with region and VPC ID
helm uninstall aws-load-balancer-controller -n kube-system

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=amazon-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-east-1 \
  --set vpcId=vpc-YOUR_VPC_ID
```

### 3. Ingress Issues

#### Problem: Ingress not getting ADDRESS
```bash
# Check Ingress status
kubectl describe ingress microservices-ingress -n microservices

# Check controller logs
kubectl logs deployment/aws-load-balancer-controller -n kube-system

# Common fixes:
# 1. Missing IAM permissions
# 2. Incorrect VPC ID
# 3. Missing subnet tags
```

#### Problem: NGINX webhook conflicts
```bash
# Symptoms
failed calling webhook "validate.nginx.ingress.kubernetes.io"

# Solution
kubectl delete validatingwebhookconfiguration ingress-nginx-admission
```

### 4. Resource Constraints

#### Problem: Too many pods
```bash
# Symptoms
0/3 nodes are available: 3 Too many pods

# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Solutions:
# 1. Scale down non-essential workloads
kubectl scale deployment DEPLOYMENT_NAME --replicas=1 -n NAMESPACE

# 2. Add more nodes
eksctl scale nodegroup --cluster=amazon-eks-cluster --name=worker-nodes --nodes=5

# 3. Use smaller resource requests
```

### 5. Service Discovery Issues

#### Problem: Services can't reach each other
```bash
# Check service endpoints
kubectl get endpoints -n microservices

# Test connectivity
kubectl run debug-pod --image=busybox -it --rm -- /bin/sh
# Inside pod:
nslookup SERVICE_NAME.microservices.svc.cluster.local
wget -qO- http://SERVICE_NAME:PORT/health
```

### 6. Image Pull Issues

#### Problem: ImagePullBackOff
```bash
# Check image availability
kubectl describe pod POD_NAME -n microservices

# Solutions:
# 1. Verify image exists
docker pull IMAGE_NAME:TAG

# 2. Add imagePullPolicy
imagePullPolicy: IfNotPresent

# 3. Use correct registry
imageRegistry: matthewntsiful  # or your registry
```

### 7. Monitoring Issues

#### Problem: Grafana LoadBalancer not accessible
```bash
# Check service status
kubectl get svc grafana -n monitoring
kubectl describe svc grafana -n monitoring

# Use port-forwarding as alternative
kubectl port-forward svc/grafana 3000:80 -n monitoring
```

## 🔍 Debugging Commands

### Pod Debugging
```bash
# Get pod status
kubectl get pods -n microservices

# Describe pod for events
kubectl describe pod POD_NAME -n microservices

# Get pod logs
kubectl logs POD_NAME -n microservices
kubectl logs POD_NAME -n microservices --previous

# Execute into pod
kubectl exec -it POD_NAME -n microservices -- /bin/sh

# Check pod resources
kubectl top pod POD_NAME -n microservices
```

### Service Debugging
```bash
# Check service configuration
kubectl get svc -n microservices
kubectl describe svc SERVICE_NAME -n microservices

# Check endpoints
kubectl get endpoints SERVICE_NAME -n microservices

# Test service connectivity
kubectl run test-pod --image=busybox -it --rm -- /bin/sh
```

### Ingress Debugging
```bash
# Check Ingress status
kubectl get ingress -n microservices
kubectl describe ingress INGRESS_NAME -n microservices

# Check Ingress controller
kubectl get pods -n kube-system | grep ingress
kubectl logs deployment/aws-load-balancer-controller -n kube-system
```

### ConfigMap/Secret Debugging
```bash
# Check ConfigMap
kubectl get configmap microservices-config -n microservices -o yaml

# Check Secret
kubectl get secret microservices-secrets -n microservices -o yaml

# Decode secret values
kubectl get secret SECRET_NAME -n microservices -o jsonpath="{.data.KEY}" | base64 --decode
```

## 🛠️ Useful Scripts

### Quick Health Check
```bash
#!/bin/bash
echo "=== Cluster Status ==="
kubectl get nodes

echo "=== Pod Status ==="
kubectl get pods -n microservices

echo "=== Service Status ==="
kubectl get svc -n microservices

echo "=== Ingress Status ==="
kubectl get ingress -n microservices

echo "=== HPA Status ==="
kubectl get hpa -n microservices
```

### Resource Usage Check
```bash
#!/bin/bash
echo "=== Node Resources ==="
kubectl top nodes

echo "=== Pod Resources ==="
kubectl top pods -n microservices

echo "=== Resource Quotas ==="
kubectl describe quota -n microservices
```

### Log Collection
```bash
#!/bin/bash
mkdir -p logs
for pod in $(kubectl get pods -n microservices -o name); do
    kubectl logs $pod -n microservices > logs/${pod#pod/}.log
done
```

## 📞 Getting Help

### Check Documentation
- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug-application-cluster/)
- [AWS EKS Troubleshooting](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html)
- [Helm Troubleshooting](https://helm.sh/docs/faq/)

### Community Resources
- [Kubernetes Slack](https://kubernetes.slack.com/)
- [AWS EKS Forum](https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/kubernetes)

### Collect Information for Support
```bash
# Cluster information
kubectl cluster-info
kubectl version

# Node information
kubectl get nodes -o wide
kubectl describe nodes

# Pod information
kubectl get pods -n microservices -o wide
kubectl describe pods -n microservices

# Events
kubectl get events -n microservices --sort-by='.lastTimestamp'
```