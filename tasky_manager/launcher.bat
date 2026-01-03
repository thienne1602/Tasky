@echo off
setlocal
chcp 65001 >nul

rem Resolve project root (one level up from this script)
set "THIS_DIR=%~dp0"
pushd "%THIS_DIR%.."
set "PROJECT_ROOT=%CD%"
popd
set "LINK=D:\Tasky"

rem Create junction to avoid Unicode-path issues
if not exist "%LINK%" (
    echo [INFO] Creating junction %LINK% -> %PROJECT_ROOT%
    mklink /J "%LINK%" "%PROJECT_ROOT%"
)

echo [1/2] Starting backend...
start "Tasky Backend" cmd /k "cd /d %LINK%\backend && npm start"

echo [INFO] Waiting 5 seconds for backend...
timeout /t 5 /nobreak >nul

echo [2/2] Starting Flutter app...
start "Tasky Flutter" cmd /k "cd /d %LINK%\tasky_app && flutter run"

echo.
echo Launcher done. You can close this window.
pause >nul
endlocal
