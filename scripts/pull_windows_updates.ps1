# Pull latest scraper code on the Windows runner (edit happens on Mac).
$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $PSScriptRoot)

Write-Host "Repo: $(Get-Location)"
Write-Host "Branch: $(git rev-parse --abbrev-ref HEAD)"
Write-Host ""

git fetch origin
git pull --ff-only
if ($LASTEXITCODE -ne 0) {
  throw "git pull failed. Resolve conflicts or check network/auth, then retry."
}

if (-not (Test-Path ".venv\Scripts\python.exe")) {
  Write-Host "WARNING: .venv missing. Run: powershell -ExecutionPolicy Bypass -File .\scripts\setup_windows.ps1"
  exit 1
}

Write-Host ""
Write-Host "Code updated."
Write-Host "If requirements.txt changed since last setup, re-run:"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\scripts\setup_windows.ps1"
Write-Host "Optional smoke test:"
Write-Host "  .\scripts\run_scrape.bat --dry-run"
