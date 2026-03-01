# Module 7 — ConfigMaps & Secrets

> ⏱️ **Time:** 20 minutes | 🎯 **Goal:** Externalize configuration and inject it into your app as env vars and mounted files

---

## 🧹 Clean Up First (Reset to a Known Good State)

If you attempted this module before, run these commands to wipe everything and start fresh.
If this is your first time through, skip to [The Concepts](#the-concepts) below.

```bash
# Remove the updated deployment
kubectl delete deployment demo-app -n workshop-app --ignore-not-found

# Remove ConfigMap and Secret
kubectl delete configmap demo-app-config -n workshop-app --ignore-not-found
kubectl delete secret demo-app-secret -n workshop-app --ignore-not-found

# Remove any quick lab ConfigMaps you may have created
kubectl delete configmap my-quick-config -n workshop-app --ignore-not-found
kubectl delete configmap file-config -n workshop-app --ignore-not-found

# Confirm the namespace is clean — only the Service and Ingress should remain
kubectl get all -n workshop-app
kubectl get configmaps -n workshop-app
kubectl get secrets -n workshop-app
```

Now restore the baseline deployment (pods running, no ConfigMap/Secret yet):

```bash
kubectl apply -f manifests/deployment.yaml
kubectl rollout status deployment/demo-app -n workshop-app
# → deployment "demo-app" successfully rolled out

kubectl get pods -n workshop-app
# → 2 pods Running
```

You're at a clean starting point. Continue below.

---

## The Concepts

### Why ConfigMaps and Secrets?

A core principle of cloud-native apps (12-Factor App): **separate config from code**.

| ❌ Bad | ✅ Good |
|--------|---------|
| Hardcode `DB_URL`, API keys, feature flags in the Docker image | Inject them at runtime — same image, different config per environment |
| Rebuild and redeploy the app to change a log level | `kubectl apply` a ConfigMap update |

Kubernetes provides two objects for this:

| Object | For | Stored As |
|--------|-----|-----------|
| **ConfigMap** | Non-sensitive config (URLs, feature flags, tuning params) | Plaintext |
| **Secret** | Sensitive data (passwords, API keys, certs) | Base64 encoded |

> ⚠️ Secrets are base64 **encoded**, not encrypted by default. For production use Sealed Secrets, External Secrets Operator, or HashiCorp Vault.

### Two Ways to Consume Them in a Pod

| Method | How | Updates without restart? |
|--------|-----|--------------------------|
| **Environment variable** | `configMapKeyRef` / `secretKeyRef` in `env:` | ❌ No — must rollout restart |
| **Volume mount** | `volumes:` + `volumeMounts:` | ✅ Yes — within ~60 seconds |

This module uses **both** methods so you can see the difference.

---

## Step 1 — Review and Apply the ConfigMap

```bash
cat manifests/configmap.yaml
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: demo-app-config
  namespace: workshop-app
data:
  # Simple key-value pairs — injected as env vars
  APP_ENV: "workshop"
  APP_VERSION: "1.0.0"
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "100"
  FEATURE_NEW_UI: "false"

  # Multi-line values — each becomes a file under /etc/config/
  app.properties: |
    environment=workshop
    app.version=1.0.0
    log.level=info
    feature.new_ui=false
    max.connections=100

  feature-flags.json: |
    {
      "new_ui": false,
      "dark_mode": false,
      "max_connections": 100
    }
```

Apply it:

```bash
kubectl apply -f manifests/configmap.yaml

kubectl get configmaps -n workshop-app
kubectl describe configmap demo-app-config -n workshop-app
```

> 💡 Applying the ConfigMap alone does **nothing** to your running pods. The pods don't know it exists yet — that happens in Step 3.

---

## Step 2 — Review and Apply the Secret

```bash
cat manifests/secret.yaml
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: demo-app-secret
  namespace: workshop-app
type: Opaque
stringData:
  DB_PASSWORD: "super-secret-workshop-password"
  API_KEY: "workshop-api-key-12345"
  connection-string: "postgresql://appuser:super-secret-workshop-password@db:5432/workshopdb"
```

> 💡 `stringData` lets you write plain strings — Kubernetes base64-encodes them automatically. Use `data:` if you want to supply pre-encoded values yourself.

Apply it:

```bash
kubectl apply -f manifests/secret.yaml

# Values are hidden in describe output — this is intentional
kubectl get secrets -n workshop-app
kubectl describe secret demo-app-secret -n workshop-app

# Manually decode a value (for learning only)
kubectl get secret demo-app-secret -n workshop-app \
  -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
echo ""
```

> 💡 Applying the Secret alone also does **nothing** to your running pods.

---

## Step 3 — Apply the Updated Deployment

> ⚠️ **This is the step most people miss.**
>
> The ConfigMap and Secret now exist in the cluster, but your pods are still using `deployment.yaml`
> which has hardcoded `env:` values and **no volume mounts at all**. You must apply
> `deployment-with-config.yaml` to wire everything up. This triggers a rolling update that
> replaces the old pods with new ones that reference the ConfigMap and Secret.

Review what's changing:

```bash
diff manifests/deployment.yaml manifests/deployment-with-config.yaml
```

The key differences in `deployment-with-config.yaml`:
- `env:` entries now use `configMapKeyRef` and `secretKeyRef` instead of hardcoded `value:`
- A `volumeMounts:` block adds `/etc/config` and `/etc/secrets` inside the container
- A `volumes:` block at the pod level wires the ConfigMap and Secret to those mounts

Apply it:

```bash
kubectl apply -f manifests/deployment-with-config.yaml

# Wait for the rolling update to finish before testing — do not skip this
kubectl rollout status deployment/demo-app -n workshop-app
# → Waiting for deployment "demo-app" rollout to finish: 1 out of 2 new replicas have been updated...
# → deployment "demo-app" successfully rolled out

# Confirm the change-cause annotation updated
kubectl rollout history deployment/demo-app -n workshop-app
# REVISION  CHANGE-CAUSE
# 1         Initial deployment — workshop demo app v1.0.0
# 2         Module 7 — Added ConfigMap and Secret injection

# Get fresh pod names — the old pods have been replaced
kubectl get pods -n workshop-app
```

---

## Step 4 — Verify Environment Variables

Use a pod name from the `kubectl get pods` output above:

```bash
kubectl exec -it <pod-name> -n workshop-app -- \
  env | grep -E "APP_ENV|APP_VERSION|LOG_LEVEL|FEATURE_NEW_UI|DB_PASSWORD|API_KEY"
```

Expected output:

```
APP_ENV=workshop
APP_VERSION=1.0.0
LOG_LEVEL=info
FEATURE_NEW_UI=false
DB_PASSWORD=super-secret-workshop-password
API_KEY=workshop-api-key-12345
```

All six values present — the first four come from the ConfigMap, the last two from the Secret.

---

## Step 5 — Verify Mounted Files

```bash
kubectl exec -it <pod-name> -n workshop-app -- ls /etc/config
```

Expected output:

```
APP_ENV
APP_VERSION
FEATURE_NEW_UI
LOG_LEVEL
MAX_CONNECTIONS
app.properties
feature-flags.json
```

> 💡 Every key in a ConfigMap becomes a file when mounted as a volume. The filename is the key, the content is the value.

```bash
# Read the properties file
kubectl exec -it <pod-name> -n workshop-app -- cat /etc/config/app.properties

# Read the JSON feature flags
kubectl exec -it <pod-name> -n workshop-app -- cat /etc/config/feature-flags.json

# Check the secrets mount
kubectl exec -it <pod-name> -n workshop-app -- ls /etc/secrets
kubectl exec -it <pod-name> -n workshop-app -- cat /etc/secrets/DB_PASSWORD
```

---

## Step 6 — Live ConfigMap Update (Volume Mount Auto-Refresh)

ConfigMaps mounted as **volumes** update automatically inside running pods within ~60 seconds, with no restart required.

```bash
# Edit the ConfigMap — change LOG_LEVEL from "info" to "debug"
kubectl edit configmap demo-app-config -n workshop-app
# Find: LOG_LEVEL: "info"
# Change to: LOG_LEVEL: "debug"
# Save and exit (:wq in vim)

# Wait ~60 seconds, then check the mounted file
kubectl exec -it <pod-name> -n workshop-app -- cat /etc/config/LOG_LEVEL
# → debug  (updated automatically)

# The env var has NOT changed — it's baked in at pod start time
kubectl exec -it <pod-name> -n workshop-app -- env | grep LOG_LEVEL
# → LOG_LEVEL=info   (still the old value)

# To pick up env var changes you need a rollout restart
kubectl rollout restart deployment/demo-app -n workshop-app
kubectl rollout status deployment/demo-app -n workshop-app

kubectl exec -it <new-pod-name> -n workshop-app -- env | grep LOG_LEVEL
# → LOG_LEVEL=debug  (now updated)

# Reset back to "info" so Module 8 starts cleanly
kubectl patch configmap demo-app-config -n workshop-app \
  --type merge -p '{"data":{"LOG_LEVEL":"info"}}'
kubectl rollout restart deployment/demo-app -n workshop-app
kubectl rollout status deployment/demo-app -n workshop-app
```

---

## 🧪 Lab Exercises

```bash
# 1. Create a ConfigMap from literal values on the command line
kubectl create configmap my-quick-config \
  --from-literal=COLOR=blue \
  --from-literal=FONT_SIZE=16 \
  -n workshop-app

kubectl get cm my-quick-config -n workshop-app -o yaml

# 2. Create a ConfigMap from a local file
echo "my workshop config content" > /tmp/my-config.txt
kubectl create configmap file-config \
  --from-file=/tmp/my-config.txt \
  -n workshop-app

kubectl describe configmap file-config -n workshop-app

# 3. Decode all secret values at once
kubectl get secret demo-app-secret -n workshop-app \
  -o jsonpath='{range .data.*}{@}{"\n"}{end}' | while read val; do
    echo "$val" | base64 -d; echo ""
  done

# 4. See the envFrom alternative (inject all ConfigMap keys at once)
kubectl explain pod.spec.containers.envFrom
```

---

## 🔍 Troubleshooting

**`ls: /etc/config: No such file or directory`**

You exec-ed into a pod from the old deployment that has no volume mounts. Confirm:

```bash
kubectl describe deployment demo-app -n workshop-app | grep change-cause
# Should show: Module 7 — Added ConfigMap and Secret injection
# If it shows: Initial deployment — Step 3 was never completed
```

Fix:

```bash
kubectl apply -f manifests/deployment-with-config.yaml
kubectl rollout status deployment/demo-app -n workshop-app
kubectl get pods -n workshop-app   # get fresh pod names, then retry
```

---

**`APP_ENV=workshop` shows but `DB_PASSWORD` is missing**

Same root cause — pods are still from the old deployment with hardcoded values, or the Secret was never applied.

```bash
kubectl get secret demo-app-secret -n workshop-app   # confirm it exists

# If missing:
kubectl apply -f manifests/secret.yaml

# Re-apply the deployment and wait
kubectl apply -f manifests/deployment-with-config.yaml
kubectl rollout status deployment/demo-app -n workshop-app
```

---

**Pod stuck in `CreateContainerConfigError`**

The ConfigMap or Secret referenced by the deployment doesn't exist yet. Apply them first, and the pending pod recovers automatically:

```bash
kubectl apply -f manifests/configmap.yaml
kubectl apply -f manifests/secret.yaml

# Pod should self-heal within a few seconds
kubectl get pods -n workshop-app -w
```

---

## Summary

The correct apply order for this module is always:

```
configmap.yaml  →  secret.yaml  →  deployment-with-config.yaml
```

| Resource | What applying it does |
|----------|-----------------------|
| `configmap.yaml` | Creates the ConfigMap object — pods don't see it yet |
| `secret.yaml` | Creates the Secret object — pods don't see it yet |
| `deployment-with-config.yaml` | **Wires it all up** — rolling restart creates new pods that reference both objects as env vars and volume mounts |

**The golden rule: ConfigMaps and Secrets are inert until a pod spec explicitly references them.**

---

**➡️ Next:** [Module 8 — Scaling & Rolling Updates](../08-scaling-updates/README.md)
