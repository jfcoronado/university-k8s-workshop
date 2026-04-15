# Module 5 — Services: Internal Networking

> ⏱️ **Time:** 20 minutes | 🎯 **Goal:** Expose your app with a stable internal network address and test it

---

## Why Do We Need Services?

Pods are **ephemeral** — they come and go. When a Pod is replaced, it gets a **new IP address**.

**Problem:** If another service was talking directly to `10.244.0.5`, that connection breaks when the Pod restarts.

**Solution:** A **Service** gives a set of Pods a **stable, permanent address** (DNS name + ClusterIP) that never changes, even as Pods come and go.

```
Before Service:                    After Service:

Client → Pod IP (changes!)         Client → Service (stable!)
                                              │
                                              ├── Pod 1 (10.244.0.5)
                                              ├── Pod 2 (10.244.0.6)
                                              └── Pod 3 (10.244.0.7)

                                   Service load-balances across healthy Pods
```

---

## Service Types

| Type | Reachable From | Use Case |
|------|----------------|---------|
| **ClusterIP** | Inside cluster only | Default. Microservice-to-microservice |
| **NodePort** | Outside via Node IP + port (30000-32767) | Dev/test access |
| **LoadBalancer** | Outside via cloud load balancer | Production on AWS/GCP/Azure |
| **ExternalName** | Maps to external DNS | Proxy to external services |

> 💡 For our workshop, we use **ClusterIP** (internal) + **Ingress** (external routing). This is the recommended production pattern.

---

## How Services Find Pods: Label Selectors

Services use **label selectors** to find their target Pods. The Service doesn't care about Pod names or IPs — only labels.

```yaml
# Service selector
selector:
  app: demo-app      # ← Route to any Pod with this label

# Pod template label (must match!)
labels:
  app: demo-app      # ← This pod will receive traffic
```

---

## Step 1: Review the Service YAML

```bash
cat manifests/service.yaml
```

```yaml
# manifests/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-app-svc          # Stable DNS name: demo-app-svc.workshop-app.svc.cluster.local
  namespace: workshop-app
  labels:
    app: demo-app
spec:
  selector:
    app: demo-app              # Routes to all Pods with label app=demo-app
  ports:
    - name: http
      protocol: TCP
      port: 80                 # Port the Service listens on (inside the cluster)
      targetPort: 3000         # Port the Node.js app listens on inside the Pod
  type: ClusterIP
```

---

## Step 2: Apply the Service

```bash
kubectl apply -f manifests/service.yaml
```

---

## Step 3: Verify the Service

```bash
kubectl get services -n workshop-app
# or shorthand
kubectl get svc -n workshop-app
```

Expected output:
```
NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
demo-app-svc   ClusterIP   10.96.145.23   <none>        80/TCP    15s
```

```bash
# Detailed view — shows selector, endpoints
kubectl describe svc demo-app-svc -n workshop-app
```

Look for the **Endpoints** line — it shows which Pod IPs are currently receiving traffic:
```
Endpoints: 10.244.0.5:3000, 10.244.0.6:3000
```

---

## Step 4: Inspect Endpoints

Endpoints are automatically created and updated by the Service to track healthy Pod IPs:

```bash
kubectl get endpoints demo-app-svc -n workshop-app
```

> 💡 If a Pod fails its readiness probe, it's **removed from the Endpoints** — no more traffic is sent to it. This is how Kubernetes ensures you only route to healthy pods.

---

## Step 5: Test the Service with Port-Forward

ClusterIP is only reachable inside the cluster. We use `port-forward` to tunnel to it temporarily:

```bash
kubectl port-forward svc/demo-app-svc 8080:80 -n workshop-app
```

> ⚠️ **Keep this terminal open!** Port-forward only works while the command is actively running. The moment you hit Ctrl+C, the tunnel closes.

Now open http://localhost:8080 in your browser. You should see the workshop app!

Press `Ctrl+C` when done.

> `port-forward` is a debugging tool only — it's not how production traffic flows. That's what Ingress is for (Module 6).

---

## Step 6: DNS Inside the Cluster

### Why DNS Matters

Think about a real application — a frontend that talks to a backend API, which talks to a database. How does the frontend know where to find the backend?

Without DNS it would hardcode an IP like `10.244.0.5`. But pod IPs change every time a pod is replaced. Hardcoding IPs would break constantly.

**Kubernetes DNS solves this.** Every Service automatically gets a stable DNS name. Your frontend calls `http://backend-svc` and CoreDNS resolves that to the correct Service IP, which load-balances to a healthy pod — no matter how many times those pods have been replaced.

```
Your App Pod
    │
    │  http://demo-app-svc   ← stable name, never changes
    ▼
CoreDNS (built-in K8s DNS server)
    │
    │  resolves to 10.96.145.23  (Service ClusterIP)
    ▼
Service: demo-app-svc
    │
    ├── Pod 10.244.0.5:3000
    └── Pod 10.244.0.6:3000
```

### The DNS Name Format

Every Service gets a DNS name in this format:
```
<service-name>.<namespace>.svc.cluster.local
```

For our service:
```
demo-app-svc.workshop-app.svc.cluster.local
```

Within the same namespace you can use just the service name:
```
demo-app-svc
```

### Test It

We'll exec into an already-running pod to test DNS — no extra image pull needed since `wget` is already available in our Node Alpine image.

**Step 1 — get a running pod name:**
```bash
kubectl get pods -n workshop-app
```

**Step 2 — test the full DNS name:**
```bash
kubectl exec -it <pod-name> -n workshop-app -- \
  wget -qO- http://demo-app-svc.workshop-app.svc.cluster.local | head -5
```

**Step 3 — test the shorthand (same namespace shortcut):**
```bash
kubectl exec -it <pod-name> -n workshop-app -- \
  wget -qO- http://demo-app-svc | head -5
```

Both return the same HTML. Kubernetes automatically appends `.workshop-app.svc.cluster.local` when pods are in the same namespace.

**Step 4 — hit the health endpoint to confirm the full chain:**
```bash
kubectl exec -it <pod-name> -n workshop-app -- \
  wget -qO- http://demo-app-svc/health
```

Expected output:
```json
{"status":"ok","pod":"demo-app-7d9f8b6c4-abc12","uptime":"5m 30s"}
```

### What You Just Proved

- `demo-app-svc` resolved to the Service ClusterIP via CoreDNS ✅
- The Service load-balanced the request to one of your pods ✅
- The pod responded through the Service, not by direct IP ✅

This is exactly how microservices communicate inside a real Kubernetes cluster.

---

## 🧪 Lab: Watch Endpoints Update

Open two terminal windows side by side.

**Terminal 1 — start watching first:**
```bash
kubectl get endpoints demo-app-svc -n workshop-app -w
```

You'll see:
```
NAME           ENDPOINTS                           AGE
demo-app-svc   10.244.0.5:3000,10.244.0.6:3000    5m
```

**Terminal 2 — delete a pod:**
```bash
# Get a pod name
kubectl get pods -n workshop-app

# Delete it
kubectl delete pod <pod-name> -n workshop-app
```

Watch Terminal 1 — you'll see the deleted pod's IP vanish instantly, then a new IP appear within seconds as Kubernetes creates a replacement:

```
NAME           ENDPOINTS                           AGE
demo-app-svc   10.244.0.5:3000,10.244.0.6:3000    5m
demo-app-svc   10.244.0.5:3000                     5m   ← pod gone
demo-app-svc   10.244.0.5:3000,10.244.0.7:3000    5m   ← new pod registered
```

The Service endpoint list updates automatically. Your DNS name `demo-app-svc` always pointed at healthy pods the entire time — this is why Services exist.

---

**➡️ Next:** [Module 6 — Ingress](../06-ingress/README.md)
