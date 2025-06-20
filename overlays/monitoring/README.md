# Immich Monitoring Setup

This directory contains monitoring configurations for Immich that work with existing Prometheus and Grafana installations.

## 🚀 Quick Setup

### Step 1: Install Prometheus Operator (if not already installed)

```bash
# Add Prometheus community helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack (includes Prometheus + Grafana + AlertManager)
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# Wait for deployment
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=300s
```

### Step 2: Deploy Immich with Monitoring

```bash
# Deploy with enhanced monitoring
kubectl apply -k overlays/monitoring
```

### Step 3: Verify Setup

```bash
# Check ServiceMonitors
kubectl get servicemonitor -n immich

# Check PrometheusRules
kubectl get prometheusrule -n immich

# Check metrics endpoints
kubectl get svc -n immich -l app.kubernetes.io/component=metrics

# Test metrics collection
kubectl port-forward svc/immich-server-metrics 3001:3001 -n immich
curl http://localhost:3001/api/server-info/stats
```

## 📊 What's Included

### ServiceMonitors
- **Immich Server**: Scrapes metrics from `/api/server-info/stats`
- **PostgreSQL**: Uses postgres_exporter sidecar for database metrics
- **Redis**: Connects to redis_exporter if available

### PrometheusRules
- **Immich Server Alerts**: Down, high CPU/memory usage
- **PostgreSQL Alerts**: Down, high connections, slow queries
- **Storage Alerts**: Low disk space warnings

### Services
- **Metrics Services**: Separate services for metrics endpoints
- **Monitoring Labels**: Proper labeling for service discovery

## 🚀 Prerequisites

You need an existing monitoring stack with:
- **Prometheus Operator** (for ServiceMonitor and PrometheusRule CRDs)
- **Prometheus** instance configured to discover ServiceMonitors
- **Grafana** (optional, for dashboards)
- **AlertManager** (optional, for alerts)

## 📦 Deployment Options

### Option 1: Include Monitoring in Base Deployment
Monitoring resources are included by default in the base kustomization.

```bash
# Deploy with monitoring enabled
kubectl apply -k overlays/production
```

### Option 2: Monitoring Overlay
Use the dedicated monitoring overlay for enhanced monitoring features:

```bash
# Deploy with enhanced monitoring
kubectl apply -k overlays/monitoring
```

### Option 3: Disable Monitoring
Remove monitoring resources from base kustomization if not needed:

```bash
# Edit base/kustomization.yaml and comment out:
# - immich-monitoring.yaml
# - immich-alerts.yaml
```

## 🔧 Configuration

### ServiceMonitor Labels
Ensure your Prometheus is configured to discover ServiceMonitors with these labels:
```yaml
prometheus:
  serviceMonitorSelector:
    matchLabels:
      prometheus: kube-prometheus
```

### Namespace Monitoring
If your Prometheus is in a different namespace, you may need to configure:
```yaml
prometheus:
  serviceMonitorNamespaceSelector:
    matchLabels:
      name: immich
```

## 📈 Available Metrics

### Immich Server Metrics
- Server status and health
- API response times
- Upload/download statistics
- User activity metrics

### PostgreSQL Metrics
- Connection pool status
- Query performance
- Database size and growth
- Lock statistics
- Replication lag (if applicable)

### Redis Metrics
- Memory usage
- Key statistics
- Command statistics
- Connection metrics

### Kubernetes Metrics
- Pod CPU/Memory usage
- Storage usage
- Network I/O
- Container restart counts

## 🚨 Default Alerts

### Critical Alerts
- **ImmichServerDown**: Server unavailable for 5+ minutes
- **PostgreSQLDown**: Database unavailable for 5+ minutes
- **ImmichStorageSpaceCritical**: >95% storage usage

### Warning Alerts
- **ImmichHighMemoryUsage**: >80% memory usage for 10+ minutes
- **ImmichHighCPUUsage**: >80% CPU usage for 15+ minutes
- **PostgreSQLHighConnections**: >80% connection usage
- **PostgreSQLSlowQueries**: Queries running >5 minutes
- **ImmichStorageSpaceLow**: >90% storage usage

## 📊 Grafana Dashboards

### Recommended Dashboards
1. **Immich Overview**: Server health, user activity, storage usage
2. **PostgreSQL Database**: Performance, connections, queries
3. **Kubernetes Resources**: Pod metrics, storage, networking
4. **Application Performance**: Response times, error rates

### Dashboard Templates
You can find community Grafana dashboards for:
- Node.js applications (for Immich server)
- PostgreSQL databases
- Kubernetes workloads
- Redis instances

## 🔍 Troubleshooting

### ServiceMonitor Not Discovered
1. Check Prometheus ServiceMonitor selector
2. Verify namespace configuration
3. Check RBAC permissions

### No Metrics Available
1. Verify service endpoints are accessible
2. Check if metrics ports are correct
3. Test metrics endpoints manually:
   ```bash
   kubectl port-forward svc/immich-server-metrics 3001:3001
   curl http://localhost:3001/api/server-info/stats
   ```

### PostgreSQL Exporter Issues
1. Check sidecar container logs:
   ```bash
   kubectl logs immich-postgresql-pgvector-0 -c postgres-exporter
   ```
2. Verify database connection string
3. Check PostgreSQL permissions

## 🛠️ Customization

### Adding Custom Metrics
1. Modify ServiceMonitor paths/ports
2. Add custom PrometheusRules
3. Update service selectors

### Different Prometheus Setup
Update ServiceMonitor labels to match your Prometheus configuration:
```yaml
labels:
  prometheus: your-prometheus-name
```

## 📚 External Monitoring Stacks

This configuration works with:
- **kube-prometheus-stack** Helm chart
- **Prometheus Operator** standalone
- **OpenShift monitoring** stack
- **Rancher monitoring** apps

## 🔗 Integration Examples

### With kube-prometheus-stack
```bash
helm install prometheus prometheus-community/kube-prometheus-stack
kubectl apply -k overlays/monitoring
```

### With Existing Prometheus
Just ensure your Prometheus has the correct ServiceMonitor selectors configured.
