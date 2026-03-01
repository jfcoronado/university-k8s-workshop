# Module 3 — Namespaces: Organizing Your Cluster

> ⏱️ **Time:** 10 minutes | 🎯 **Goal:** Understand and create Namespaces to organize resources

---

## What is a Namespace?

A **Namespace** is a virtual cluster inside your Kubernetes cluster. Think of it like a folder — it groups related resources together and provides isolation.

```
cluster
├── namespace: kube-system     (K8s system components)
├── namespace: default         (where things go without a namespace)
├── namespace: workshop-app    ← We'll create this
└── namespace: monitoring      (e.g., Prometheus, Grafana)
```

### Why Use Namespaces?

| Use Case | Example |
|----------|---------|
| **Environment isolation** | `dev`, `staging`, `prod` in one cluster |
| **Team isolation** | `team-frontend`, `team-backend` |
| **App isolation** | `monitoring`, `logging`, `workshop-app` |
| **Resource quotas** | Limit CPU/memory per namespace |
| **RBAC scoping** | Give a team access to only their namespace |

> ⚠️ **Namespaces do NOT provide security isolation** by default — just logical separation. Use Network Policies for traffic isolation.

---

## Step 1: Create a Namespace via kubectl

The fastest way:
```bash
kubectl create namespace workshop-app
```

Verify it exists:
```bash
kubectl get namespaces
# or shorthand
kubectl get ns
```

---

## Step 2: Create a Namespace via YAML (the GitOps way)

Using YAML is better for real projects — it's declarative and version-controlled.

```bash
cat manifests/namespace.yaml
```

```yaml
# manifests/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: workshop-app
  labels:
    environment: workshop
    managed-by: kubectl
```

Delete the previously created namespace and apply using the manifest or you will get a "Warning," which is not a big deal:
```bash
kubectl delete namespace workshop-app
kubectl apply -f manifests/namespace.yaml
```

> 💡 `kubectl apply` is idempotent — running it again won't error if the namespace already exists.

---

## Step 3: Working Within a Namespace

Most kubectl commands need `-n <namespace>` to scope to a namespace:

```bash
# List pods in a specific namespace
kubectl get pods -n workshop-app

# Get ALL resources across ALL namespaces
kubectl get pods --all-namespaces
kubectl get pods -A   # shorthand

# Set a default namespace for your session (optional)
kubectl config set-context --current --namespace=workshop-app
# Now you don't need -n workshop-app on every command
# Reset with:
kubectl config set-context --current --namespace=default
```

---

## Understanding the `default` Namespace

If you don't specify a namespace, commands go to `default`:

```bash
# These are equivalent when current namespace is 'default'
kubectl get pods
kubectl get pods -n default
```

> 🏭 **Best practice:** Never deploy your apps to `default` in production. Always use named namespaces.

---

## Namespace Resource Quotas (Preview)

You can limit resources per namespace. We won't apply this today, but here's what it looks like:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: workshop-quota
  namespace: workshop-app
spec:
  hard:
    pods: "10"
    requests.cpu: "2"
    requests.memory: 2Gi
    limits.cpu: "4"
    limits.memory: 4Gi
```

---

## 🧪 Lab Exercises

```bash
# 1. List all namespaces and notice the age/status
kubectl get namespaces

# 2. Describe the workshop-app namespace
kubectl describe namespace workshop-app

# 3. Try getting pods in workshop-app (should be empty)
kubectl get all -n workshop-app
```

---

**➡️ Next:** [Module 4 — Deployments](../04-deployments/README.md)
