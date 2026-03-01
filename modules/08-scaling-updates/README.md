# Module 8 — Scaling & Rolling Updates

> ⏱️ **Time:** 20 minutes | 🎯 **Goal:** Scale your app, perform a zero-downtime rolling update, and roll back

---

## Scaling in Kubernetes

Kubernetes supports two types of scaling:

| Type | How | When |
|------|-----|------|
| **Horizontal Scaling** | Add more Pods | Stateless apps, handle more traffic |
| **Vertical Scaling** | Give each Pod more CPU/RAM | Single-threaded apps, database pods |

For web applications, **horizontal scaling** is always the right approach.

---

## Manual Horizontal Scaling

### Scale Up

```bash
# Scale to 5 replicas
kubectl scale deployment demo-app --replicas=5 -n workshop-app

# Watch pods appear
kubectl get pods -n workshop-app -w
```

Now open http://demo.local and refresh several times — you'll see **5 different pod names** cycling through in the hero card. Each pod's request counter will increment independently.

### Scale Down

```bash
kubectl scale deployment demo-app --replicas=2 -n workshop-app
```

---

## Horizontal Pod Autoscaler (HPA)

In production, you don't manually scale — you let Kubernetes do it based on metrics.

```yaml
# manifests/hpa.yaml (review only — requires metrics-server)
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: demo-app-hpa
  namespace: workshop-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: demo-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70    # Scale up when avg CPU > 70%
```

> ⚠️ HPA requires metrics-server. We review the YAML but won't apply it today.

---

## Rolling Updates: Zero-Downtime Deployments

A **rolling update** replaces Pods one at a time, ensuring some are always available.

```
Before update: [v1.0.0] [v1.0.0] [v1.0.0] [v1.0.0]

Step 1:        [v1.0.0] [v1.0.0] [v1.0.0] [v2.0.0]   ← 1 new pod created
Step 2:        [v1.0.0] [v1.0.0] [v2.0.0] [v2.0.0]   ← 1 old pod removed
Step 3:        [v1.0.0] [v2.0.0] [v2.0.0] [v2.0.0]
Step 4:        [v2.0.0] [v2.0.0] [v2.0.0] [v2.0.0]   ← complete!
```

### Rolling Update Strategy (already in our deployment.yaml)

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1         # Create 1 extra Pod before removing an old one
      maxUnavailable: 0   # Never go below desired replica count (zero-downtime)
```

---

## Step 1: Build v2.0.0 of the App

For the rolling update demo, we'll build a v2 image with a small change. Open `app/Dockerfile` and change the `APP_VERSION` env var line:

```dockerfile
# Change this line:
ENV APP_VERSION=1.0.0
# To:
ENV APP_VERSION=2.0.0
```

Then build and load it:

```bash
docker build -t k8s-workshop-demo:2.0.0 ./app
kind load docker-image k8s-workshop-demo:2.0.0 --name workshop
```

---

## Step 2: Perform the Rolling Update

```bash
# Terminal 1: Watch pods update in real time
kubectl get pods -n workshop-app -w

# Terminal 2: Trigger the rolling update
kubectl set image deployment/demo-app \
  demo-app=k8s-workshop-demo:2.0.0 \
  -n workshop-app
```

Watch Terminal 1 — new `v2.0.0` pods come up **before** old `v1.0.0` pods are terminated. Keep http://demo.local open — the version badge in the top-right corner will flip from `v1.0.0` to `v2.0.0` as your requests hit updated pods.

---

## Step 3: Check Rollout Status

```bash
kubectl rollout status deployment/demo-app -n workshop-app
# Waiting for deployment "demo-app" rollout to finish...
# deployment "demo-app" successfully rolled out
```

---

## Step 4: View Rollout History

```bash
kubectl rollout history deployment/demo-app -n workshop-app
```

Add a change-cause annotation for better history tracking:
```bash
kubectl annotate deployment demo-app \
  kubernetes.io/change-cause="Upgraded app to v2.0.0" \
  -n workshop-app
```

---

## Step 5: Roll Back!

Something went wrong? Roll back instantly to the previous version:

```bash
# Roll back to previous revision
kubectl rollout undo deployment/demo-app -n workshop-app

# Or roll back to a specific revision number
kubectl rollout undo deployment/demo-app --to-revision=1 -n workshop-app

# Watch the rollback
kubectl rollout status deployment/demo-app -n workshop-app
```

Open http://demo.local — the version badge flips back to `v1.0.0`. That's the power of rollbacks.

---

## Step 6: The GitOps Way (Better Than kubectl set image)

In production, update the image tag in your YAML file and apply it:

```bash
# Edit manifests/deployment.yaml — change:
#   image: k8s-workshop-demo:1.0.0
# To:
#   image: k8s-workshop-demo:2.0.0

kubectl apply -f manifests/deployment.yaml
```

This is better because:
- ✅ The change is in version control (git history = audit log)
- ✅ Reviewable via Pull Request before it hits the cluster
- ✅ Rollback = `git revert` + `kubectl apply`

---

## 🧪 Lab: Simulate a Bad Deploy

```bash
# 1. Deploy a broken image (non-existent tag)
kubectl set image deployment/demo-app \
  demo-app=k8s-workshop-demo:this-tag-does-not-exist \
  -n workshop-app

# 2. Watch what happens
kubectl get pods -n workshop-app -w
# You'll see: ErrImagePull → ImagePullBackOff
# Old pods stay running! The rolling update STOPS because new pods can't start.

# 3. Check rollout status
kubectl rollout status deployment/demo-app -n workshop-app --timeout=30s

# 4. Roll back to fix it instantly
kubectl rollout undo deployment/demo-app -n workshop-app

# 5. Confirm everything is healthy
kubectl get pods -n workshop-app
```

> 💡 This is why `maxUnavailable: 0` matters — the old pods kept running the whole time, so your users never saw an outage.

---

## kubectl Rollout Cheat Sheet

```bash
kubectl scale deployment demo-app --replicas=N -n workshop-app
kubectl rollout status deployment/demo-app -n workshop-app
kubectl rollout history deployment/demo-app -n workshop-app
kubectl rollout undo deployment/demo-app -n workshop-app
kubectl rollout undo deployment/demo-app --to-revision=1 -n workshop-app
kubectl rollout pause deployment/demo-app -n workshop-app
kubectl rollout resume deployment/demo-app -n workshop-app
kubectl rollout restart deployment/demo-app -n workshop-app  # Force pod replacement (useful after config changes)
```

---

**➡️ Next:** [Module 9 — Bonus: Troubleshooting & Tips](../09-bonus/README.md)
