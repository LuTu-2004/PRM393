# Mounts the Flutter SDK and this project on space-free drive letters, working
# around the Flutter native-assets bug with spaces in paths.
# Run once after each reboot:  powershell -ExecutionPolicy Bypass -File tool\dev_drives.ps1
$sdk = "D:\hoc tap\software code\flutter_windows_3.47.5-stable"
$project = Split-Path -Parent $PSScriptRoot

if (-not (Test-Path "X:\")) { subst X: $sdk }
if (-not (Test-Path "Y:\")) { subst Y: $project }
subst
Write-Host "Mo VS Code tai Y:\  ->  code Y:\"
