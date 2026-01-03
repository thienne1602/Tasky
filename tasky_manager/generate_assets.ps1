$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

function New-Gif($path, $bgR, $bgG, $bgB, $text) {
  $bmp = New-Object System.Drawing.Bitmap 180,180
  $g   = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'HighQuality'
  $g.Clear([System.Drawing.Color]::FromArgb($bgR,$bgG,$bgB))
  $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
  $font  = New-Object System.Drawing.Font 'Segoe UI Semibold',24
  $sf    = New-Object System.Drawing.StringFormat
  $sf.Alignment = 'Center'
  $sf.LineAlignment = 'Center'
  $g.DrawString($text, $font, $brush, [System.Drawing.RectangleF]::new(0,0,180,180), $sf)
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Gif)
  $g.Dispose(); $bmp.Dispose(); $brush.Dispose(); $font.Dispose(); $sf.Dispose()
}

function New-BeepWav($path, $freq, $durationMs) {
  $sampleRate = 44100
  $samples    = [int]($sampleRate * $durationMs / 1000)
  $dataSize   = $samples * 2
  $fs = [System.IO.File]::Create($path)
  $bw = New-Object System.IO.BinaryWriter($fs)
  $bw.Write([System.Text.Encoding]::ASCII.GetBytes('RIFF'))
  $bw.Write([int]($dataSize + 36))
  $bw.Write([System.Text.Encoding]::ASCII.GetBytes('WAVE'))
  $bw.Write([System.Text.Encoding]::ASCII.GetBytes('fmt '))
  $bw.Write([int]16)
  $bw.Write([int16]1)
  $bw.Write([int16]1)
  $bw.Write([int]$sampleRate)
  $bw.Write([int]($sampleRate * 2))
  $bw.Write([int16]2)
  $bw.Write([int16]16)
  $bw.Write([System.Text.Encoding]::ASCII.GetBytes('data'))
  $bw.Write([int]$dataSize)
  for($i = 0; $i -lt $samples; $i++) {
    $t = 2 * [math]::PI * $freq * $i / $sampleRate
    $sample = [int16]([math]::Sin($t) * 16000)
    $bw.Write([int16]$sample)
  }
  $bw.Dispose(); $fs.Dispose()
}

$gifRoot   = 'd:\project\Lập Trình Di Động\Tasky\tasky_app\assets\gifs'
New-Gif (Join-Path $gifRoot 'signup.gif') 120 90 255 'Sign up'
New-Gif (Join-Path $gifRoot 'done.gif')   80 200 140 'Done!'
New-Gif (Join-Path $gifRoot 'login.gif')  90 140 255 'Login'
New-Gif (Join-Path $gifRoot 'loading.gif') 255 200 90 'Loading'

$audioRoot = 'd:\project\Lập Trình Di Động\Tasky\tasky_app\assets\audio'
New-BeepWav (Join-Path $audioRoot 'task_complete.wav') 880 220
New-BeepWav (Join-Path $audioRoot 'deadline.wav')      440 400
New-BeepWav (Join-Path $audioRoot 'notification.wav')  660 180
New-BeepWav (Join-Path $audioRoot 'bgm1.wav')          330 800
New-BeepWav (Join-Path $audioRoot 'bgm2.wav')          280 800
New-BeepWav (Join-Path $audioRoot 'bgm3.wav')          520 800

Write-Host 'Assets generated.'
