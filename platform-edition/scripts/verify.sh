#!/usr/bin/env bash
set -u

PASS=0
FAIL=0

check() {
  local desc="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    printf '[PASS] %s\n' "$desc"
    PASS=$((PASS + 1))
  else
    printf '[FAIL] %s\n' "$desc"
    FAIL=$((FAIL + 1))
  fi
}

check "docker installed" "command -v docker"
check "docker running" "docker info"
check "kind installed" "command -v kind"
check "kubectl installed" "command -v kubectl"
check "helm installed" "command -v helm"

check "cluster exists" "kind get clusters | grep -q '^workshop$'"
check "kubectl context" "kubectl config current-context | grep -q '^kind-workshop$'"
check "node ready" "kubectl get nodes --no-headers | grep -q ' Ready '"

check "traefik running" "kubectl get pods -n traefik --no-headers | grep -q Running"
check "demo app running" "kubectl get pods -n workshop-app --no-headers | grep -q Running"
check "ingress exists" "kubectl get ingress demo-app-ingress -n workshop-app"

if [[ "$OSTYPE" == darwin* || "$OSTYPE" == linux* ]]; then
  check "demo.local in /etc/hosts" "grep -q 'demo.local' /etc/hosts"
fi

check "health endpoint responds" "curl -sf http://demo.local/health"

printf '\nChecks: %d passed, %d failed\n' "$PASS" "$FAIL"
if [[ "$FAIL" -ne 0 ]]; then
  exit 1
fi
