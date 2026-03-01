# Demo App — Build & Run Guide

This is the custom Node.js app used in the SCaLE Kubernetes Workshop.  
It's a single-file server (`server.js`) with **zero npm dependencies** — just Node.js stdlib.

---

## What It Shows

When you open it in the browser you'll see:

- **Pod Name** (hostname) — proves which pod handled your request
- **Pod IP / Node / Namespace** — injected via the Kubernetes Downward API
- **Request Counter** — each pod tracks its own count; refresh to see load balancing in action
- **ConfigMap values** — env vars injected from `demo-app-config`
- **Secret values** — masked, but proves they were injected from `demo-app-secret`
- **Mounted config file** — `/etc/config/app.properties` rendered from the ConfigMap volume

---

## Option A: Use the Pre-Built Image (Easiest)

The manifests reference a pre-built image. If you've pushed it to a registry, attendees can just `kubectl apply` and go.

---

## Option B: Build and Load into KIND (Workshop Demo)

This is the best hands-on option — shows attendees the full Docker → KIND workflow.

```bash
# 1. Build the image
docker build -t k8s-workshop-demo:1.0.0 ./app

# 2. Load it into your KIND cluster (bypasses a registry entirely)
kind load docker-image k8s-workshop-demo:1.0.0 --name workshop

# 3. Update deployment.yaml — change the image line to:
#    image: k8s-workshop-demo:1.0.0
# And add under the image line:
#    imagePullPolicy: Never

# 4. Apply
kubectl apply -f manifests/deployment.yaml
```

---

## Option C: Push to GitHub Container Registry (Production-Like)

```bash
# 1. Login
echo $CR_PAT | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin

# 2. Build and tag
docker build -t ghcr.io/YOUR_GITHUB_USERNAME/k8s-workshop-demo:1.0.0 ./app

# 3. Push
docker push ghcr.io/YOUR_GITHUB_USERNAME/k8s-workshop-demo:1.0.0

# 4. Update image in deployment.yaml and apply
kubectl apply -f manifests/deployment.yaml
```

---

## Run Locally (No Kubernetes)

```bash
cd app
node server.js
# Open http://localhost:3000
```

---

## Endpoints

| Path | Description |
|------|-------------|
| `/` | Main workshop UI |
| `/health` | Health check (used by K8s probes) — returns `{"status":"ok"}` |
| `/api/info` | JSON with pod name, IP, request count, uptime |

---

## Build a v2 for the Rolling Update Demo (Module 8)

```bash
# Change APP_VERSION in the Dockerfile ENV line to 2.0.0
# Then build and load:
docker build -t k8s-workshop-demo:2.0.0 ./app
kind load docker-image k8s-workshop-demo:2.0.0 --name workshop

# Trigger a rolling update:
kubectl set image deployment/demo-app \
  demo-app=k8s-workshop-demo:2.0.0 \
  -n workshop-app

# Watch the rollout:
kubectl rollout status deployment/demo-app -n workshop-app
```
