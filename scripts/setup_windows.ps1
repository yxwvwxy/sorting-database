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
Write-Host "1. Copy .env.example to .env and fill UNIUNI_* + SUPABASE_* (keep secrets on this PC only)"
Write-Host "2. Test one run:  .\scripts\run_scrape.bat"
Write-Host "3. Register schedule:  powershell -ExecutionPolicy Bypass -File .\scripts\register_scheduled_tasks.ps1"
Write-Host "4. After Mac pushes code:  powershell -ExecutionPolicy Bypass -File .\scripts\pull_windows_updates.ps1"
Write-Host "See WINDOWS_SETUP.md for Mac-edit / Windows-run workflow."
