@echo off
chcp 65001 >nul
title Tasky - Starting Application
color 0A

echo.
echo ════════════════════════════════════════════════════════
echo    🌸 TASKY - TEAM TASK MANAGEMENT APP 🌸
echo ════════════════════════════════════════════════════════
echo.

REM Check if backend node_modules exists
if not exist "backend\node_modules\" (
    echo [1/4] 📦 Installing backend dependencies...
    cd backend
    call npm install
    if errorlevel 1 (
        echo ❌ Failed to install backend dependencies!
        pause
        exit /b 1
    )
    cd ..
) else (
    echo [1/4] ✅ Backend dependencies already installed
)

REM Initialize database
echo [2/4] 🗄️  Initializing MySQL database...
cd backend
call npm run db:init
if errorlevel 1 (
    echo ⚠️  Database initialization failed - make sure MySQL/Laragon is running!
    echo    Continue anyway? Press any key...
    pause >nul
)
cd ..

REM Check if Flutter dependencies are installed
cd tasky_app
echo [3/4] 📦 Getting Flutter dependencies...

REM Try to find Flutter in common locations
set FLUTTER_CMD=flutter
where flutter >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Flutter not found in PATH, checking common locations...
    if exist "D:\Setup\flutter_windows_3.35.7-stable\flutter\bin\flutter.bat" (
        set FLUTTER_CMD=D:\Setup\flutter_windows_3.35.7-stable\flutter\bin\flutter.bat
        echo ✅ Found Flutter at D:\Setup\flutter_windows_3.35.7-stable\flutter
    ) else if exist "C:\src\flutter\bin\flutter.bat" (
        set FLUTTER_CMD=C:\src\flutter\bin\flutter.bat
        echo ✅ Found Flutter at C:\src\flutter
    ) else (
        echo ❌ Flutter not found! Please install Flutter or add it to PATH.
        echo    Download from: https://flutter.dev
        cd ..
        pause
        exit /b 1
    )
)

call "%FLUTTER_CMD%" pub get
if errorlevel 1 (
    echo ❌ Failed to get Flutter dependencies!
    cd ..
    pause
    exit /b 1
)
cd ..

echo [4/4] 🚀 Starting Tasky application...
echo.
echo ════════════════════════════════════════════════════════
echo    Backend API: http://localhost:4000
echo    Flutter App: Opening in Edge browser...
echo ════════════════════════════════════════════════════════
echo.
echo 💡 Tips:
echo    - Press 'r' in Flutter terminal to hot reload
echo    - Press 'q' to quit Flutter app
echo    - Press Ctrl+C to stop backend server
echo.
echo 🔥 Starting both services now...
echo.

REM Start backend in new window
start "Tasky Backend API" cmd /k "cd /d "%~dp0backend" && color 0E && echo 🔧 Backend API Server && echo ════════════════════════════════════════ && npm run dev"

REM Wait 3 seconds for backend to start
timeout /t 3 /nobreak >nul

REM Start Flutter app in new window
start "Tasky Flutter App" cmd /k "cd /d "%~dp0tasky_app" && color 0B && echo 📱 Flutter Application && echo ════════════════════════════════════════ && "%FLUTTER_CMD%" run -d edge"

echo.
echo ✅ Both services started!
echo.
echo 📝 Two new windows have been opened:
echo    1. Backend API (yellow) - running on port 4000
echo    2. Flutter App (cyan) - running in Edge browser
echo.
echo 🛑 To stop the application:
echo    - Close both terminal windows
echo    - Or press Ctrl+C in each window
echo.
echo You can close this window now.
echo.
pause
