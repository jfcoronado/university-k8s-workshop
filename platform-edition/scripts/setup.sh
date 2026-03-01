#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

log() { printf '[INFO] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; }
err() { printf '[ERROR] %s\n' "$1"; exit 1; }

command -v docker >/dev/null 2>&1 || err "docker not found"
command -v kind >/dev/null 2>&1 || err "kind not found"
command -v kubectl >/dev/null 2>&1 || err "kubectl not found"
command -v helm >/dev/null 2>&1 || err "helm not found"
docker info >/dev/null 2>&1 || err "docker daemon is not running"

log "Using repo root: $ROOT_DIR"

log "Pulling base images"
docker pull kindest/node:v1.29.0
docker pull traefik:v3.0

if kind get clusters 2>/dev/null | grep -q '^workshop$'; then
  warn "cluster 'workshop' already exists; skipping create"
else
  log "Creating kind cluster"
  kind create cluster --name workshop --config "$ROOT_DIR/manifests/kind-config.yaml"
fi

kubectl config use-context kind-workshop >/dev/null
kubectl wait --for=condition=Ready node --all --timeout=180s >/dev/null

log "Installing traefik"
helm repo add traefik https://traefik.github.io/charts --force-update >/dev/null
helm repo update >/dev/null
kind load docker-image traefik:v3.0 --name workshop
helm upgrade --install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --values "$ROOT_DIR/manifests/traefik-values.yaml" \
  --wait

log "Building workshop app image"
docker build -t k8s-workshop-demo:1.0.0 "$ROOT_DIR/app"
kind load docker-image k8s-workshop-demo:1.0.0 --name workshop

log "Applying manifests"
kubectl apply -f "$ROOT_DIR/manifests/namespace.yaml"
kubectl apply -f "$ROOT_DIR/manifests/configmap.yaml"
kubectl apply -f "$ROOT_DIR/manifests/secret.yaml"
kubectl apply -f "$ROOT_DIR/manifests/deployment.yaml"
kubectl apply -f "$ROOT_DIR/manifests/service.yaml"
kubectl apply -f "$ROOT_DIR/manifests/ingress.yaml"
kubectl rollout status deployment/demo-app -n workshop-app --timeout=180s

if [[ "$OSTYPE" == darwin* || "$OSTYPE" == linux* ]]; then
  if grep -q 'demo.local' /etc/hosts 2>/dev/null; then
    warn "demo.local already exists in /etc/hosts"
  else
    log "Adding demo.local to /etc/hosts"
    echo '127.0.0.1 demo.local' | sudo tee -a /etc/hosts >/dev/null
  fi
else
  warn "Non-Unix shell detected; run setup.ps1 to manage Windows hosts file"
fi

printf '\nSetup complete. Open http://demo.local\n'
