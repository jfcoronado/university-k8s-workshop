# Module 2 - Creating Your KIND Cluster (Cross-Platform)

Time: 20 minutes
Goal: Create and verify a local Kubernetes cluster with ingress-ready port mappings.

## 1) Create the cluster

### macOS/Linux/WSL

```bash
kind create cluster --name workshop --config manifests/kind-config.yaml
```

### Windows PowerShell

```powershell
kind create cluster --name workshop --config .\manifests\kind-config.yaml
```

## 2) Verify cluster and context

### macOS/Linux/WSL

```bash
kubectl cluster-info --context kind-workshop
kubectl get nodes
kubectl config current-context
```

### Windows PowerShell

```powershell
kubectl cluster-info --context kind-workshop
kubectl get nodes
kubectl config current-context
```

## 3) Explore namespaces and pods

```bash
kubectl get pods -A
kubectl get namespaces
```

PowerShell uses the same commands.

## 4) Useful KIND commands

```bash
kind get clusters
kind load docker-image my-image:tag --name workshop
kind delete cluster --name workshop
```

PowerShell uses the same commands.

## 5) Shell-specific notes

- Original module uses Unix helpers like `head` in one exploration command.
- In PowerShell, replace `| head -30` with `| Select-Object -First 30`.

PowerShell equivalent:

```powershell
kubectl api-resources | Select-Object -First 30
```
