# Module 9 — Bonus: Troubleshooting & Next Steps

> ⏱️ **Time:** Open-ended | 🎯 **Goal:** Debug common issues and know where to go next

---

## Common Pod States & What They Mean

| Status | Meaning | Fix |
|--------|---------|-----|
| `Pending` | Scheduler can't place the pod | Check resources, node selectors, taints |
| `ContainerCreating` | Image pulling or volume mounting | Wait, or check image name/pull secrets |
| `Running` | Container is running | Normal |
| `CrashLoopBackOff` | Container keeps crashing | Check logs: `kubectl logs <pod> --previous` |
| `OOMKilled` | Container exceeded memory limit | Increase memory limits |
| `ImagePullBackOff` | Can't pull the image | Check image name, registry access, pull secrets |
| `ErrImagePull` | Image pull failed once | Check image name/tag, network |
| `Terminating` | Pod is being deleted | Normal, or check finalizers if stuck |
| `Error` | Container exited with error | Check logs |

---

## Troubleshooting Decision Tree

```
Pod not working?
│
├─ kubectl get pods -n <ns>
│   │
│   ├─ Status: Pending
│   │   └─ kubectl describe pod <pod> -n <ns>
│   │       Look for: Events section — "Insufficient CPU/Memory", "Unschedulable"
│   │
│   ├─ Status: CrashLoopBackOff
│   │   └─ kubectl logs <pod> -n <ns> --previous
│   │       Look for: App startup error, missing env var, failed DB connection
│   │
│   ├─ Status: ImagePullBackOff
│   │   └─ kubectl describe pod <pod> -n <ns>
│   │       Look for: Image name typo, private registry needs pull secret
│   │
│   └─ Status: Running but app not responding
│       ├─ kubectl exec -it <pod> -n <ns> -- curl localhost:<port>
│       ├─ kubectl get endpoints <svc> -n <ns>
│       └─ kubectl logs <pod> -n <ns>
```

---

## Essential Debugging Commands

```bash
# 1. The "describe" command — your best friend
kubectl describe pod <pod-name> -n <ns>
kubectl describe deployment <deploy-name> -n <ns>
kubectl describe svc <svc-name> -n <ns>
kubectl describe ingress <ingress-name> -n <ns>

# 2. Events — what happened in the cluster
kubectl get events -n workshop-app --sort-by='.lastTimestamp'

# 3. Logs
kubectl logs <pod> -n <ns>
kubectl logs <pod> -n <ns> --previous      # Last terminated container
kubectl logs -l app=demo-app -n <ns>       # All pods matching label

# 4. Shell into a pod
kubectl exec -it <pod> -n <ns> -- /bin/sh
kubectl exec -it <pod> -n <ns> -- /bin/bash

# 5. Run a debug pod (ephemeral container)
kubectl run debug --image=busybox --restart=Never -it --rm -n workshop-app -- sh
kubectl run debug --image=curlimages/curl --restart=Never -it --rm -n workshop-app \
  -- curl -v http://demo-app-svc

# 6. Port forward to test services
kubectl port-forward svc/demo-app-svc 8080:80 -n workshop-app
kubectl port-forward pod/<pod-name> 8080:80 -n workshop-app

# 7. Check resource usage (requires metrics-server)
kubectl top pods -n workshop-app
kubectl top nodes
```

---

## Debugging Ingress

```bash
# 1. Is the Ingress Controller running?
kubectl get pods -n traefik

# 2. Does the Ingress have an address?
kubectl get ingress -n workshop-app
# ADDRESS column should show 'localhost' or an IP

# 3. Are your Service endpoints populated?
kubectl get endpoints demo-app-svc -n workshop-app
# Empty endpoints = no pods matching the selector

# 4. Check the Ingress Controller logs
kubectl logs -n traefik \
  $(kubectl get pods -n traefik -o name | grep controller | head -1)

# 5. Test directly to the controller
curl -H "Host: demo.local" http://localhost
```

---

## Common Mistakes & Fixes

### Label mismatch between Deployment selector and Pod template
```bash
# Symptom: No endpoints for service
# Check: Do these match?
kubectl get deploy demo-app -n workshop-app -o jsonpath='{.spec.selector}'
kubectl get pods -n workshop-app --show-labels
```

### Wrong namespace
```bash
# Symptom: "not found" errors
# Always include -n <namespace>
kubectl get pods -n workshop-app    # NOT just: kubectl get pods
```

### Port mismatch
```bash
# Service targetPort must match containerPort in Pod spec
# Check:
kubectl get svc demo-app-svc -n workshop-app -o yaml | grep -A5 ports
kubectl get pods -n workshop-app -o yaml | grep -A5 ports
```

### Image not found in KIND
```bash
# If using a locally built image, load it into KIND first
docker build -t my-app:v1 .
kind load docker-image my-app:v1 --name workshop
# Then set imagePullPolicy: Never in your Deployment
```

---

## Clean Up the Workshop

When you're done:

```bash
# Remove the /etc/hosts entry
sudo sed -i '' '/demo.local/d' /etc/hosts    # macOS
sudo sed -i '/demo.local/d' /etc/hosts        # Linux

# Or use the teardown script
bash scripts/teardown.sh
```

---

## Next Steps: What to Learn

### Immediate Next Topics
- **Helm** — Kubernetes package manager. Install complex apps with a single command
- **Persistent Volumes** — Give your Pods storage that survives restarts
- **StatefulSets** — For stateful apps (databases, queues)
- **RBAC** — Control who can do what in your cluster
- **Network Policies** — Control which Pods can talk to which

### Intermediate Topics
- **Service Mesh** (Istio / Linkerd) — mTLS, traffic splitting, observability
- **GitOps** (ArgoCD / Flux) — Let git be the source of truth for deployments
- **Observability** (Prometheus + Grafana) — Metrics, dashboards, alerting
- **Cert-Manager** — Automatic TLS certificates (Let's Encrypt)

### Certifications
| Cert | Level | Focus |
|------|-------|-------|
| CKA | Intermediate | Cluster administration |
| CKAD | Intermediate | Application development |
| CKS | Advanced | Security |

### Practice Environments
- **Killercoda:** [killercoda.com](https://killercoda.com) — Free browser-based labs
- **Play with K8s:** [labs.play-with-k8s.com](https://labs.play-with-k8s.com) — 4-hour free sessions
- **k3d:** Lightweight alternative to KIND
- **minikube:** Another local K8s option with add-ons

### Community
- **CNCF Slack:** [slack.cncf.io](https://slack.cncf.io) — #kubernetes channel
- **Cloud Native LA:** [meetup.com/cloud-native-la](https://meetup.com/cloud-native-la)
- **Kubernetes Docs:** [kubernetes.io/docs](https://kubernetes.io/docs) — the best reference
- **KubeWeekly newsletter:** [kubeweekly.io](https://kubeweekly.io)

---

## 🙌 Thank You!

You just went from zero to a fully functioning Kubernetes deployment pipeline!

Questions after the workshop? Open an issue in this repo or find me on CNCF Slack.
