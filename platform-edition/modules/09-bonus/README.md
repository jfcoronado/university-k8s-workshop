# Module 9 - Bonus: Troubleshooting & Tips (Cross-Platform)

Time: Open-ended
Goal: Quickly diagnose common failures with shell-safe command alternatives.

## Core debug commands (all platforms)

```bash
kubectl describe pod <pod> -n <ns>
kubectl get events -n <ns> --sort-by='.lastTimestamp'
kubectl logs <pod> -n <ns>
kubectl logs <pod> -n <ns> --previous
kubectl get endpoints <svc> -n <ns>
```

PowerShell uses the same commands.

## Ingress debug command with shell differences

### macOS/Linux/WSL

```bash
kubectl logs -n traefik $(kubectl get pods -n traefik -o name | grep traefik | head -1)
```

### Windows PowerShell

```powershell
$pod = kubectl get pods -n traefik -o name | Select-String traefik | Select-Object -First 1
kubectl logs -n traefik $pod.ToString()
```

## Hosts file cleanup

### macOS

```bash
sudo sed -i '' '/demo.local/d' /etc/hosts
```

### Linux

```bash
sudo sed -i '/demo.local/d' /etc/hosts
```

### Windows PowerShell (Admin)

```powershell
$hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
(Get-Content $hosts) | Where-Object { $_ -notmatch 'demo\.local' } | Set-Content $hosts
```

## Preferred cleanup scripts

- macOS/Linux/WSL:

```bash
bash platform-edition/scripts/teardown.sh
```

- Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\platform-edition\scripts\teardown.ps1
```
