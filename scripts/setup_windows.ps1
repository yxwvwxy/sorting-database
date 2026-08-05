$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $PSScriptRoot)

Write-Host "Creating venv..."
python -m venv .venv
& .\.venv\Scripts\python.exe -m pip install --upgrade pip
& .\.venv\Scripts\pip.exe install -r requirements.txt
& .\.venv\Scripts\python.exe -m playwright install chromium

if (-not (Test-Path "logs")) { New-Item -ItemType Directory -Path "logs" | Out-Null }

Write-Host ""
Write-Host "Setup complete."
Write-Host "1. Copy .env.example to .env and fill secrets"
Write-Host "2. Test one run:  .\scripts\run_scrape.bat"
Write-Host "3. Register schedule:  powershell -ExecutionPolicy Bypass -File .\scripts\register_scheduled_tasks.ps1"
