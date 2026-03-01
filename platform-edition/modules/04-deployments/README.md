# Module 4 - Deployments: Running Your App (Cross-Platform)

Time: 25 minutes
Goal: Build the app image, load it into KIND, deploy it, and verify pod health.

## 1) Build image

### macOS/Linux/WSL

```bash
docker build -t k8s-workshop-demo:1.0.0 ./app
docker images | grep k8s-workshop-demo
```

### Windows PowerShell

```powershell
docker build -t k8s-workshop-demo:1.0.0 .\app
docker images | Select-String k8s-workshop-demo
```

## 2) Load image into KIND

```bash
kind load docker-image k8s-workshop-demo:1.0.0 --name workshop
```

PowerShell uses the same command.

## 3) Apply deployment and watch rollout

```bash
kubectl apply -f manifests/deployment.yaml
kubectl get pods -n workshop-app -w
```

PowerShell uses the same commands.

## 4) Logs and pod inspection

```bash
kubectl describe deployment demo-app -n workshop-app
kubectl logs -l app=demo-app -n workshop-app
```

PowerShell uses the same commands.

## 5) Exec into pod

```bash
kubectl exec -it <pod-name> -n workshop-app -- /bin/sh
```

Note: this command opens a Linux shell inside the container. It is valid from PowerShell too.

## 6) Self-healing test

```bash
kubectl get pods -n workshop-app -w
kubectl delete pod <pod-name> -n workshop-app
```

PowerShell uses the same commands.
