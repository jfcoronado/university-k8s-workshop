# Module 7 — ConfigMaps & Secrets

> ⏱️ **Time:** 20 minutes | 🎯 **Goal:** Externalize configuration and inject it into your app as env vars and files

---

## The 12-Factor App: Config in the Environment

A core principle of cloud-native applications: **separate config from code**.

❌ **Bad:** Hardcode database URLs, API keys, and feature flags in your Docker image  
✅ **Good:** Inject them at runtime via environment variables or mounted files

Kubernetes provides two objects for this:

| Object | For | Stored As |
|--------|-----|-----------|
| **ConfigMap** | Non-sensitive config (URLs, feature flags, tuning params) | Plaintext |
| **Secret** | Sensitive data (passwords, API keys, certs) | Base64 encoded (not encrypted by default!) |

> ⚠️ Secrets are base64 encoded, **NOT encrypted** by default. For real security, use tools like HashiCorp Vault, Sealed Secrets, or enable etcd encryption at rest.

---

## ConfigMaps

### Step 1: Review the ConfigMap

```bash
cat manifests/configmap.yaml
```

```yaml
# manifests/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: demo-app-config
  namespace: workshop-app
data:
  # Simple key-value pairs
  APP_ENV: "workshop"
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "100"
  FEATURE_NEW_UI: "true"
  
  # A whole config file as a value (multi-line)
  app.properties: |
    environment=workshop
    log.level=info
    feature.new_ui=true
    max.connections=100

  feature-flags.json: |
    {
      "new_ui": true,
      "dark_mode": false,
      "max_connections": 100
    }
```

### Step 2: Apply and Inspect

```bash
kubectl apply -f manifests/configmap.yaml

kubectl get configmaps -n workshop-app
kubectl describe configmap demo-app-config -n workshop-app
```

---

## Secrets

### Step 3: Review the Secret

```bash
cat manifests/secret.yaml
```

```yaml
# manifests/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: demo-app-secret
  namespace: workshop-app
type: Opaque
stringData:
  # Use stringData for human-readable values (K8s encodes for you)
  DB_PASSWORD: "super-secret-password"
  API_KEY: "my-api-key-12345"
  connection-string: "postgresql://user:password@db:5432/myapp"
```

> 💡 `stringData` vs `data`: `stringData` accepts plain strings (K8s base64-encodes them). `data` requires pre-encoded base64 values.

### Step 4: Apply the Secret

```bash
kubectl apply -f manifests/secret.yaml

kubectl get secrets -n workshop-app

# Notice: values are hidden
kubectl describe secret demo-app-secret -n workshop-app
```

Manual base64 encoding (for reference):
```bash
# Encode
echo -n "my-password" | base64

# Decode
echo "bXktcGFzc3dvcmQ=" | base64 -d
```

---

## Injecting Config into Pods

There are three ways to consume ConfigMaps and Secrets in your Pods:

### Method 1: Environment Variables (Individual Keys)

```yaml
spec:
  containers:
    - name: demo-app
      image: k8s-workshop-demo:1.0.0
      env:
        # From ConfigMap
        - name: APP_ENV
          valueFrom:
            configMapKeyRef:
              name: demo-app-config
              key: APP_ENV
        # From Secret
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: demo-app-secret
              key: DB_PASSWORD
```

### Method 2: Inject All Keys as Environment Variables (envFrom)

```yaml
spec:
  containers:
    - name: demo-app
      envFrom:
        - configMapRef:
            name: demo-app-config
        - secretRef:
            name: demo-app-secret
```

### Method 3: Mount as Files (Volumes)

```yaml
spec:
  containers:
    - name: demo-app
      volumeMounts:
        - name: config-volume
          mountPath: /etc/config      # Files appear here inside the container
        - name: secret-volume
          mountPath: /etc/secrets
          readOnly: true
  volumes:
    - name: config-volume
      configMap:
        name: demo-app-config
    - name: secret-volume
      secret:
        secretName: demo-app-secret
```

---

## Step 5: Update the Deployment to Use Config

The full deployment with config injection is in `manifests/deployment-with-config.yaml`:

```bash
cat manifests/deployment-with-config.yaml
kubectl apply -f manifests/deployment-with-config.yaml

# Verify the env vars are set in the pod
kubectl exec -it <pod-name> -n workshop-app -- env | grep -E "APP_ENV|LOG_LEVEL|DB_PASSWORD"
```

---

## Step 6: Verify Mounted Files

```bash
kubectl exec -it <pod-name> -n workshop-app -- ls /etc/config
kubectl exec -it <pod-name> -n workshop-app -- cat /etc/config/app.properties
```

---

## Live ConfigMap Updates

ConfigMaps mounted as **volumes** update automatically (within ~60 seconds) without restarting Pods.

ConfigMaps injected as **environment variables** do NOT update — you must restart the Pod.

```bash
# Update the configmap
kubectl edit configmap demo-app-config -n workshop-app
# Change LOG_LEVEL from "info" to "debug"
# Save and exit

# For env var injection: trigger a rollout
kubectl rollout restart deployment/demo-app -n workshop-app
```

---

## 🧪 Lab Exercises

```bash
# 1. View your secret values (base64 decoded)
kubectl get secret demo-app-secret -n workshop-app -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
echo ""

# 2. Create a quick ConfigMap from a literal value
kubectl create configmap my-quick-config \
  --from-literal=COLOR=blue \
  --from-literal=FONT_SIZE=16 \
  -n workshop-app

kubectl get cm my-quick-config -n workshop-app -o yaml

# 3. Create a ConfigMap from a file
echo "my config content" > /tmp/my-config.txt
kubectl create configmap file-config --from-file=/tmp/my-config.txt -n workshop-app
```

---

**➡️ Next:** [Module 8 — Scaling & Rolling Updates](../08-scaling-updates/README.md)
