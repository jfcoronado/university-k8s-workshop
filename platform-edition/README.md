# Cross-Platform Workshop Pack (Non-Destructive)

This folder contains a cross-platform variant of the workshop docs and helper scripts.
Your existing repository files are unchanged.

## What is in this folder

- `docs/platforms/macos.md`
- `docs/platforms/linux.md`
- `docs/platforms/windows-powershell.md`
- `modules/00-preflight/README.md` (platform-aware preflight)
- `modules/02-kind-cluster/README.md` (platform-aware cluster setup)
- `modules/04-deployments/README.md` (platform-aware deployment flow)
- `modules/05-services/README.md` (platform-aware service/DNS commands)
- `modules/06-ingress/README.md` (platform-aware hosts steps)
- `modules/09-bonus/README.md` (platform-aware troubleshooting)
- `scripts/setup.sh`, `scripts/verify.sh`, `scripts/teardown.sh`
- `scripts/setup.ps1`, `scripts/verify.ps1`, `scripts/teardown.ps1`

## Suggested usage

1. Keep using the original module flow for core learning content.
2. Use the platform guides in `docs/platforms/` for OS-specific setup and command differences.
3. Use the new scripts in this folder if you want automation by shell:
   - macOS/Linux/WSL: `bash platform-edition/scripts/setup.sh`
   - Windows PowerShell: `powershell -ExecutionPolicy Bypass -File .\\platform-edition\\scripts\\setup.ps1`

## Notes

- These scripts operate on the existing repo resources (`manifests/`, `app/`) from the repository root.
- If your path has spaces, run commands from a terminal started in the repo root.
