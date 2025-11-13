@echo off
chcp 65001 >nul
title Tasky - Stopping Application
color 0C

echo.
echo ════════════════════════════════════════════════════════
echo    🛑 STOPPING TASKY APPLICATION
echo ════════════════════════════════════════════════════════
echo.

echo Searching for running processes...
echo.

REM Kill Flutter processes
taskkill /FI "WINDOWTITLE eq Tasky Flutter App*" /T /F 2>nul
if errorlevel 1 (
    echo ⚠️  No Flutter app process found
) else (
    echo ✅ Flutter app stopped
)

REM Kill Node.js backend processes
taskkill /FI "WINDOWTITLE eq Tasky Backend API*" /T /F 2>nul
if errorlevel 1 (
    echo ⚠️  No backend process found
) else (
    echo ✅ Backend API stopped
)

REM Also kill any node/flutter processes that might be orphaned
taskkill /IM node.exe /F 2>nul
taskkill /IM dart.exe /F 2>nul

echo.
echo ════════════════════════════════════════════════════════
echo    🌸 All Tasky processes have been terminated
echo ════════════════════════════════════════════════════════
echo.
pause
