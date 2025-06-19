# Immich Sealed - Kustomize Deployment

This repository provides a complete Kubernetes deployment for Immich using Kustomize and Sealed Secrets.

## 📁 Directory Structure

```
immich-sealed/
├── base/                              # Base Kubernetes manifests
│   ├── kustomization.yaml            # Base kustomization
│   ├── immich-application.yaml       # ArgoCD application (Helm-based)
│   ├── immich-pvcs.yaml              # Persistent Volume Claims
│   ├── immich-postgresql-pgvector.yaml  # PostgreSQL with pgvector
│   ├── immich-redis-app.yaml         # Redis deployment
│   ├── immich-nodeport-service.yaml  # NodePort service
│   ├── immich-loadbalancer-service.yaml # LoadBalancer service
│   └── immich-nginx-proxy.yaml       # NGINX proxy with HTTPS
├── overlays/                          # Environment-specific overlays
│   ├── development/
│   │   └── kustomization.yaml        # Development configuration
│   └── production/
│       └── kustomization.yaml        # Production configuration
├── apps/                              # Helm charts and sealed secrets
│   └── immich/
│       ├── Chart.yaml                # Helm chart definition
│       ├── values.yaml               # Helm values
│       └── sealed-immich-secret-new.yaml  # Sealed secret
├── kustomization.yaml                 # Root kustomization (defaults to production)
├── deploy.sh                          # Deployment script
├── argocd-application-kustomize.yaml  # ArgoCD application for kustomize
└── README.md                          # This file
```

## 🚀 Quick Start

### Option 1: Using the Deployment Script

```bash
# Deploy to production
./deploy.sh production

# Deploy to development
./deploy.sh development

# Deploy base configuration only
./deploy.sh base
```

### Option 2: Using Kustomize Directly

```bash
# Production deployment
kubectl apply -k overlays/production

# Development deployment
kubectl apply -k overlays/development

# Base deployment
kubectl apply -k base
```

### Option 3: Using ArgoCD

```bash
# Apply the ArgoCD application
kubectl apply -f argocd-application-kustomize.yaml
```

## 🔧 Configuration

### Environment Differences

| Component | Development | Production |
|-----------|-------------|------------|
| Namespace | `immich-dev` | `immich` |
| PostgreSQL Memory | 256Mi-1Gi | 1Gi-4Gi |
| PostgreSQL CPU | 100m-500m | 500m-2000m |
| Library PVC | 10Gi | 100Gi |
| Uploads PVC | 5Gi | 50Gi |
| Log Level | debug | warn |
| Image Tag | latest | v1.135.0 |

### Customization

You can customize the deployment by:

1. **Modifying base resources**: Edit files in `base/` directory
2. **Environment-specific patches**: Edit `overlays/{env}/kustomization.yaml`
3. **Adding new environments**: Create new overlay directories

## 🔐 Secrets Management

This setup uses Sealed Secrets for secure secret management:

1. **PostgreSQL Password**: Stored in `apps/immich/sealed-immich-secret-new.yaml`
2. **TLS Certificates**: Managed by the NGINX proxy configuration

### Creating New Sealed Secrets

```bash
# Create a regular secret
kubectl create secret generic my-secret \
  --from-literal=password=mysecretpassword \
  --dry-run=client -o yaml > my-secret.yaml

# Convert to sealed secret
kubeseal -o yaml < my-secret.yaml > my-sealed-secret.yaml
```

## 🛠️ Components Deployed

### Core Services
- **Immich Server**: Main application server
- **Immich Machine Learning**: ML processing service
- **PostgreSQL with pgvector**: Database with vector extension
- **Redis**: Caching and session storage

### Storage
- **Library PVC**: Stores the Immich library
- **Uploads PVC**: Stores uploaded media
- **PostgreSQL PVC**: Database storage (created by StatefulSet)

### Networking
- **ClusterIP Services**: Internal service communication
- **NodePort Service**: External access via node ports
- **LoadBalancer Service**: External access via load balancer
- **NGINX Proxy**: HTTPS termination and reverse proxy

## 📊 Monitoring and Maintenance

### Check Deployment Status

```bash
# Check all pods
kubectl get pods -n immich

# Check services
kubectl get svc -n immich

# Check persistent volumes
kubectl get pvc -n immich

# Check logs
kubectl logs -n immich deployment/immich-server
```

### Scaling

```bash
# Scale PostgreSQL (if needed)
kubectl scale statefulset immich-postgresql-pgvector -n immich --replicas=1

# Note: Immich server scaling is managed by the Helm chart
```

## 🌐 Accessing Immich

### Port Forwarding (Development)
```bash
kubectl port-forward -n immich svc/immich-server 3001:3001
# Access at http://localhost:3001
```

### NodePort (Production)
```bash
# Get the NodePort
kubectl get svc immich-server-nodeport -n immich

# Access at http://<node-ip>:<nodeport>
```

### LoadBalancer (Production)
```bash
# Get the external IP
kubectl get svc immich-server-loadbalancer -n immich

# Access at http://<external-ip>
```

## 🔄 Updates and Maintenance

### Updating Immich Version

1. Update the image tag in `base/kustomization.yaml`:
   ```yaml
   images:
     - name: ghcr.io/immich-app/immich-server
       newTag: v1.136.0  # New version
   ```

2. Apply the changes:
   ```bash
   kubectl apply -k overlays/production
   ```

### Database Migrations

Immich handles database migrations automatically on startup. Monitor the logs:

```bash
kubectl logs -n immich deployment/immich-server -f
```

## 🚨 Troubleshooting

### Common Issues

1. **Pods stuck in Pending**: Check PVC status and storage class
2. **Database connection issues**: Verify PostgreSQL service and secrets
3. **External access problems**: Check services and ingress configuration

### Debug Commands

```bash
# Check pod status
kubectl describe pod -n immich <pod-name>

# Check service endpoints
kubectl get endpoints -n immich

# Check persistent volume claims
kubectl describe pvc -n immich

# Check sealed secrets
kubectl get sealedsecret -n immich
```

## 📚 Additional Resources

- [Immich Documentation](https://immich.app/docs)
- [Kustomize Documentation](https://kustomize.io/)
- [Sealed Secrets Documentation](https://sealed-secrets.netlify.app/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
