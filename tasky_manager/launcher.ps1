param(
    [switch] $SkipLink
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Resolve project root (one level up from this script)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
$link = 'D:\Tasky'

function Ensure-Link {
    if ($SkipLink) { return }
    if (-not (Test-Path $link)) {
        cmd /c "mklink /J \"$link\" \"$projectRoot\"" | Out-Null
    }
}

function Start-Backend {
    Ensure-Link
    Start-Process cmd -ArgumentList '/k', "cd /d $link\backend && npm start" -WindowStyle Normal -WorkingDirectory "$link\backend"
}

function Start-App {
    Ensure-Link
    Start-Process cmd -ArgumentList '/k', "cd /d $link\tasky_app && flutter run" -WindowStyle Normal -WorkingDirectory "$link\tasky_app"
}

function Start-All {
    Start-Backend
    Start-Sleep -Seconds 2
    Start-App
}

# UI
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Tasky Launcher'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(360,220)
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

$label = New-Object System.Windows.Forms.Label
$label.Text = "Project root: $projectRoot`nLink: $link"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(15,15)
$form.Controls.Add($label)

function New-Button($text,$x,$y,$onClick){
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Size = New-Object System.Drawing.Size(140,35)
    $btn.Location = New-Object System.Drawing.Point($x,$y)
    $btn.Add_Click($onClick)
    $form.Controls.Add($btn)
}

New-Button 'Start Backend' 15 70 { Start-Backend }
New-Button 'Start Flutter' 185 70 { Start-App }
New-Button 'Start Both' 15 120 { Start-All }
New-Button 'Open Folder' 185 120 { Start-Process explorer.exe $projectRoot }

[System.Windows.Forms.Application]::EnableVisualStyles()
$form.Topmost = $true
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
