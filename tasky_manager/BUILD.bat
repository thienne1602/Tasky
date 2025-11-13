@echo off
chcp 65001 >nul
title Building Tasky Manager
color 0B

echo.
echo ════════════════════════════════════════════════════════
echo    🏗️  BUILDING TASKY MANAGER 🏗️
echo ════════════════════════════════════════════════════════
echo.

REM Check if .NET SDK is installed
dotnet --version >nul 2>&1
if errorlevel 1 (
    echo ❌ .NET SDK not found!
    echo.
    echo Please download and install .NET 6.0 SDK from:
    echo https://dotnet.microsoft.com/download/dotnet/6.0
    echo.
    pause
    exit /b 1
)

echo ✅ .NET SDK found
echo.

echo [1/3] 📦 Restoring dependencies...
dotnet restore
if errorlevel 1 (
    echo ❌ Failed to restore dependencies!
    pause
    exit /b 1
)

echo.
echo [2/3] 🔨 Building project...
dotnet build -c Release
if errorlevel 1 (
    echo ❌ Build failed!
    pause
    exit /b 1
)

echo.
echo [3/3] 📦 Publishing executable...
dotnet publish -c Release -r win-x64 --self-contained -p:PublishSingleFile=true
if errorlevel 1 (
    echo ❌ Publish failed!
    pause
    exit /b 1
)

echo.
echo ════════════════════════════════════════════════════════
echo    ✅ BUILD SUCCESSFUL! ✅
echo ════════════════════════════════════════════════════════
echo.
echo 📁 Executable location:
echo    bin\Release\net6.0-windows\win-x64\publish\TaskyManager.exe
echo.
echo 🚀 You can now run the application!
echo.

pause
