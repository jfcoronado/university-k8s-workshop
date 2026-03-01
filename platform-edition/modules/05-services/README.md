# Module 5 - Services: Internal Networking (Cross-Platform)

Time: 20 minutes
Goal: Expose the app via ClusterIP service and validate DNS/service routing.

## 1) Apply service

```bash
kubectl apply -f manifests/service.yaml
kubectl get svc -n workshop-app
kubectl describe svc demo-app-svc -n workshop-app
```

PowerShell uses the same commands.

## 2) Inspect endpoints

```bash
kubectl get endpoints demo-app-svc -n workshop-app
```

PowerShell uses the same command.

## 3) Port-forward test

```bash
kubectl port-forward svc/demo-app-svc 8080:80 -n workshop-app
```

Open `http://localhost:8080`.

## 4) DNS test from a running pod

### macOS/Linux/WSL

```bash
kubectl get pods -n workshop-app
kubectl exec -it <pod-name> -n workshop-app -- \
  wget -qO- http://demo-app-svc.workshop-app.svc.cluster.local | head -5
```

### Windows PowerShell

```powershell
kubectl get pods -n workshop-app
kubectl exec -it <pod-name> -n workshop-app -- wget -qO- http://demo-app-svc.workshop-app.svc.cluster.local
```

Optional truncation in PowerShell:

```powershell
kubectl exec -it <pod-name> -n workshop-app -- wget -qO- http://demo-app-svc | Select-Object -First 5
```

## 5) Endpoint change lab

```bash
kubectl get endpoints demo-app-svc -n workshop-app -w
kubectl delete pod <pod-name> -n workshop-app
```

PowerShell uses the same commands.
