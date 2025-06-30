# Immich Sealed - Complete Project Analysis & Learning Guide

## 📋 Overview

This document provides a comprehensive analysis of every file in the Immich Sealed project to help you understand Kubernetes, Kustomize, GitOps, and DevOps best practices. Each file is explained with its purpose, key concepts, and learning objectives.

**Project Summary**: A production-ready Kubernetes deployment for Immich (self-hosted photo management) using Kustomize for configuration management, with multi-environment support, monitoring integration, and GitOps compatibility.

---

## 🏗️ Project Architecture

### Core Technologies
- **Kubernetes**: Container orchestration platform
- **Kustomize**: Native Kubernetes configuration management
- **Immich**: Self-hosted photo and video management application
- **PostgreSQL + pgvector**: Database with vector search capabilities
- **Redis**: In-memory caching and session storage
- **Sealed Secrets**: Encrypted secret management for GitOps
- **Prometheus/Grafana**: Monitoring and observability stack
- **ArgoCD**: GitOps continuous deployment

### Deployment Patterns
- **Base + Overlays**: Kustomize pattern for environment-specific configurations
- **Multi-Environment**: Development, Production, and Monitoring variations
- **GitOps Ready**: Version-controlled infrastructure with ArgoCD integration
- **Security First**: Encrypted secrets, resource limits, security contexts

---

## 📁 Detailed File Analysis

### 🚀 Deployment Scripts

#### `deploy.sh` - Automated Deployment Script
```bash
#!/bin/bash
# Immich Sealed Deployment Script
```

**Purpose**: Intelligent deployment automation with environment detection and validation.

**Key Learning Concepts**:
- **Environment Detection**: Automatically detects monitoring capabilities (Prometheus Operator CRDs)
- **Namespace Management**: Dynamic namespace assignment based on environment
- **Error Handling**: Comprehensive validation and user feedback
- **Shell Scripting Best Practices**: `set -e` for error handling, parameter validation

**Code Breakdown**:
```bash
# Check for monitoring CRDs
check_monitoring_crds() {
    if kubectl get crd servicemonitors.monitoring.coreos.com >/dev/null 2>&1; then
        return 0  # Monitoring available
    else
        return 1  # No monitoring
    fi
}
```

**Learning Objectives**:
- Understand Kubernetes CRD (Custom Resource Definition) detection
- Learn shell function patterns for reusable code
- Practice conditional deployment logic
- Master kubectl command patterns

#### `validate.sh` - Configuration Validation Script
```bash
#!/bin/bash
# Kustomization Validation Script
```

**Purpose**: Pre-deployment validation of all Kustomize configurations.

**Key Learning Concepts**:
- **Dry-run Validation**: Using `kubectl kustomize` to validate without applying
- **Error Propagation**: Proper exit codes and error handling
- **Resource Counting**: Parsing YAML to count Kubernetes resources

**Code Example**:
```bash
# Test base kustomization
if kubectl kustomize base > /dev/null 2>&1; then
    echo "✅ Base kustomization is valid"
else
    echo "❌ Base kustomization has errors"
    kubectl kustomize base  # Show errors
    exit 1
fi
```

**Learning Objectives**:
- Learn validation patterns for infrastructure code
- Understand Kustomize build process
- Practice error handling in automation scripts

---

### 📦 Base Configuration (`base/`)

#### `base/kustomization.yaml` - Base Kustomize Configuration
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
```

**Purpose**: Defines the foundational Kubernetes resources and common configurations.

**Key Learning Concepts**:
- **Resource Ordering**: Dependencies between resources (secrets → PVCs → deployments)
- **Common Labels**: Applied to all resources for consistent labeling
- **Image Management**: Centralized image version control
- **Namespace Management**: Default namespace assignment

**Critical Sections**:
```yaml
resources:
  - immich-postgresql-secret.yaml  # Secrets first
  - immich-pvcs.yaml              # Storage next
  - immich-server.yaml            # Applications last

labels:
  - pairs:
      app.kubernetes.io/name: immich
      app.kubernetes.io/instance: immich-sealed
```

**Learning Objectives**:
- Understand Kustomize resource management
- Learn Kubernetes labeling conventions
- Practice dependency ordering in manifests

#### `base/immich-server.yaml` - Main Application Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
```

**Purpose**: Defines the core Immich application deployment with proper configuration.

**Key Learning Concepts**:
- **Init Containers**: Setup tasks before main container starts
- **Volume Mounts**: Persistent storage attachment
- **Environment Variables**: Application configuration
- **Resource Limits**: CPU and memory constraints
- **Health Checks**: Liveness and readiness probes

**Critical Sections**:
```yaml
initContainers:
- name: init-upload-dirs
  image: busybox:1.35
  command: ['sh', '-c']
  args:
  - |
    mkdir -p /upload/library
    mkdir -p /upload/upload
```

**Learning Objectives**:
- Master Kubernetes Deployment patterns
- Understand container lifecycle management
- Learn volume mounting and persistent storage
- Practice environment variable configuration

#### `base/immich-postgresql-pgvector.yaml` - Database StatefulSet
```yaml
apiVersion: apps/v1
kind: StatefulSet
```

**Purpose**: PostgreSQL database with pgvector extension for vector similarity search.

**Key Learning Concepts**:
- **StatefulSet vs Deployment**: When to use each for stateful applications
- **Persistent Volume Claims**: Storage templates for StatefulSets
- **Database Initialization**: Custom scripts and configuration
- **Service Exposure**: Headless services for StatefulSets

**Critical Sections**:
```yaml
spec:
  serviceName: immich-postgresql-pgvector
  replicas: 1
  volumeClaimTemplates:
  - metadata:
      name: postgresql-data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 20Gi
```

**Learning Objectives**:
- Understand StatefulSet use cases and patterns
- Learn database deployment in Kubernetes
- Practice persistent storage configuration
- Master service discovery patterns

#### `base/immich-redis.yaml` - Redis Cache Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
```

**Purpose**: Redis instance for caching and session management.

**Key Learning Concepts**:
- **Stateless Caching**: Redis as ephemeral cache vs persistent storage
- **Service Configuration**: ClusterIP for internal communication
- **Resource Optimization**: Memory-focused resource allocation

#### `base/immich-pvcs.yaml` - Persistent Volume Claims
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
```

**Purpose**: Storage definitions for application data.

**Key Learning Concepts**:
- **Storage Classes**: Dynamic provisioning configuration
- **Access Modes**: ReadWriteOnce vs ReadWriteMany
- **Storage Sizing**: Capacity planning for different environments

#### `base/immich-postgresql-secret.yaml` - Sealed Secret
```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
```

**Purpose**: Encrypted secret management compatible with GitOps workflows.

**Key Learning Concepts**:
- **GitOps Security**: Storing encrypted secrets in version control
- **Sealed Secrets Controller**: Runtime decryption mechanism
- **Secret References**: How applications consume secrets

**Learning Objectives**:
- Understand GitOps-compatible secret management
- Learn encryption at rest for sensitive data
- Practice secure Kubernetes deployments

#### `base/immich-nodeport-service.yaml` & `base/immich-loadbalancer-service.yaml`
```yaml
apiVersion: v1
kind: Service
```

**Purpose**: External access configuration for different environments.

**Key Learning Concepts**:
- **Service Types**: NodePort vs LoadBalancer vs ClusterIP
- **Port Configuration**: Target ports and service ports
- **External Access Patterns**: When to use each service type

#### `base/immich-nginx-proxy.yaml` - Reverse Proxy
```yaml
apiVersion: apps/v1
kind: Deployment
```

**Purpose**: NGINX reverse proxy for HTTPS termination and SSL offloading.

**Key Learning Concepts**:
- **Reverse Proxy Patterns**: SSL termination and request routing
- **ConfigMap Configuration**: Externalizing NGINX configuration
- **Multi-container Pods**: Sidecar patterns

---

### 🔧 Environment Overlays (`overlays/`)

#### `overlays/development/kustomization.yaml` - Development Environment
```yaml
namespace: immich-dev
```

**Purpose**: Development-specific configurations with reduced resources.

**Key Learning Concepts**:
- **Environment Isolation**: Separate namespaces for environments
- **Resource Scaling**: Reduced CPU/memory for development
- **Configuration Overrides**: Environment-specific settings

**Critical Patches**:
```yaml
patches:
  - target:
      kind: StatefulSet
      name: immich-postgresql-pgvector
    patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/resources
        value:
          requests:
            memory: "256Mi"
            cpu: "100m"
```

**Learning Objectives**:
- Master Kustomize patch patterns
- Understand resource optimization for development
- Learn environment-specific configuration management

#### `overlays/production/kustomization.yaml` - Production Environment
```yaml
commonAnnotations:
  backup.kubernetes.io/enabled: "true"
```

**Purpose**: Production-hardened configuration with full resources and backup annotations.

**Key Learning Concepts**:
- **Production Hardening**: Resource limits, backup annotations, monitoring
- **High Availability**: Production-grade resource allocation
- **Operational Readiness**: Backup and recovery preparation

#### `overlays/production-no-monitoring/kustomization.yaml` - Production without Monitoring
**Purpose**: Production deployment for environments without Prometheus Operator.

**Key Learning Concepts**:
- **Conditional Features**: Deploying subsets based on cluster capabilities
- **Monitoring Dependencies**: Understanding when monitoring can/cannot be deployed

#### `overlays/monitoring/` - Enhanced Monitoring Configuration

##### `overlays/monitoring/immich-monitoring.yaml` - ServiceMonitor
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
```

**Purpose**: Prometheus metrics collection configuration.

**Key Learning Concepts**:
- **Prometheus Operator CRDs**: ServiceMonitor and PrometheusRule resources
- **Metrics Discovery**: How Prometheus finds and scrapes targets
- **Label Selectors**: Target selection patterns

##### `overlays/monitoring/immich-alerts.yaml` - PrometheusRule
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
```

**Purpose**: Pre-configured alerting rules for operational monitoring.

**Key Learning Concepts**:
- **Alert Definitions**: PromQL queries for alert conditions
- **Alert Severity**: Critical vs warning alert classification
- **Runbook Integration**: Documentation links in alerts

##### `overlays/monitoring/README.md` - Monitoring Documentation
**Purpose**: Comprehensive guide for monitoring setup and configuration.

**Key Learning Concepts**:
- **Documentation Best Practices**: Clear setup instructions and troubleshooting
- **Monitoring Stack Integration**: Working with existing Prometheus/Grafana installations

---

### 🔄 GitOps Configuration (`argocd/`)

#### `argocd/app-of-apps.yaml` - Root ArgoCD Application
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
```

**Purpose**: ArgoCD app-of-apps pattern for managing multiple applications.

**Key Learning Concepts**:
- **App-of-Apps Pattern**: Hierarchical application management
- **GitOps Workflow**: Declarative application deployment
- **Sync Policies**: Automatic vs manual synchronization

#### `argocd/projects/immich-project.yaml` - ArgoCD Project
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
```

**Purpose**: RBAC and security boundaries for Immich applications.

**Key Learning Concepts**:
- **Project-based RBAC**: Access control and resource restrictions
- **Source Repositories**: Allowed Git repositories
- **Destination Clusters**: Target cluster restrictions

#### `argocd/applications/` - Individual Applications
**Purpose**: ArgoCD application definitions for each environment.

**Key Learning Concepts**:
- **Environment Management**: Separate applications per environment
- **Sync Strategies**: Different deployment approaches per environment
- **Health Checks**: Application health assessment

---

### 🔍 CI/CD Pipeline (`.github/workflows/`)

#### `.github/workflows/ci.yaml` - Main CI/CD Pipeline
```yaml
name: CI/CD Pipeline
```

**Purpose**: Comprehensive automation for validation, testing, security, and deployment.

**Key Learning Concepts**:
- **Multi-Job Workflows**: Parallel and sequential job execution
- **Matrix Testing**: Testing multiple environments simultaneously
- **Artifact Management**: Generating and storing deployment artifacts
- **Security Integration**: Automated security scanning

**Job Breakdown**:

##### Job 1: `validate-manifests` - Configuration Validation
```yaml
- name: Run validation script
  run: ./validate.sh
```

**Learning Objectives**:
- Automated validation patterns
- Kustomize build verification
- Error detection and reporting

##### Job 2: `test-environments` - Environment Testing
```yaml
strategy:
  matrix:
    environment: [development, production, production-no-monitoring, monitoring]
```

**Learning Objectives**:
- Matrix testing strategies
- Environment-specific validation
- Resource counting and verification

##### Job 3: `security-compliance` - Security Scanning
```yaml
- name: Run basic security scan
  run: |
    trivy fs --security-checks secret --format json
```

**Learning Objectives**:
- Automated security scanning
- Secret detection and prevention
- Security best practices validation

##### Job 4: `generate-artifacts` - Deployment Artifact Generation
```yaml
- name: Generate deployment manifests
```

**Learning Objectives**:
- Artifact generation patterns
- Deployment automation
- Release management

#### `.github/workflows/security.yaml` - Dedicated Security Pipeline
```yaml
name: Security Scan
```

**Purpose**: Comprehensive security analysis with multiple tools and checks.

**Key Learning Concepts**:
- **SARIF Integration**: Security findings uploaded to GitHub Security tab
- **Multiple Security Tools**: Trivy for vulnerabilities and secrets
- **Kubernetes Security Scanning**: Configuration analysis for security issues
- **Best Practices Validation**: Automated security policy checking

**Security Checks**:
- Vulnerability scanning with Trivy
- Secret detection and classification
- Kubernetes misconfigurations
- Security best practices validation
- SARIF reporting integration

#### `.trivyignore` - Security Scan Exclusions
```bash
# GitHub Actions workflow files containing security scanning commands
.github/workflows/ci.yaml
```

**Purpose**: Exclude false positives from security scans.

**Key Learning Concepts**:
- **False Positive Management**: Excluding legitimate patterns
- **Security Tool Configuration**: Customizing scan behavior
- **Documentation Exclusions**: Preventing docs from triggering alerts

---

### 📚 Documentation Files

#### `README.md` - Main Project Documentation
**Purpose**: Comprehensive project documentation with deployment guides.

**Key Sections**:
- **Features Overview**: Project capabilities and benefits
- **Quick Start Guides**: Multiple deployment options
- **Configuration Details**: Environment-specific settings
- **Troubleshooting**: Common issues and solutions
- **Security Guidelines**: Best practices and requirements

#### `VALIDATION_REPORT.md` - Validation Results
**Purpose**: Automated validation report showing configuration health.

#### `netskope-interview-study-guide.md` - Additional Learning Material
**Purpose**: Extended learning content for DevOps and Kubernetes concepts.

---

## 🎯 Key Learning Concepts by Technology

### Kubernetes Fundamentals
1. **Resource Types**: Deployments, StatefulSets, Services, PVCs, Secrets
2. **Namespaces**: Environment isolation and resource organization
3. **Labels and Selectors**: Resource identification and grouping
4. **Resource Management**: CPU/memory limits and requests
5. **Storage**: Persistent volumes and storage classes
6. **Networking**: Services, ingress, and network policies
7. **Security**: RBAC, security contexts, pod security standards

### Kustomize Patterns
1. **Base + Overlays**: Code reuse and environment-specific customization
2. **Patches**: JSON patches for configuration modifications
3. **Resource Ordering**: Managing dependencies between resources
4. **ConfigMap/Secret Generation**: Dynamic configuration creation
5. **Image Management**: Centralized image version control
6. **Common Labels/Annotations**: Consistent resource tagging

### GitOps Workflows
1. **Infrastructure as Code**: Version-controlled infrastructure
2. **ArgoCD Applications**: Declarative application management
3. **App-of-Apps Pattern**: Hierarchical application organization
4. **Sync Strategies**: Automatic vs manual deployment
5. **RBAC**: Project-based access control
6. **Secret Management**: Sealed Secrets for GitOps compatibility

### DevOps Automation
1. **CI/CD Pipelines**: Multi-stage automation workflows
2. **Matrix Testing**: Parallel environment validation
3. **Security Integration**: Automated security scanning
4. **Artifact Management**: Deployment package generation
5. **Error Handling**: Robust automation with proper error reporting
6. **Documentation**: Automated report generation

### Security Best Practices
1. **Secret Management**: Encryption at rest and in transit
2. **Vulnerability Scanning**: Automated security analysis
3. **Configuration Validation**: Security policy enforcement
4. **RBAC**: Role-based access control
5. **Network Security**: Service mesh and network policies
6. **Compliance**: Security standards and best practices

### Monitoring and Observability
1. **Prometheus Integration**: Metrics collection and alerting
2. **Grafana Dashboards**: Visualization and monitoring
3. **ServiceMonitors**: Automatic target discovery
4. **AlertManager**: Alert routing and notification
5. **Custom Metrics**: Application-specific monitoring
6. **Log Aggregation**: Centralized logging strategies

---

## 🛠️ Hands-on Learning Exercises

### Beginner Level
1. **Deploy Development Environment**: Use the deployment script to set up a dev environment
2. **Modify Resource Limits**: Change CPU/memory allocations in overlays
3. **Add New Environment**: Create a staging overlay with custom settings
4. **Validate Configurations**: Run validation scripts and understand output

### Intermediate Level
1. **Customize Monitoring**: Add custom metrics and alerts
2. **Implement Network Policies**: Add network security controls
3. **Configure Storage Classes**: Use specific storage for different environments
4. **Set Up GitOps**: Deploy using ArgoCD and app-of-apps pattern

### Advanced Level
1. **Multi-Cluster Deployment**: Deploy across multiple Kubernetes clusters
2. **Advanced Security**: Implement admission controllers and security policies
3. **Custom Operators**: Create custom resources for application management
4. **Disaster Recovery**: Implement backup and recovery procedures

---

## 🔍 Troubleshooting Common Issues

### Deployment Issues
- **Resource Conflicts**: Namespace and resource name collisions
- **Storage Problems**: PVC provisioning and storage class issues
- **Secret Decryption**: Sealed Secrets controller problems
- **Image Pull Errors**: Registry access and authentication issues

### Monitoring Issues
- **CRD Dependencies**: Prometheus Operator installation requirements
- **Service Discovery**: ServiceMonitor label selector configuration
- **Metrics Endpoints**: Application metrics exposure
- **Alert Configuration**: PrometheusRule syntax and testing

### Security Issues
- **Secret Exposure**: Accidental secret commits
- **RBAC Problems**: Permission and access control issues
- **Network Policies**: Service communication restrictions
- **Vulnerability Management**: Security scan false positives

---

## 📈 Best Practices Learned

### Configuration Management
- Use base + overlays for environment variations
- Implement proper resource ordering and dependencies
- Apply consistent labeling and annotation strategies
- Validate configurations before deployment

### Security
- Encrypt all secrets at rest and in transit
- Implement least-privilege access controls
- Regularly scan for vulnerabilities and misconfigurations
- Use network policies for micro-segmentation

### Operations
- Implement comprehensive monitoring and alerting
- Automate deployment and validation processes
- Maintain clear documentation and runbooks
- Plan for disaster recovery and backup scenarios

### Development
- Use GitOps for version-controlled infrastructure
- Implement automated testing and validation
- Follow infrastructure as code principles
- Maintain environment parity where possible

---

## 🎓 Next Steps for Learning

1. **Advanced Kubernetes**: Study CRDs, operators, and advanced scheduling
2. **Service Mesh**: Implement Istio or Linkerd for advanced networking
3. **Advanced Monitoring**: Custom Prometheus exporters and complex alerting
4. **Multi-Cloud**: Deploy across different cloud providers
5. **Security Hardening**: Implement Pod Security Standards and admission controllers
6. **Performance Optimization**: Cluster autoscaling and resource optimization

---

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kustomize Reference](https://kubectl.docs.kubernetes.io/references/kustomize/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Prometheus Operator Guide](https://prometheus-operator.dev/)
- [Sealed Secrets Documentation](https://sealed-secrets.netlify.app/)
- [Security Best Practices](https://kubernetes.io/docs/concepts/security/)

This comprehensive analysis demonstrates a production-ready Kubernetes deployment with modern DevOps practices, providing an excellent foundation for learning cloud-native technologies and GitOps workflows.
