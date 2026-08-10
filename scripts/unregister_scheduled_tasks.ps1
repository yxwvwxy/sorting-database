# Remove Windows Task Scheduler jobs for the 20-minute scrape.
$ErrorActionPreference = "Stop"
$taskBase = "SortingDataScrape20Min"
$minutes = @("10", "30", "50")

foreach ($m in $minutes) {
  $name = "$taskBase-$m"
  schtasks /Query /TN $name 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) {
    schtasks /Delete /TN $name /F | Out-Null
    Write-Host "Removed $name"
  } else {
    Write-Host "Not found: $name"
  }
}

Write-Host ""
Write-Host "Windows schedule cleared. You can re-enable Mac LaunchAgent if needed."
