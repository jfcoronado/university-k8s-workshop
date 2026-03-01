# Windows PowerShell Guide

## Install tools (PowerShell)

```powershell
winget install Docker.DockerDesktop
winget install Kubernetes.kind
winget install Kubernetes.kubectl
winget install Helm.Helm
```

Start Docker Desktop and verify:

```powershell
docker --version
kind --version
kubectl version --client
helm version
```

## Run workshop automation (PowerShell)

From repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\platform-edition\scripts\setup.ps1
powershell -ExecutionPolicy Bypass -File .\platform-edition\scripts\verify.ps1
```

## Hosts file

`setup.ps1` attempts to add `demo.local` to `C:\Windows\System32\drivers\etc\hosts`.
If PowerShell is not running as Administrator, it prints a warning and skips that step.

## Teardown

```powershell
powershell -ExecutionPolicy Bypass -File .\platform-edition\scripts\teardown.ps1
```
