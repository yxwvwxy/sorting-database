@echo off
setlocal
cd /d "%~dp0.."

if not exist ".venv\Scripts\python.exe" (
  echo Missing .venv. Run scripts\setup_windows.ps1 first.
  exit /b 1
)

if not exist "logs" mkdir logs

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd"') do set DAY=%%i
set LOG=logs\scrape-%DAY%.log
set LOCK=logs\scrape.lock

if exist "%LOCK%" (
  echo [%DATE% %TIME%] Skip: previous scrape still running >> "%LOG%"
  exit /b 0
)

echo %DATE% %TIME% > "%LOCK%"
".venv\Scripts\python.exe" -m src.main %* >> "%LOG%" 2>&1
set ERR=%ERRORLEVEL%
del "%LOCK%" >nul 2>&1
exit /b %ERR%
