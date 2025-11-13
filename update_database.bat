@echo off
chcp 65001 >nul
echo.
echo ════════════════════════════════════════════════════════
echo    🔄 UPDATING DATABASE SCHEMA
echo ════════════════════════════════════════════════════════
echo.
echo This will:
echo  - Add user_id column to users table
echo  - Create friendships table
echo  - Generate user_id for existing users
echo.
pause

cd backend

echo Running migration...
node scripts\migrate.js
if errorlevel 1 (
    echo.
    echo ❌ Migration failed!
    pause
    exit /b 1
)

echo.
pause
