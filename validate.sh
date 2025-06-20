#!/bin/bash

# Kustomization Validation Script
# This script validates the kustomization structure

set -e

echo "🔍 Validating Kustomization Structure..."
echo ""

# Test base kustomization
echo "📦 Testing base kustomization..."
if kubectl kustomize base > /dev/null 2>&1; then
    echo "✅ Base kustomization is valid"
else
    echo "❌ Base kustomization has errors"
    kubectl kustomize base
    exit 1
fi

# Test development overlay
echo "🔧 Testing development overlay..."
if kubectl kustomize overlays/development > /dev/null 2>&1; then
    echo "✅ Development overlay is valid"
else
    echo "❌ Development overlay has errors"
    kubectl kustomize overlays/development
    exit 1
fi

# Test production overlay
echo "🏭 Testing production overlay..."
if kubectl kustomize overlays/production > /dev/null 2>&1; then
    echo "✅ Production overlay is valid"
else
    echo "❌ Production overlay has errors"
    kubectl kustomize overlays/production
    exit 1
fi

# Test production-no-monitoring overlay
echo "🏭 Testing production-no-monitoring overlay..."
if kubectl kustomize overlays/production-no-monitoring > /dev/null 2>&1; then
    echo "✅ Production-no-monitoring overlay is valid"
else
    echo "❌ Production-no-monitoring overlay has errors"
    kubectl kustomize overlays/production-no-monitoring
    exit 1
fi

# Test root kustomization
echo "🌟 Testing root kustomization..."
if kubectl kustomize . > /dev/null 2>&1; then
    echo "✅ Root kustomization is valid"
else
    echo "❌ Root kustomization has errors"
    kubectl kustomize .
    exit 1
fi

echo ""
echo "🎉 All kustomizations are valid!"
echo ""
echo "📋 Resource counts:"
echo "   Base resources: $(kubectl kustomize base | grep '^kind:' | wc -l | tr -d ' ')"
echo "   Development resources: $(kubectl kustomize overlays/development | grep '^kind:' | wc -l | tr -d ' ')"
echo "   Production resources: $(kubectl kustomize overlays/production | grep '^kind:' | wc -l | tr -d ' ')"
echo "   Production (no monitoring): $(kubectl kustomize overlays/production-no-monitoring | grep '^kind:' | wc -l | tr -d ' ')"
echo ""
echo "✨ Ready for deployment!"
