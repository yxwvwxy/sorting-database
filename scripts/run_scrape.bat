@echo off
setlocal EnableExtensions
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
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-ddTHH:mm"') do set SLOT=%%i
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format mm"') do set SLOT_MIN=%%i
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

echo %DATE% %TIME%> "%LOCK%"

REM No labels: cmd.exe misses :labels when this file is saved with LF endings.
echo ===== %DATE% %TIME% start =====>> "%LOG%"
".venv\Scripts\python.exe" -m src.main --chutes-only %* >> "%LOG%" 2>&1
set ERR=%ERRORLEVEL%
if not %ERR%==0 echo Run attempt 1/2 failed ^(exit %ERR%^).>> "%LOG%"
if not %ERR%==0 echo Whole-run retry 2/2 after failure ^(fresh browser in 25s^)...>> "%LOG%"
if not %ERR%==0 powershell -NoProfile -Command "Start-Sleep -Seconds 25"
if not %ERR%==0 ".venv\Scripts\python.exe" -m src.main --chutes-only %* >> "%LOG%" 2>&1
if not %ERR%==0 set ERR=%ERRORLEVEL%
echo ===== %DATE% %TIME% done ^(exit %ERR%^) =====>> "%LOG%"

del "%LOCK%" >nul 2>&1

REM Bundle export follows a finished :10 chute run in its own process.
REM A chute failure still reaches this point. A bundle failure does not change ERR.
if %SLOT_MIN% GEQ 10 if %SLOT_MIN% LSS 30 (
  echo [%DATE% %TIME%] Bundle export after chute exit %ERR% slot %SLOT% >> "%LOG%"
  ".venv\Scripts\python.exe" -m src.bundle_export --slot %SLOT% >> "logs\bundle-%DAY%.log" 2>&1
  echo [%DATE% %TIME%] Bundle export exit %ERRORLEVEL% >> "%LOG%"
)

exit /b %ERR%
