#!/usr/bin/env bash
# verify.sh — Checks that the workshop environment is healthy
# Usage: bash scripts/verify.sh

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
PASS=0; FAIL=0

check() {
  local desc="$1"; local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} $desc"
    ((PASS++))
  else
    echo -e "${RED}✗${NC} $desc"
    ((FAIL++))
  fi
}

echo ""
echo "═══════════════════════════════════════"
echo "   ☸  Workshop Environment Check"
echo "═══════════════════════════════════════"
echo ""

echo "── Tools ──────────────────────────────"
check "docker installed"              "command -v docker"
check "docker running"                "docker info"
check "kind installed"                "command -v kind"
check "kubectl installed"             "command -v kubectl"
check "helm installed"                "command -v helm"

echo ""
echo "── Cluster ────────────────────────────"
check "KIND cluster 'workshop' exists"   "kind get clusters | grep -q workshop"
check "kubectl context is kind-workshop" "kubectl config current-context | grep -q kind-workshop"
check "Node is Ready"                    "kubectl get nodes | grep -q Ready"

echo ""
echo "── Traefik Ingress Controller ─────────"
check "traefik namespace exists"         "kubectl get ns traefik"
check "Traefik pod running"              "kubectl get pods -n traefik | grep -q Running"

echo ""
echo "── Application ────────────────────────"
check "workshop-app namespace exists"    "kubectl get ns workshop-app"
check "ConfigMap exists"                 "kubectl get configmap demo-app-config -n workshop-app"
check "Secret exists"                    "kubectl get secret demo-app-secret -n workshop-app"
check "Deployment exists"                "kubectl get deployment demo-app -n workshop-app"
check "Pods are Running"                 "kubectl get pods -n workshop-app | grep -q Running"
check "Service exists"                   "kubectl get svc demo-app-svc -n workshop-app"
check "Ingress exists"                   "kubectl get ingress demo-app-ingress -n workshop-app"

echo ""
echo "── Network ─────────────────────────────"
check "demo.local in /etc/hosts"         "grep -q demo.local /etc/hosts"
check "App responds at demo.local"       "curl -sf http://demo.local/health"

echo ""
echo "═══════════════════════════════════════"
if [ $FAIL -eq 0 ]; then
  echo -e "${GREEN}All $PASS checks passed! ✅${NC}"
  echo "Open http://demo.local in your browser"
else
  echo -e "${RED}$FAIL check(s) failed${NC} | ${GREEN}$PASS passed${NC}"
  echo -e "${YELLOW}Run 'bash scripts/setup.sh' to fix the environment${NC}"
fi
echo "═══════════════════════════════════════"
echo ""
