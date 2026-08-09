@echo off
setlocal
cd /d "%~dp0.."

REM Stable browser path (ignore any Cursor/temp PLAYWRIGHT_BROWSERS_PATH)
set "PLAYWRIGHT_BROWSERS_PATH=%LOCALAPPDATA%\ms-playwright"
set PYTHONUTF8=1
set PYTHONIOENCODING=utf-8

if not exist ".venv\Scripts\python.exe" (
  echo Missing .venv. Run scripts\setup_windows.ps1 first.
  exit /b 1
)

if not exist "logs" mkdir logs

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd"') do set DAY=%%i
set LOG=logs\scrape-%DAY%.log
set LOCK=logs\scrape.lock

REM Stale lock: schedule is every 20m; expire after 15m so the next slot can recover.
if exist "%LOCK%" (
  powershell -NoProfile -Command ^
    "$lock='logs\scrape.lock'; $age=(New-TimeSpan -Start (Get-Item -LiteralPath $lock).LastWriteTime -End (Get-Date)).TotalMinutes; if ($age -gt 15) { Remove-Item -LiteralPath $lock -Force; exit 2 } else { exit 0 }"
  if errorlevel 2 (
    echo [%DATE% %TIME%] Removed stale scrape.lock ^(older than 15m^) >> "%LOG%"
  ) else if exist "%LOCK%" (
    echo [%DATE% %TIME%] Skip: previous scrape still running >> "%LOG%"
    exit /b 2
  )
)

echo %DATE% %TIME% > "%LOCK%"
".venv\Scripts\python.exe" -m src.main %* >> "%LOG%" 2>&1
set ERR=%ERRORLEVEL%
del "%LOCK%" >nul 2>&1
exit /b %ERR%
