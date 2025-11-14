#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="argocd"
RELEASE_NAME="argocd"
HELM_REPO="argo/argo-cd"
HELM_REPO_URL="https://argoproj.github.io/argo-helm"
HELM_VERSION="7.6.3"

echo "📁 Ensuring namespace 'argocd' exists..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "🗑️ Removing old TLS secret if present..."
kubectl -n argocd delete secret gateway-tls --ignore-not-found
kubectl -n argocd delete secret argocd-server-tls --ignore-not-found
kubectl -n argocd delete configmap argocd-ca --ignore-not-found

echo "🔐 Creating new TLS secret"
kubectl -n argocd create secret tls gateway-tls \
  --cert=certs/gateway.crt --key=certs/gateway.key
kubectl -n argocd create secret tls argocd-server-tls \
  --cert=certs/argocd.crt --key=certs/argocd.key
kubectl -n argocd create configmap argocd-ca \
  --from-file=ca.crt=certs/rootCA.crt

echo "✅ Certificate chain ready."

echo "📦 Adding Argo Helm repository..."
helm repo add argo "$HELM_REPO_URL"

echo "🔄 Updating Helm repositories..."
helm repo update

echo "🚀 Installing or upgrading Argo CD (release: $RELEASE_NAME)..."
helm upgrade --install "$RELEASE_NAME" "$HELM_REPO" \
  --namespace "$NAMESPACE" \
  --version "$HELM_VERSION" \
  --set server.service.type=ClusterIP \
  --set server.service.servicePort=443 \
  --wait

echo "🎉 Argo CD installed."
