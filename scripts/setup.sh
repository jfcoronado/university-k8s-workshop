#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# setup.sh — One-command workshop environment setup
# Works on: Intel Mac, Apple Silicon (M1/M2/M3/M4), AMD64/ARM64 Linux, Windows WSL
# Usage: bash scripts/setup.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
log()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
success(){ echo -e "${GREEN}[OK]${NC}    $1"; }
warn()   { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo ""
echo "╔═══════════════════════════════════════════════════╗"
echo "║     ☸  Kubernetes Beginners Workshop — Setup      ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""

# ── 1. Check prerequisites ────────────────────────────────────────────────────
log "Checking prerequisites..."
command -v docker  >/dev/null 2>&1 || error "docker not found — install Docker Desktop first"
command -v kind    >/dev/null 2>&1 || error "kind not found — see modules/00-preflight/README.md"
command -v kubectl >/dev/null 2>&1 || error "kubectl not found — see modules/00-preflight/README.md"
command -v helm    >/dev/null 2>&1 || error "helm not found — run: brew install helm"
docker info >/dev/null 2>&1        || error "Docker daemon is not running — start Docker Desktop"
success "All prerequisites found"

# ── 2. Pre-pull images ────────────────────────────────────────────────────────
log "Pre-pulling images (avoids Wi-Fi issues during the workshop)..."
docker pull kindest/node:v1.29.0
docker pull traefik:v3.0
success "Images ready"

# ── 3. Create KIND cluster ────────────────────────────────────────────────────
log "Creating KIND cluster 'workshop'..."
if kind get clusters 2>/dev/null | grep -q "^workshop$"; then
  warn "Cluster 'workshop' already exists — skipping creation"
else
  kind create cluster --name workshop --config manifests/kind-config.yaml
  success "KIND cluster created"
fi

kubectl config use-context kind-workshop
success "kubectl context → kind-workshop"

log "Waiting for node to be Ready..."
kubectl wait --for=condition=Ready node --all --timeout=120s
success "Node is Ready"

# ── 4. Install Traefik Ingress Controller ──────────────────────────────────────
log "Adding Traefik Helm repo..."
helm repo add traefik https://traefik.github.io/charts
helm repo update

log "Installing Traefik Ingress Controller..."
helm upgrade --install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --set ports.web.nodePort=30080 \
  --set service.type=NodePort \
  --wait
success "Traefik Ingress Controller is running"

# ── 5. Build and load the workshop app ────────────────────────────────────────
log "Building workshop app image..."
docker build -t k8s-workshop-demo:1.0.0 ./app
log "Loading image into KIND..."
kind load docker-image k8s-workshop-demo:1.0.0 --name workshop
success "Workshop app image loaded"

# ── 6. Apply all manifests ────────────────────────────────────────────────────
log "Applying manifests..."
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/configmap.yaml
kubectl apply -f manifests/secret.yaml
kubectl apply -f manifests/deployment.yaml
kubectl apply -f manifests/service.yaml
kubectl apply -f manifests/ingress.yaml

log "Waiting for deployment to be ready..."
kubectl rollout status deployment/demo-app -n workshop-app --timeout=120s
success "Application deployed"

# ── 7. Add /etc/hosts entry ────────────────────────────────────────────────────
if grep -q "demo.local" /etc/hosts 2>/dev/null; then
  warn "demo.local already in /etc/hosts — skipping"
else
  log "Adding demo.local to /etc/hosts (may prompt for sudo)..."
  echo '127.0.0.1 demo.local' | sudo tee -a /etc/hosts >/dev/null
  success "Added demo.local → /etc/hosts"
fi

# ── 8. Done ────────────────────────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════════════╗"
echo "║                  ✅  All Done!                    ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""
success "Open http://demo.local in your browser!"
echo ""
echo "  Cluster:    kind-workshop"
echo "  Namespace:  workshop-app"
echo "  URL:        http://demo.local"
echo ""
