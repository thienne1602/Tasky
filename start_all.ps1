# Start both backend and Flutter app
Write-Host "🚀 Starting Tasky App & Backend..." -ForegroundColor Green

# Start backend in background
Write-Host "📡 Starting backend server..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-Command cd 'backend'; npm run dev" -NoNewWindow

# Wait for backend to initialize
Write-Host "⏳ Waiting for backend to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Start Flutter app
Write-Host "📱 Starting Flutter app..." -ForegroundColor Blue
flutter run --debug
