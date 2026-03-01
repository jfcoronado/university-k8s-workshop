#!/usr/bin/env bash
set -euo pipefail

log() { printf '[INFO] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; }

if kind get clusters 2>/dev/null | grep -q '^workshop$'; then
  log "Deleting kind cluster 'workshop'"
  kind delete cluster --name workshop
else
  warn "cluster 'workshop' not found"
fi

if [[ "$OSTYPE" == darwin* || "$OSTYPE" == linux* ]]; then
  if grep -q 'demo.local' /etc/hosts 2>/dev/null; then
    log "Removing demo.local from /etc/hosts"
    tmp_file="$(mktemp)"
    grep -v 'demo.local' /etc/hosts > "$tmp_file"
    sudo cp "$tmp_file" /etc/hosts
    rm -f "$tmp_file"
  else
    warn "demo.local not present in /etc/hosts"
  fi
else
  warn "Non-Unix shell detected; run teardown.ps1 for Windows hosts cleanup"
fi

log "Teardown complete"
