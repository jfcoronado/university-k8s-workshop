#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# teardown.sh — Removes all workshop resources
# Usage: bash scripts/teardown.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success(){ echo -e "${GREEN}[OK]${NC} $1"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo ""
echo "╔═══════════════════════════════════════════════════╗"
echo "║    ☸  Kubernetes Workshop — Teardown              ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""

# ── 1. Delete KIND cluster ────────────────────────────────────────────────────
if kind get clusters 2>/dev/null | grep -q "^workshop$"; then
  log "Deleting KIND cluster 'workshop'..."
  kind delete cluster --name workshop
  success "Cluster deleted"
else
  warn "Cluster 'workshop' not found — skipping"
fi

# ── 2. Remove /etc/hosts entry ────────────────────────────────────────────────
if grep -q "demo.local" /etc/hosts 2>/dev/null; then
  log "Removing demo.local from /etc/hosts..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sudo sed -i '' '/demo.local/d' /etc/hosts
  else
    sudo sed -i '/demo.local/d' /etc/hosts
  fi
  success "Removed demo.local from /etc/hosts"
else
  warn "demo.local not in /etc/hosts — skipping"
fi

echo ""
success "Teardown complete! Your system is clean."
echo ""
