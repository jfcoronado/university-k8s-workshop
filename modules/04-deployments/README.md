# Module 4 — Deployments: Running Your App

> ⏱️ **Time:** 25 minutes | 🎯 **Goal:** Build the workshop app, load it into KIND, deploy it, and prove self-healing works

---

## Pods vs Deployments — What's the Difference?

**Pod:** Runs one or more containers. If it crashes, it stays dead.

**Deployment:** A controller that manages Pods. If a Pod crashes, the Deployment creates a new one.

```
Deployment
└── ReplicaSet (manages N identical pods)
    ├── Pod 1  ← app container running here
    ├── Pod 2  ← app container running here
    └── Pod 3  ← app container running here
```

> 🔑 **In practice: never create bare Pods.** Always use a Deployment (or StatefulSet for stateful apps).

---

## Step 1: Build the Workshop App

Our demo app is a Node.js server in the `app/` folder. Let's build it into a Docker image:

```bash
docker build -t k8s-workshop-demo:1.0.0 ./app
```

Verify the image was built:
```bash
docker images | grep k8s-workshop-demo
```

---

## Step 2: Load the Image into KIND

KIND runs Kubernetes inside Docker containers. Those containers can't see images in your local Docker daemon by default — you need to explicitly load them in:

```bash
kind load docker-image k8s-workshop-demo:1.0.0 --name workshop
```

> 💡 This is KIND-specific. In a real cluster on AWS/GCP/Azure, you'd push to a container registry (ECR, GCR, GHCR) and Kubernetes would pull from there.

---

## Step 3: Review the Deployment YAML

```bash
cat manifests/deployment.yaml
```

```yaml
# manifests/deployment.yaml
apiVersion: apps/v1          # API group for Deployments
kind: Deployment             # The object type
metadata:
  name: demo-app             # Name of this Deployment
  namespace: workshop-app    # Which namespace
  labels:
    app: demo-app
spec:
  replicas: 2                # How many Pods to keep running
  selector:
    matchLabels:
      app: demo-app          # The Deployment manages Pods with this label
  template:                  # Pod blueprint starts here
    metadata:
      labels:
        app: demo-app        # Label every Pod gets (must match selector above!)
    spec:
      containers:
        - name: demo-app
          image: k8s-workshop-demo:1.0.0   # The image we just built and loaded
          imagePullPolicy: Never            # Use local image, don't try to pull
          ports:
            - containerPort: 3000
          env:
            # Downward API — Kubernetes injects Pod metadata as env vars
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            - name: APP_ENV
              value: "workshop"
            - name: APP_VERSION
              value: "1.0.0"
          resources:
            requests:
              cpu: 100m        # 100 millicores = 0.1 CPU core (guaranteed)
              memory: 64Mi     # 64 MiB RAM (guaranteed)
            limits:
              cpu: 250m        # Max CPU this container can use
              memory: 128Mi    # Max RAM — container is OOMKilled if exceeded
          readinessProbe:      # Is the app ready to receive traffic?
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:       # Is the app alive? Restart if not.
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 15
            periodSeconds: 20
```

### Key Fields Explained

| Field | What it means |
|-------|--------------|
| `replicas: 2` | Always keep 2 Pods running |
| `selector.matchLabels` | How the Deployment finds its Pods — must match `template.metadata.labels` |
| `imagePullPolicy: Never` | Use the locally loaded image — never try to pull from a registry |
| `resources.requests` | Minimum resources reserved for scheduling |
| `resources.limits` | Hard cap — container is OOMKilled if memory exceeded |
| `readinessProbe` | K8s waits for this to pass before sending traffic to the Pod |
| `livenessProbe` | K8s restarts the Pod if this keeps failing |

### The Downward API
The `fieldRef` env vars are a Kubernetes feature called the **Downward API** — it lets a Pod learn about itself (its own name, IP, namespace, node) without calling the API server. Our app displays these values on the page, which is how you'll see the pod name change as requests are load-balanced.

### CPU Units

| Value | Meaning |
|-------|---------|
| `1` | 1 full CPU core |
| `500m` | 0.5 CPU core (500 millicores) |
| `100m` | 0.1 CPU core (100 millicores) |

---

## Step 4: Update the Image in deployment.yaml

Before applying, update the image line in `manifests/deployment.yaml` to use the local image:

```yaml
image: k8s-workshop-demo:1.0.0
imagePullPolicy: Never
```

> The file currently has a placeholder registry URL. Replace it with the above two lines.

---

## Step 5: Apply the Deployment

```bash
kubectl apply -f manifests/deployment.yaml
```

---

## Step 6: Watch Pods Start Up

```bash
# Watch in real time (Ctrl+C to stop)
kubectl get pods -n workshop-app -w
```

Expected output:
```
NAME                        READY   STATUS    RESTARTS   AGE
demo-app-7d9f8b6c4-abc12   1/1     Running   0          30s
demo-app-7d9f8b6c4-xyz34   1/1     Running   0          30s
```

---

## Step 7: Inspect Your Deployment and Pods

```bash
# Overall Deployment status
kubectl get deployment demo-app -n workshop-app

# Detailed view with events and conditions
kubectl describe deployment demo-app -n workshop-app

# Describe a specific pod
kubectl describe pod <pod-name> -n workshop-app

# What to look for: Events section at the bottom, Conditions, probe status
```

---

## Step 8: View Logs

```bash
# Logs from a specific pod
kubectl logs <pod-name> -n workshop-app

# Stream logs live
kubectl logs -f <pod-name> -n workshop-app

# Logs from ALL pods matching the label at once
kubectl logs -l app=demo-app -n workshop-app

# Previous container logs (useful after a crash)
kubectl logs <pod-name> -n workshop-app --previous
```

You should see lines like:
```
☸  Workshop demo app running on port 3000
   Pod: demo-app-7d9f8b6c4-abc12
   Env: workshop | Version: 1.0.0
```

---

## Step 9: Execute into a Pod

```bash
# Open a shell inside a running container
kubectl exec -it <pod-name> -n workshop-app -- /bin/sh

# Once inside, try:
wget -qO- localhost:3000/health
hostname
env | grep POD
exit
```

> 💡 This is like SSH-ing into a container. Very useful for debugging!

---

## 🧪 Lab: Self-Healing Demo

This is the crowd-pleaser! Watch Kubernetes automatically replace a crashed Pod:

```bash
# Terminal 1: Watch pods continuously
kubectl get pods -n workshop-app -w

# Terminal 2: Delete a pod to simulate a crash
kubectl delete pod <pod-name> -n workshop-app
```

Watch Terminal 1 — within seconds a **new Pod** appears with a new name!

The Deployment controller noticed `actual (1) < desired (2)` and immediately created a replacement. The app never went down because the second replica kept serving traffic.

---

## Labels & Selectors

Labels are key-value pairs on any K8s object. Selectors filter by labels.

```bash
# Show labels on pods
kubectl get pods -n workshop-app --show-labels

# Filter pods by label
kubectl get pods -n workshop-app -l app=demo-app
```

> 🔑 Labels are how Kubernetes connects objects. The Deployment finds its Pods by label. The Service (next module) finds Pods to load-balance by label. This loose coupling is powerful.

---

**➡️ Next:** [Module 5 — Services](../05-services/README.md)
