# Build script for DDS Node.js addon on Windows (PowerShell)

Write-Host "Building DDS Node.js addon for Windows..." -ForegroundColor Green
Set-Location $PSScriptRoot

# Check if DDS library exists
if (-not (Test-Path "..\DDSmessage\build\Release\ICD.lib")) {
    Write-Host "Error: DDS library not found at ..\DDSmessage\build\Release\ICD.lib" -ForegroundColor Red
    Write-Host "Please build the DDS library first using Visual Studio:" -ForegroundColor Yellow
    Write-Host "  1. Open DDSmessage\build\icd_library.sln" -ForegroundColor Cyan
    Write-Host "  2. Build in Release configuration" -ForegroundColor Cyan
    exit 1
}

# Install dependencies and build
Write-Host "Installing Node.js dependencies..." -ForegroundColor Yellow
npm install

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Build successful!" -ForegroundColor Green
Write-Host ""
Write-Host "To run examples:" -ForegroundColor Yellow
Write-Host "  .\setup-env.ps1" -ForegroundColor Cyan
Write-Host "  node examples\test.js" -ForegroundColor Cyan
Write-Host "  node examples\test-domain.js" -ForegroundColor Cyan
