@echo off
chcp 65001 >nul
title Tasky - Quick Start (Backend Only)
color 0E

echo.
echo ════════════════════════════════════════════════════════
echo    🚀 STARTING BACKEND ONLY 🚀
echo ════════════════════════════════════════════════════════
echo.

cd backend

REM Check if node_modules exists
if not exist "node_modules\" (
    echo [1/3] 📦 Installing dependencies...
    call npm install
    if errorlevel 1 (
        echo ❌ Failed to install dependencies!
        pause
        exit /b 1
    )
) else (
    echo [1/3] ✅ Dependencies installed
)

echo [2/3] 🗄️  Initializing database...
call npm run db:init
if errorlevel 1 (
    echo ⚠️  Database init failed - make sure MySQL/Laragon is running!
    pause
)

echo [3/3] 🚀 Starting backend server...
echo.
echo ════════════════════════════════════════════════════════
echo    Backend API: http://localhost:4000
echo ════════════════════════════════════════════════════════
echo.
echo 💡 Backend is running...
echo    Press Ctrl+C to stop
echo.

call npm run dev
