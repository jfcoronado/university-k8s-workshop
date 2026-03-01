$ErrorActionPreference = 'Stop'

function Write-Info($Message) { Write-Host "[INFO] $Message" }
function Write-WarnMsg($Message) { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-ErrorAndExit($Message) { Write-Host "[ERROR] $Message" -ForegroundColor Red; exit 1 }

function Test-IsAdmin {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Command($Name) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    Write-ErrorAndExit "$Name not found"
  }
}

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Manifests = Join-Path $RepoRoot 'manifests'
$AppDir = Join-Path $RepoRoot 'app'

Write-Info "Using repo root: $RepoRoot"

Assert-Command docker
Assert-Command kind
Assert-Command kubectl
Assert-Command helm

docker info *> $null
if ($LASTEXITCODE -ne 0) { Write-ErrorAndExit 'docker daemon is not running' }

Write-Info 'Pulling base images'
docker pull kindest/node:v1.29.0
docker pull traefik:v3.0

$clusters = kind get clusters 2>$null
if ($clusters -contains 'workshop') {
  Write-WarnMsg "cluster 'workshop' already exists; skipping create"
} else {
  Write-Info "Creating kind cluster"
  kind create cluster --name workshop --config (Join-Path $Manifests 'kind-config.yaml')
}

kubectl config use-context kind-workshop *> $null
kubectl wait --for=condition=Ready node --all --timeout=180s *> $null

Write-Info 'Installing traefik'
helm repo add traefik https://traefik.github.io/charts --force-update *> $null
helm repo update *> $null
kind load docker-image traefik:v3.0 --name workshop
helm upgrade --install traefik traefik/traefik `
  --namespace traefik `
  --create-namespace `
  --values (Join-Path $Manifests 'traefik-values.yaml') `
  --wait

Write-Info 'Building workshop app image'
docker build -t k8s-workshop-demo:1.0.0 $AppDir
kind load docker-image k8s-workshop-demo:1.0.0 --name workshop

Write-Info 'Applying manifests'
kubectl apply -f (Join-Path $Manifests 'namespace.yaml')
kubectl apply -f (Join-Path $Manifests 'configmap.yaml')
kubectl apply -f (Join-Path $Manifests 'secret.yaml')
kubectl apply -f (Join-Path $Manifests 'deployment.yaml')
kubectl apply -f (Join-Path $Manifests 'service.yaml')
kubectl apply -f (Join-Path $Manifests 'ingress.yaml')
kubectl rollout status deployment/demo-app -n workshop-app --timeout=180s

$hostsPath = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
if (Test-IsAdmin) {
  $hostsContent = Get-Content $hostsPath -ErrorAction SilentlyContinue
  if ($hostsContent -match 'demo\.local') {
    Write-WarnMsg 'demo.local already exists in hosts file'
  } else {
    Add-Content -Path $hostsPath -Value '127.0.0.1 demo.local'
    Write-Info 'Added demo.local to hosts file'
  }
} else {
  Write-WarnMsg 'Not running as Administrator; skipping hosts file update'
  Write-WarnMsg 'Run PowerShell as Administrator and add: 127.0.0.1 demo.local'
}

Write-Host ''
Write-Host 'Setup complete. Open http://demo.local'
