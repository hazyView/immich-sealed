#!/bin/bash

# Immich Sealed Deployment Script
# This script helps deploy Immich using Kustomize with different environments

set -e

ENVIRONMENT=${1:-production}
NAMESPACE="immich"

echo "🚀 Deploying Immich with Kustomize"
echo "Environment: $ENVIRONMENT"

# Check for monitoring CRDs
check_monitoring_crds() {
    if kubectl get crd servicemonitors.monitoring.coreos.com >/dev/null 2>&1 && \
       kubectl get crd prometheusrules.monitoring.coreos.com >/dev/null 2>&1; then
        echo "✅ Prometheus Operator CRDs found - monitoring enabled"
        return 0
    else
        echo "⚠️  Prometheus Operator CRDs not found - monitoring disabled"
        echo "   Install Prometheus Operator to enable monitoring features"
        return 1
    fi
}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(development|production|production-no-monitoring|base|monitoring)$ ]]; then
    echo "❌ Invalid environment. Use: development, production, production-no-monitoring, base, or monitoring"
    exit 1
fi

# Set namespace based on environment
if [ "$ENVIRONMENT" = "development" ]; then
    NAMESPACE="immich-dev"
fi

echo "Namespace: $NAMESPACE"

# Check monitoring capabilities
MONITORING_AVAILABLE=false
if check_monitoring_crds; then
    MONITORING_AVAILABLE=true
fi

# Create namespace if it doesn't exist
echo "📦 Creating namespace if not exists..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Deploy based on environment
case $ENVIRONMENT in
    "development")
        echo "🔧 Deploying Development Environment..."
        kubectl apply -k overlays/development
        ;;
    "production")
        if [ "$MONITORING_AVAILABLE" = true ]; then
            echo "🏭 Deploying Production Environment (with monitoring)..."
            kubectl apply -k overlays/production
        else
            echo "🏭 Deploying Production Environment (without monitoring)..."
            kubectl apply -k overlays/production-no-monitoring
        fi
        ;;
    "production-no-monitoring")
        echo "🏭 Deploying Production Environment (monitoring disabled)..."
        kubectl apply -k overlays/production-no-monitoring
        ;;
    "monitoring")
        if [ "$MONITORING_AVAILABLE" = true ]; then
            echo "📊 Deploying with Enhanced Monitoring..."
            kubectl apply -k overlays/monitoring
        else
            echo "❌ Cannot deploy monitoring overlay - Prometheus Operator CRDs not found"
            echo "   Install Prometheus Operator first, then try again"
            exit 1
        fi
        ;;
    "base")
        echo "🏗️  Deploying Base Configuration..."
        kubectl apply -k base
        ;;
esac

echo "✅ Deployment completed!"
echo ""
echo "📋 Check status with:"
echo "   kubectl get pods -n $NAMESPACE"
echo "   kubectl get svc -n $NAMESPACE"
echo ""
echo "🌐 Access Immich:"
if [ "$ENVIRONMENT" = "development" ]; then
    echo "   kubectl port-forward -n $NAMESPACE svc/immich-server 3001:3001"
else
    echo "   kubectl port-forward -n $NAMESPACE svc/immich-server 3001:3001"
    echo "   or use the LoadBalancer/NodePort services"
fi
