# Build script for DDS Node.js addon on Windows (PowerShell)

Write-Host "Building DDS Node.js addon for Windows..." -ForegroundColor Green
Set-Location (Split-Path $PSScriptRoot -Parent)

# Install dependencies and build (this will also build the DDS library)
Write-Host "Installing Node.js dependencies..." -ForegroundColor Yellow
npm install

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Build successful!" -ForegroundColor Green
Write-Host ""
Write-Host "To run examples:" -ForegroundColor Yellow
Write-Host "  .\scripts\setup-env.ps1" -ForegroundColor Cyan
Write-Host "  node examples\test.js" -ForegroundColor Cyan
Write-Host "  node examples\test-domain.js" -ForegroundColor Cyan
