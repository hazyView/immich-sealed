#!/bin/bash

# Immich Sealed Deployment Script
# This script helps deploy Immich using Kustomize with different environments

set -e

ENVIRONMENT=${1:-production}
NAMESPACE="immich"

echo "🚀 Deploying Immich with Kustomize"
echo "Environment: $ENVIRONMENT"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(development|production|base)$ ]]; then
    echo "❌ Invalid environment. Use: development, production, or base"
    exit 1
fi

# Set namespace based on environment
if [ "$ENVIRONMENT" = "development" ]; then
    NAMESPACE="immich-dev"
fi

echo "Namespace: $NAMESPACE"

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
        echo "🏭 Deploying Production Environment..."
        kubectl apply -k overlays/production
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
