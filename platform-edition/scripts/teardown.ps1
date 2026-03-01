$ErrorActionPreference = 'Stop'

function Write-Info($Message) { Write-Host "[INFO] $Message" }
function Write-WarnMsg($Message) { Write-Host "[WARN] $Message" -ForegroundColor Yellow }

function Test-IsAdmin {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$clusters = kind get clusters 2>$null
if ($clusters -contains 'workshop') {
  Write-Info "Deleting kind cluster 'workshop'"
  kind delete cluster --name workshop
} else {
  Write-WarnMsg "cluster 'workshop' not found"
}

$hostsPath = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
if (Test-IsAdmin) {
  if (Test-Path $hostsPath) {
    $lines = Get-Content $hostsPath
    if ($lines -match 'demo\.local') {
      $newLines = $lines | Where-Object { $_ -notmatch 'demo\.local' }
      Set-Content -Path $hostsPath -Value $newLines
      Write-Info 'Removed demo.local from hosts file'
    } else {
      Write-WarnMsg 'demo.local not present in hosts file'
    }
  }
} else {
  Write-WarnMsg 'Not running as Administrator; skipping hosts cleanup'
}

Write-Info 'Teardown complete'
