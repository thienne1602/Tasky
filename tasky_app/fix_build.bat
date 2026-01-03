@echo off
echo Fixing Flutter build issues...
echo.

echo Step 1: Cleaning Flutter cache...
flutter clean
if %errorlevel% neq 0 (
    echo Error during flutter clean
    pause
    exit /b 1
)

echo.
echo Step 2: Removing build directories...
if exist build rmdir /s /q build
if exist android\app\build rmdir /s /q android\app\build
if exist android\build rmdir /s /q android\build

echo.
echo Step 3: Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo Error during flutter pub get
    pause
    exit /b 1
)

echo.
echo Step 4: Running flutter doctor...
flutter doctor

echo.
echo Build cache cleared! Try running 'flutter run' now.
pause
