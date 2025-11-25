#!/usr/bin/env bash
set -euo pipefail

# --- Detect if Fish shell was used to launch ---
if [ -n "${FISH_VERSION:-}" ]; then
  echo "🐟 Detected Fish shell. Re-running under Bash..."
  exec bash "$0" "$@"
fi

# ----------------------------------------------------------------------------
# Install Kubernetes Gateway API
# ----------------------------------------------------------------------------

echo "🚀 Installing Kubernetes Gateway API (CRDs + Standard controller)..."

# Step 1: install Gateway API CRDs
echo "📦 Applying official Gateway API CRDs..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml

# Optional: wait until CRDs are registered
echo "⏳ Waiting for CRDs to be established..."
kubectl wait --for=condition=Established crd/gateways.gateway.networking.k8s.io --timeout=60s

# Step 3: confirm installation
echo "✅ Gateway API CRDs installed:"
kubectl get crds | grep gateway.networking.k8s.io || true

echo "🎉 Gateway API successfully installed on Minikube."

# ----------------------------------------------------------------------------
# Install KGateway as dataplane for Gateway API
# ----------------------------------------------------------------------------

NAMESPACE="kgateway-system"
VERSION="v2.1.1"

echo "🚀 Installing KGateway (CRDs + Control Plane)..."

# Ensure Helm is ready for OCI registries
echo "📦 Enabling Helm OCI support..."
export HELM_EXPERIMENTAL_OCI=1

# Create namespace if missing
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Step 1: Install CRDs
echo "📦 Installing KGateway CRDs ($VERSION)..."
helm upgrade -i kgateway-crds \
  oci://cr.kgateway.dev/kgateway-dev/charts/kgateway-crds \
  --version "$VERSION" \
  --create-namespace \
  --namespace "$NAMESPACE"

# Step 2: Install Control Plane
echo "⚙️ Installing KGateway Control Plane ($VERSION)..."
helm upgrade -i kgateway \
  oci://cr.kgateway.dev/kgateway-dev/charts/kgateway \
  --version "$VERSION" \
  --namespace "$NAMESPACE" \
  --set controller.image.pullPolicy=Always

# Step 3: Wait for deployment
echo "⏳ Waiting for KGateway pods to be ready..."
kubectl rollout status deployment/kgateway -n "$NAMESPACE" --timeout=180s

echo "✅ KGateway successfully installed!"
kubectl get pods -n "$NAMESPACE"
