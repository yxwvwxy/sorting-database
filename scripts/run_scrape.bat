@echo off
setlocal EnableExtensions
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

echo %DATE% %TIME%> "%LOCK%"

call :run_with_retry %* >> "%LOG%" 2>&1
set ERR=%ERRORLEVEL%
del "%LOCK%" >nul 2>&1
exit /b %ERR%

:run_with_retry
echo ===== %DATE% %TIME% start =====
set ATTEMPT=1
set ERR=1

:retry_loop
if %ATTEMPT% GTR 1 (
  echo Whole-run retry %ATTEMPT%/2 after failure ^(fresh browser in 25s^)...
  powershell -NoProfile -Command "Start-Sleep -Seconds 25"
)
".venv\Scripts\python.exe" -m src.main %*
set ERR=%ERRORLEVEL%
if %ERR% EQU 0 goto retry_done
echo Run attempt %ATTEMPT%/2 failed ^(exit %ERR%^).
if %ATTEMPT% GEQ 2 goto retry_done
set /a ATTEMPT+=1
goto retry_loop

:retry_done
echo ===== %DATE% %TIME% done ^(exit %ERR%^) =====
exit /b %ERR%
