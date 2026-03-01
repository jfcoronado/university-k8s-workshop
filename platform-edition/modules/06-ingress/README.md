# Module 6 - Ingress: External Traffic Routing (Cross-Platform)

Time: 25 minutes
Goal: Install Traefik and route `demo.local` traffic to your app.

## 1) Install Helm

### macOS

```bash
brew install helm
```

### Linux

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Windows PowerShell

```powershell
winget install Helm.Helm
```

## 2) Pre-pull and load Traefik image

```bash
docker pull traefik:v3.0
kind load docker-image traefik:v3.0 --name workshop
```

## 3) Install Traefik using the values file

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm upgrade --install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --values manifests/traefik-values.yaml \
  --wait
```

## 4) Apply ingress

```bash
kubectl apply -f manifests/ingress.yaml
kubectl get ingress -n workshop-app
```

## 5) Configure hosts file

### macOS/Linux

```bash
echo '127.0.0.1 demo.local' | sudo tee -a /etc/hosts
```

### Windows PowerShell (Admin)

```powershell
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value '127.0.0.1 demo.local'
```

## 6) Verify end-to-end

- Browser: `http://demo.local`
- CLI check:

```bash
curl http://demo.local/health
```

PowerShell equivalent:

```powershell
(Invoke-WebRequest -Uri 'http://demo.local/health' -UseBasicParsing).Content
```
