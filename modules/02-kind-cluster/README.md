# Module 2 — Creating Your KIND Cluster

> ⏱️ **Time:** 20 minutes | 🎯 **Goal:** Create and verify a local Kubernetes cluster with Ingress support

---

## What is KIND?

**KIND = Kubernetes IN Docker**

KIND runs a complete Kubernetes cluster using Docker containers as "nodes". Each Docker container acts like a real server — it runs kubelet, the container runtime, and all the Kubernetes components.

```
Your Laptop
└── Docker
    └── Docker Container (acts as a K8s Node)
        ├── kubelet
        ├── containerd
        └── Your Pods
```

This is perfect for learning — it's free, runs locally, and is **identical** to real Kubernetes.

---

## Step 1: Review the KIND Config

We need a custom config file to enable Ingress (external traffic routing). This file is already in the repo:

```bash
cat manifests/kind-config.yaml
```

```yaml
# manifests/kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
```

### What does this config do?

| Setting | Purpose |
|---------|---------|
| `role: control-plane` | This node is both control plane AND worker (fine for learning) |
| `node-labels: ingress-ready=true` | Marks the node so the Ingress controller can be scheduled on it |
| `extraPortMappings` | Forwards ports 80/443 from your laptop → inside the cluster |

---

## Step 2: Create the Cluster

```bash
kind create cluster --name workshop --config manifests/kind-config.yaml
```

Expected output (takes 1-3 minutes):
```
Creating cluster "workshop" ...
 ✓ Ensuring node image (kindest/node:v1.29.0) 🖼
 ✓ Preparing nodes 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-workshop"
Have a nice day! 👋
```

---

## Step 3: Verify the Cluster

```bash
# Confirm kubectl is pointed at your new cluster
kubectl cluster-info --context kind-workshop

# Check nodes
kubectl get nodes

# Expected:
# NAME                     STATUS   ROLES           AGE   VERSION
# workshop-control-plane   Ready    control-plane   2m    v1.29.0
```

---

## Step 4: Explore the Cluster

```bash
# See all system pods running in the cluster
kubectl get pods --all-namespaces

# Equivalent shorthand
kubectl get pods -A

# What namespaces exist by default?
kubectl get namespaces
```

You'll see namespaces like:
- `kube-system` — Kubernetes system components
- `kube-public` — Publicly readable data
- `kube-node-lease` — Node heartbeat data
- `local-path-storage` — KIND's default storage class

---

## Step 5: Understand kubectl Contexts

A **context** is a saved connection to a cluster. You can have multiple clusters and switch between them.

```bash
# See all contexts
kubectl config get-contexts

# See current context
kubectl config current-context

# Switch context (if you had multiple clusters)
kubectl config use-context kind-workshop
```

---

## KIND Cheat Sheet

```bash
# List all KIND clusters
kind get clusters

# Delete the cluster when done
kind delete cluster --name workshop

# Load a local Docker image into KIND
# (needed if you build your own image)
kind load docker-image my-image:tag --name workshop

# Get cluster logs
kind export logs /tmp/kind-logs --name workshop
```

---

## 🧪 Lab: Explore What's Running

Run these and look at the output:

```bash
# What pods run the cluster itself?
kubectl get pods -n kube-system

# What's the API server doing?
kubectl get componentstatuses 2>/dev/null || echo "Use: kubectl get --raw='/readyz?verbose'"

# What resources can Kubernetes manage?
kubectl api-resources | head -30
```

---

**➡️ Next:** [Module 3 — Namespaces](../03-namespaces/README.md)
