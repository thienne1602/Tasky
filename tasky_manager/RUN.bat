@echo off
chcp 65001 >nul
title Tasky Manager
color 0E

REM Check if published executable exists
if exist "bin\Release\net6.0-windows\win-x64\publish\TaskyManager.exe" (
    echo Starting Tasky Manager...
    start "" "bin\Release\net6.0-windows\win-x64\publish\TaskyManager.exe"
    exit
)

REM Otherwise run with dotnet
echo Published executable not found. Running with dotnet...
dotnet run
