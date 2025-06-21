# Immich Sealed - Production-Ready Kubernetes Deployment

[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.20+-blue.svg)](https://kubernetes.io/)
[![Kustomize](https://img.shields.io/badge/Kustomize-3.0+-green.svg)](https://kustomize.io/)
[![Immich](https://img.shields.io/badge/Immich-v1.135.0-purple.svg)](https://immich.app/)

A complete, production-ready Kubernetes deployment for [Immich](https://immich.app/) using Kustomize with multi-environment support, monitoring integration, and GitOps compatibility.

## ✨ Features

- **🚀 Multi-Environment Support**: Development, Production, and Production-no-monitoring overlays
- **🔐 Secure by Default**: SealedSecrets for sensitive data, proper RBAC, resource limits
- **📊 Monitoring Ready**: Prometheus/Grafana integration with pre-built dashboards and alerts
- **� GitOps Compatible**: ArgoCD applications with app-of-apps pattern
- **⚡ Performance Optimized**: Environment-specific resource allocation and caching
- **🛡️ Production Hardened**: Health checks, persistent storage, backup annotations
- **🔧 Easy Deployment**: Automated deployment script with environment detection

## 📁 Project Structure

```
immich-sealed/
├── 📁 base/                           # Base Kubernetes manifests
│   ├── kustomization.yaml            # Base kustomization with common config
│   ├── immich-server.yaml            # Main Immich server deployment + service
│   ├── immich-postgresql-pgvector.yaml # PostgreSQL with pgvector extension
│   ├── immich-redis.yaml             # Native Redis deployment + services
│   ├── immich-pvcs.yaml              # Persistent Volume Claims
│   ├── immich-postgresql-secret.yaml # SealedSecret for PostgreSQL password
│   ├── immich-nodeport-service.yaml  # NodePort service (external access)
│   ├── immich-loadbalancer-service.yaml # LoadBalancer service
│   └── immich-nginx-proxy.yaml       # NGINX reverse proxy with HTTPS
├── 📁 overlays/                       # Environment-specific configurations
│   ├── 🔧 development/               # Development environment
│   │   └── kustomization.yaml        # Dev-specific patches & settings
│   ├── 🏭 production/                # Production environment  
│   │   └── kustomization.yaml        # Production patches & settings
│   ├── 🏭 production-no-monitoring/  # Production without monitoring
│   │   └── kustomization.yaml        # Same as production but no monitoring
│   └── 📊 monitoring/                # Enhanced monitoring overlay
│       ├── kustomization.yaml        # Monitoring-specific config
│       ├── immich-monitoring.yaml    # ServiceMonitor for Prometheus
│       ├── immich-alerts.yaml        # PrometheusRule for alerts
│       ├── postgresql-exporter-patch.yaml # PostgreSQL metrics exporter
│       └── README.md                 # Monitoring setup guide
├── 📁 argocd/                        # GitOps configurations (optional)
│   ├── app-of-apps.yaml             # Root ArgoCD application
│   ├── kustomization.yaml           # ArgoCD manifest aggregation
│   ├── 📁 projects/                 # ArgoCD project definitions
│   │   └── immich-project.yaml      # Immich project with RBAC
│   └── 📁 applications/             # Individual ArgoCD applications
│       ├── immich-production.yaml   # Production environment app
│       ├── immich-development.yaml  # Development environment app
│       └── immich-kustomize.yaml    # Direct kustomize deployment
├── 🚀 deploy.sh                     # Automated deployment script
├── ✅ validate.sh                   # Configuration validation script
├── kustomization.yaml               # Root kustomization (defaults to production-no-monitoring)
└── README.md                        # This documentation
```

## 🚀 Quick Start

### Prerequisites

- Kubernetes cluster (1.20+)
- kubectl configured to access your cluster
- [Kustomize](https://kustomize.io/) (built into kubectl 1.14+)
- [Sealed Secrets Controller](https://sealed-secrets.netlify.app/) (for production deployments)

### Option 1: Automated Deployment (Recommended)

The deployment script automatically detects your environment and monitoring capabilities:

```bash
# Clone the repository
git clone <your-repo-url>
cd immich-sealed

# Make scripts executable
chmod +x deploy.sh validate.sh

# Deploy to production (auto-detects monitoring capabilities)
./deploy.sh production

# Deploy to production without monitoring
./deploy.sh production-no-monitoring

# Deploy to development environment
./deploy.sh development

# Deploy with enhanced monitoring (requires Prometheus Operator)
./deploy.sh monitoring

# Deploy base configuration only
./deploy.sh base
```

### Option 2: Direct Kustomize Deployment

```bash
# Validate configurations first
./validate.sh

# Choose your deployment:

# 🏭 Production (recommended for production workloads)
kubectl apply -k overlays/production

# 🏭 Production without monitoring (if no Prometheus Operator)
kubectl apply -k overlays/production-no-monitoring

# 🔧 Development (reduced resources, debug logging)
kubectl apply -k overlays/development

# 📊 Enhanced monitoring (requires existing monitoring stack)
kubectl apply -k overlays/monitoring

# 🏗️ Base only (minimal deployment)
kubectl apply -k base
```

### Option 3: GitOps with ArgoCD

```bash
# Install ArgoCD first (if not already installed)
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Update repository URL in argocd/app-of-apps.yaml
# Then apply the app-of-apps pattern:
kubectl apply -f argocd/app-of-apps.yaml
```

## ⚙️ Configuration

### Environment-Specific Settings

| Setting | Development | Production | Production-No-Monitoring |
|---------|-------------|------------|---------------------------|
| **Namespace** | `immich-dev` | `immich` | `immich` |
| **PostgreSQL Resources** | 256Mi-1Gi / 100m-500m | 1Gi-4Gi / 500m-2000m | 1Gi-4Gi / 500m-2000m |
| **Library PVC Size** | 10Gi | 100Gi | 100Gi |
| **Uploads PVC Size** | 5Gi | 50Gi | 50Gi |
| **Log Level** | debug | warn | warn |
| **Immich Image Tag** | latest | v1.135.0 | v1.135.0 |
| **Auto Scaling** | Disabled | Available | Available |
| **Backup Annotations** | No | Yes | Yes |
| **Monitoring** | Basic | Full (if CRDs available) | Disabled |

### Core Components Deployed

#### 🔧 Application Stack
- **Immich Server**: Main photo management application (v1.135.0)
- **PostgreSQL + pgvector**: Database with vector similarity search
- **Redis**: Caching and session management
- **NGINX Proxy**: Reverse proxy with HTTPS support

#### 💾 Storage
- **Library PVC**: Immich photo library storage
- **Uploads PVC**: Temporary upload storage  
- **PostgreSQL PVC**: Database persistent storage

#### 🌐 Networking
- **ClusterIP**: Internal service communication
- **NodePort**: External access on port 30001
- **LoadBalancer**: Cloud provider load balancer integration
- **NGINX Proxy**: HTTPS termination and SSL offloading

#### 📊 Monitoring (Optional)
- **ServiceMonitor**: Prometheus metrics collection
- **PrometheusRule**: Pre-configured alerts
- **PostgreSQL Exporter**: Database performance metrics
- **Grafana Integration**: Dashboard discovery annotations

### Customization Options

#### 🎨 Adding New Environments
```bash
# Create new overlay
mkdir -p overlays/staging
cp overlays/production/kustomization.yaml overlays/staging/
# Edit overlays/staging/kustomization.yaml for staging-specific settings
```

#### 🔧 Modifying Base Resources
```bash
# Edit any base resource
vim base/immich-server.yaml
# Changes automatically apply to all overlays
```

#### � Custom Monitoring
```bash
# Add custom metrics
vim overlays/monitoring/immich-monitoring.yaml
# Define custom alerts
vim overlays/monitoring/immich-alerts.yaml
```

## �🔐 Security & Secrets Management

### Sealed Secrets Integration

This deployment uses [Sealed Secrets](https://sealed-secrets.netlify.app/) for secure secret management:

- **PostgreSQL Password**: Encrypted in `base/immich-postgresql-secret.yaml`
- **Runtime Decryption**: Sealed Secrets controller decrypts secrets at runtime
- **Git-Safe**: Encrypted secrets can be safely stored in Git repositories

### Prerequisites for Production

1. **Install Sealed Secrets Controller**:
```bash
# Install the controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Install kubeseal CLI
# macOS
brew install kubeseal
# Linux
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz
```

### Creating New Sealed Secrets

```bash
# Create a regular secret
kubectl create secret generic my-secret \
  --from-literal=password=mysecretpassword \
  --namespace=immich \
  --dry-run=client -o yaml > my-secret.yaml

# Convert to sealed secret
kubeseal -o yaml < my-secret.yaml > my-sealed-secret.yaml

# Clean up temporary file
rm my-secret.yaml
```

### Updating Existing Secrets

```bash
# Update PostgreSQL password
echo -n "newpassword" | kubectl create secret generic immich-postgresql-temp \
  --dry-run=client --from-file=password=/dev/stdin -o yaml | \
  kubeseal -o yaml --merge-into base/immich-postgresql-secret.yaml
```

## 📊 Monitoring & Observability

### Built-in Monitoring Stack

This deployment includes comprehensive monitoring capabilities:

#### 🎯 Metrics Collection
- **Immich Server Metrics**: API performance, user activity, processing queues
- **PostgreSQL Metrics**: Connection pools, query performance, database size
- **Redis Metrics**: Cache hit rates, memory usage, connection stats
- **Kubernetes Metrics**: Pod resources, PVC usage, network traffic

#### 🚨 Pre-configured Alerts
- High memory/CPU usage
- Database connection issues
- Storage space warnings
- Application errors and crashes
- Service availability monitoring

#### 📈 Monitoring Deployment Options

**Option 1: Enhanced Monitoring Overlay**
```bash
# Deploy with full monitoring stack
./deploy.sh monitoring
# or
kubectl apply -k overlays/monitoring
```

**Option 2: Production with Auto-Detection**
```bash
# Automatically includes monitoring if Prometheus Operator is available
./deploy.sh production
```

**Option 3: Production without Monitoring**
```bash
# Explicitly disable monitoring
./deploy.sh production-no-monitoring
```

### Prerequisites for Monitoring

- **Prometheus Operator**: For ServiceMonitor and PrometheusRule CRDs
- **Prometheus**: For metrics collection
- **Grafana**: For dashboards (optional)

```bash
# Quick monitoring stack installation (example)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace
```

### Available Dashboards

The monitoring configuration includes Grafana dashboard discovery annotations:
- **Immich Overview**: Application performance and usage
- **PostgreSQL Performance**: Database metrics and optimization
- **Kubernetes Resources**: Pod and storage monitoring

For detailed monitoring setup, see [`overlays/monitoring/README.md`](overlays/monitoring/README.md).

## 🛠️ Deployment Validation & Troubleshooting

### Pre-deployment Validation

Always validate your configuration before deploying:

```bash
# Validate all overlays
./validate.sh

# Manual validation
kubectl kustomize overlays/production --dry-run
kubectl kustomize overlays/development --dry-run
kubectl kustomize overlays/monitoring --dry-run
```

### Health Checks

```bash
# Check deployment status
kubectl get pods -n immich -w

# Verify services
kubectl get svc -n immich

# Check persistent volumes
kubectl get pvc -n immich

# Validate sealed secrets
kubectl get sealedsecret -n immich
```

### Common Troubleshooting Steps

#### 🔍 Pod Issues
```bash
# Check pod details
kubectl describe pod -n immich <pod-name>

# View logs
kubectl logs -n immich deployment/immich-server -f
kubectl logs -n immich statefulset/immich-postgresql-pgvector -f

# Check resource usage
kubectl top pods -n immich
```

#### 🔗 Service Connectivity
```bash
# Test internal connectivity
kubectl run debug --image=busybox -it --rm -- /bin/sh
# Inside the pod:
# nslookup immich-postgresql-pgvector.immich.svc.cluster.local
# nslookup immich-redis-master.immich.svc.cluster.local

# Check service endpoints
kubectl get endpoints -n immich
```

#### 💾 Storage Issues
```bash
# Check PVC status
kubectl describe pvc -n immich

# Check storage class
kubectl get storageclass

# Monitor disk usage (if metrics available)
kubectl top pvc -n immich
```

#### 🔐 Secret Issues
```bash
# Verify sealed secret controller
kubectl get pods -n kube-system | grep sealed-secrets

# Check secret decryption
kubectl get secret -n immich immich-postgresql-temp -o yaml

# Validate secret content
kubectl get secret -n immich immich-postgresql-temp -o jsonpath='{.data.password}' | base64 -d
```

### Common Issues & Solutions

| Issue | Symptoms | Solution |
|-------|----------|----------|
| **Pods Stuck in Pending** | PVC binding issues | Check storage class and availability |
| **Database Connection Failed** | Immich server crash loops | Verify PostgreSQL pod is running and secret is correct |
| **External Access Issues** | Cannot reach Immich UI | Check NodePort/LoadBalancer service configuration |
| **Sealed Secret Not Decrypting** | Pods can't read secrets | Ensure sealed-secrets controller is running |
| **Monitoring Not Working** | No metrics in Prometheus | Verify Prometheus Operator CRDs are installed |

## 🌐 Accessing Immich

### Development Access (Port Forwarding)
```bash
# Forward to development environment
kubectl port-forward -n immich-dev svc/immich-server 3001:3001

# Forward to production environment
kubectl port-forward -n immich svc/immich-server 3001:3001

# Access at http://localhost:3001
```

### Production Access Options

#### Option 1: NodePort (Recommended for testing)
```bash
# Check NodePort assignment
kubectl get svc immich-server-nodeport -n immich

# Access at http://<any-node-ip>:30001
# Find node IPs:
kubectl get nodes -o wide
```

#### Option 2: LoadBalancer (Cloud environments)
```bash
# Get external IP (may take a few minutes)
kubectl get svc immich-server-loadbalancer -n immich -w

# Access at http://<external-ip>
```

#### Option 3: NGINX Proxy with HTTPS
```bash
# Port forward to NGINX proxy
kubectl port-forward -n immich svc/nginx-proxy 8080:80

# Access at http://localhost:8080
# Configure HTTPS certificates in base/immich-nginx-proxy.yaml
```

### First-time Setup

1. **Access Immich**: Use one of the methods above
2. **Create Admin Account**: Follow the setup wizard
3. **Configure Storage**: Library and uploads are already configured
4. **Upload Photos**: Start using your self-hosted photo management!

## 🔄 Updates & Maintenance

### Updating Immich Version

1. **Update Image Tags**:
```bash
# Edit base/kustomization.yaml
vim base/kustomization.yaml

# Update image version
images:
  - name: ghcr.io/immich-app/immich-server
    newTag: v1.136.0  # New version
```

2. **Apply Updates**:
```bash
# Validate first
./validate.sh

# Apply to production
./deploy.sh production

# Or apply manually
kubectl apply -k overlays/production
```

3. **Monitor Migration**:
```bash
# Watch database migration logs
kubectl logs -n immich deployment/immich-server -f

# Check application status
kubectl get pods -n immich
```

### Scaling Operations

```bash
# Scale PostgreSQL StatefulSet (careful with data)
kubectl scale statefulset immich-postgresql-pgvector -n immich --replicas=1

# Scale Immich server (if needed)
kubectl scale deployment immich-server -n immich --replicas=2

# Scale Redis (standalone mode only supports 1 replica)
kubectl scale deployment immich-redis -n immich --replicas=1
```

### Backup & Recovery

#### Database Backup
```bash
# Create database backup
kubectl exec -n immich statefulset/immich-postgresql-pgvector -- \
  pg_dump -U immich immich > immich-backup-$(date +%Y%m%d).sql
```

#### Storage Backup
```bash
# Backup PVCs (example with Velero)
velero backup create immich-backup --include-namespaces immich

# Or use your preferred backup solution
```

### Performance Tuning

#### PostgreSQL Optimization
```bash
# Edit PostgreSQL configuration
kubectl edit statefulset -n immich immich-postgresql-pgvector

# Common optimizations:
# - shared_buffers = 25% of RAM
# - effective_cache_size = 75% of RAM
# - maintenance_work_mem = 256MB
```

#### Resource Monitoring
```bash
# Monitor resource usage
kubectl top pods -n immich
kubectl top nodes

# Adjust resources in overlays if needed
vim overlays/production/kustomization.yaml
```

## 🚨 Troubleshooting Guide

### Debug Commands Reference

```bash
# Quick health check
./validate.sh && kubectl get pods -n immich

# Detailed pod investigation
kubectl describe pod -n immich <pod-name>
kubectl logs -n immich <pod-name> --previous

# Service connectivity testing
kubectl run debug-pod --image=nicolaka/netshoot -it --rm
# Inside debug pod: nslookup immich-postgresql-pgvector.immich.svc.cluster.local

# Resource usage monitoring
kubectl top pods -n immich --sort-by=memory
kubectl top nodes --sort-by=cpu
```

## 🔄 GitOps Integration

### ArgoCD Configuration

This project includes complete ArgoCD integration with the app-of-apps pattern:

#### Structure
- **App-of-Apps**: `argocd/app-of-apps.yaml` - Root application
- **Project**: `argocd/projects/immich-project.yaml` - RBAC and permissions
- **Applications**: Individual apps for each environment

#### Setup Steps

1. **Update Repository URLs**:
```bash
# Update all ArgoCD applications with your repository URL
find argocd/ -name "*.yaml" -exec sed -i 's|https://github.com/hazyView/immich-sealed|<your-repo-url>|g' {} +
```

2. **Deploy App-of-Apps**:
```bash
kubectl apply -f argocd/app-of-apps.yaml
```

3. **Monitor Deployment**:
```bash
# ArgoCD UI or CLI
argocd app list
argocd app sync immich-production
```

### Available ArgoCD Applications

| Application | Path | Target |
|-------------|------|--------|
| `immich-production` | `overlays/production` | `immich` namespace |
| `immich-development` | `overlays/development` | `immich-dev` namespace |
| `immich-kustomize` | `overlays/production-no-monitoring` | `immich` namespace |

## 📚 Advanced Configuration

### Custom Environment Variables

Add environment-specific variables to your overlays:

```yaml
# overlays/production/kustomization.yaml
configMapGenerator:
  - name: immich-config
    behavior: merge
    literals:
      - CUSTOM_VAR=production-value
      - ANOTHER_VAR=custom-setting
```

### Network Policies

Add network security policies:

```yaml
# overlays/production/network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: immich-network-policy
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: immich
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: nginx-proxy
    ports:
    - protocol: TCP
      port: 2283
```

### Custom Storage Classes

Use specific storage classes for different environments:

```yaml
# overlays/production/kustomization.yaml
patches:
  - target:
      kind: PersistentVolumeClaim
      name: immich-server-library
    patch: |-
      - op: replace
        path: /spec/storageClassName
        value: fast-ssd
```

## 🔍 Monitoring Deep Dive

### Custom Metrics

Add custom Prometheus metrics:

```yaml
# overlays/monitoring/custom-servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: immich-custom-metrics
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: immich
  endpoints:
  - port: metrics
    interval: 30s
    path: /custom-metrics
```

### Alert Customization

Modify alert rules:

```yaml
# overlays/monitoring/custom-alerts.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: immich-custom-alerts
spec:
  groups:
  - name: immich.custom
    rules:
    - alert: ImmichCustomAlert
      expr: custom_metric > 100
      for: 5m
      annotations:
        summary: "Custom Immich alert"
```

## 📋 Production Checklist

Before deploying to production, ensure:

- [ ] **Sealed Secrets Controller** is installed and running
- [ ] **Storage Classes** are configured and available
- [ ] **Backup Strategy** is implemented for PVCs and database
- [ ] **Monitoring Stack** is installed if using monitoring overlay
- [ ] **Resource Limits** are appropriate for your cluster
- [ ] **Network Access** is configured (LoadBalancer/Ingress)
- [ ] **SSL Certificates** are configured for HTTPS
- [ ] **Database Performance** tuning is applied
- [ ] **Security Policies** are in place (RBAC, Network Policies)
- [ ] **Disaster Recovery** plan is documented

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and test thoroughly
4. Validate all overlays: `./validate.sh`
5. Commit your changes: `git commit -m 'Add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Immich Team](https://github.com/immich-app/immich) for the amazing photo management application
- [Kubernetes Community](https://kubernetes.io/) for the container orchestration platform
- [Kustomize](https://kustomize.io/) for the configuration management tool
- [Sealed Secrets](https://sealed-secrets.netlify.app/) for secure secret management
- [Prometheus Operator](https://prometheus-operator.dev/) for monitoring capabilities

## 📚 Additional Resources

- [Immich Documentation](https://immich.app/docs) - Official Immich documentation
- [Kustomize Reference](https://kubectl.docs.kubernetes.io/references/kustomize/) - Kustomize documentation
- [Sealed Secrets Guide](https://sealed-secrets.netlify.app/) - Sealed Secrets documentation
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/) - GitOps with ArgoCD
- [Prometheus Operator](https://prometheus-operator.dev/) - Monitoring setup
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/) - K8s configuration best practices

---

**⭐ If this project helped you, please give it a star!**
