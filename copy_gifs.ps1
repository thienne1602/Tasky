# Copy GIF files from Gif sticker folder to assets/gifs with correct names
$sourceDir = "D:\project\Lập Trình Di Động\Tasky\Gif sticker"
$destDir = "D:\project\Lập Trình Di Động\Tasky\tasky_app\assets\gifs"

# Create destination directory if it doesn't exist
if (!(Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir
}

# Copy and rename GIF files
Copy-Item "$sourceDir\đăng kí.gif" "$destDir\signup.gif" -Force
Copy-Item "$sourceDir\đăng nhập.gif" "$destDir\login.gif" -Force
Copy-Item "$sourceDir\đang tải 2.gif" "$destDir\loading.gif" -Force
Copy-Item "$sourceDir\xong.gif" "$destDir\done.gif" -Force

# Copy additional GIF files for potential future use
Copy-Item "$sourceDir\đăng xuất.gif" "$destDir\logout.gif" -Force
Copy-Item "$sourceDir\đặt thành công.gif" "$destDir\success.gif" -Force
Copy-Item "$sourceDir\ketban.gif" "$destDir\friend.gif" -Force
Copy-Item "$sourceDir\vị trí.gif" "$destDir\location.gif" -Force
Copy-Item "$sourceDir\xin chào.gif" "$destDir\welcome.gif" -Force

Write-Host "GIF files copied successfully!"
