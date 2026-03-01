$ErrorActionPreference = 'Continue'

$global:Pass = 0
$global:Fail = 0

function Check($Description, [scriptblock]$TestBlock) {
  try {
    $ok = & $TestBlock
    if ($ok) {
      Write-Host "[PASS] $Description"
      $global:Pass++
    } else {
      Write-Host "[FAIL] $Description" -ForegroundColor Red
      $global:Fail++
    }
  } catch {
    Write-Host "[FAIL] $Description" -ForegroundColor Red
    $global:Fail++
  }
}

Check 'docker installed' { [bool](Get-Command docker -ErrorAction SilentlyContinue) }
Check 'docker running' { docker info *> $null; $LASTEXITCODE -eq 0 }
Check 'kind installed' { [bool](Get-Command kind -ErrorAction SilentlyContinue) }
Check 'kubectl installed' { [bool](Get-Command kubectl -ErrorAction SilentlyContinue) }
Check 'helm installed' { [bool](Get-Command helm -ErrorAction SilentlyContinue) }

Check "cluster 'workshop' exists" { (kind get clusters 2>$null) -contains 'workshop' }
Check 'kubectl context is kind-workshop' { (kubectl config current-context) -eq 'kind-workshop' }
Check 'node ready' { (kubectl get nodes --no-headers 2>$null | Select-String ' Ready ') -ne $null }

Check 'traefik pod running' { (kubectl get pods -n traefik --no-headers 2>$null | Select-String 'Running') -ne $null }
Check 'demo app pod running' { (kubectl get pods -n workshop-app --no-headers 2>$null | Select-String 'Running') -ne $null }
Check 'ingress exists' { kubectl get ingress demo-app-ingress -n workshop-app *> $null; $LASTEXITCODE -eq 0 }

$hostsPath = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
Check 'demo.local in hosts file' { (Get-Content $hostsPath -ErrorAction SilentlyContinue | Select-String 'demo\.local') -ne $null }

Check 'health endpoint responds' {
  $resp = Invoke-WebRequest -Uri 'http://demo.local/health' -UseBasicParsing -TimeoutSec 5
  $resp.StatusCode -eq 200
}

Write-Host "`nChecks: $Pass passed, $Fail failed"
if ($Fail -ne 0) { exit 1 }
