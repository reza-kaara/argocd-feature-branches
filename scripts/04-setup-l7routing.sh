#!/usr/bin/env bash
set -euo pipefail

echo "📡 Applying Gateway API resources..."
kubectl apply -f manifests/gateway.yaml
kubectl apply -f manifests/httproute.yaml
kubectl apply -f manifests/backendtlspolicy.yaml
echo "✅ Gateway applied."

echo "⏳ Waiting for Gateway to be ready..."
while true; do
  if kubectl get pod -n argocd -l gateway.networking.k8s.io/gateway-name=argocd-gateway --no-headers 2>/dev/null | grep -q .; then
    echo "📦 Envoy pod created."
    break
  fi
  sleep 2
done

echo "⏳ Waiting for Envoy pod to be Ready..."
kubectl wait -n argocd \
  --for=condition=Ready \
  pod -l gateway.networking.k8s.io/gateway-name=argocd-gateway \
  --timeout=300s

echo "🎉 Envoy Ready!"
