$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$bat = Join-Path $repo "scripts\run_scrape.bat"
$taskName = "SortingDataScrape20Min"

if (-not (Test-Path -LiteralPath $bat)) {
  throw "Missing $bat"
}

# Three tasks: every hour at :10, :30, :50 (PC timezone should be Eastern)
$minutes = @("10", "30", "50")
foreach ($m in $minutes) {
  $name = "$taskName-$m"

  Unregister-ScheduledTask -TaskName $name -Confirm:$false -ErrorAction SilentlyContinue

  # Use cmd.exe so paths with spaces (e.g. "Sorting Database") are not split.
  $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$bat`""
  $trigger = New-ScheduledTaskTrigger -Once -At ([datetime]::Today.AddMinutes([int]$m)) `
    -RepetitionInterval (New-TimeSpan -Hours 1) `
    -RepetitionDuration (New-TimeSpan -Days 3650)
  $settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2)
  $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

  Register-ScheduledTask -TaskName $name -Action $action -Trigger $trigger -Settings $settings -Principal $principal | Out-Null
  Write-Host "Registered $name (every hour at :$m)"
}

Write-Host ""
Write-Host "Set this PC timezone to Eastern Time (America/New_York)."
Write-Host "Keep lid closed awake + plugged in so tasks keep firing."
