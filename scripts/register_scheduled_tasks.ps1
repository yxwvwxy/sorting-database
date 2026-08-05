$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$bat = Join-Path $repo "scripts\run_scrape.bat"
$taskName = "SortingDataScrape20Min"

if (-not (Test-Path $bat)) {
  throw "Missing $bat"
}

# Three tasks: every hour at :10, :30, :50 (set PC timezone to Eastern)
$minutes = @("10", "30", "50")
foreach ($m in $minutes) {
  $name = "$taskName-$m"
  schtasks /Query /TN $name 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) {
    schtasks /Delete /TN $name /F | Out-Null
  }
  schtasks /Create /TN $name /TR "`"$bat`"" /SC DAILY /ST "00:$m" /RI 60 /DU 24:00 /F /RL LIMITED
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to create task $name"
  }
  Write-Host "Registered $name (every hour at :$m)"
}

Write-Host ""
Write-Host "Set this PC timezone to Eastern Time (America/New_York)."
Write-Host "Keep lid closed awake + plugged in so tasks keep firing."
