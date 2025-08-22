# Windows PowerShell script for ICDWrapperCpp Conan packaging
# This script packages EXISTING binaries (does not build them)

param(
    [switch]$SkipProfile = $false,
    [switch]$Publish = $false,
    [string]$Repository = "http://localhost:8081/artifactory/api/conan/local-conan"
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "ICDWrapperCpp Conan Packaging (Windows)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Verify binaries exist before packaging
Write-Host "`nVerifying existing Windows binaries..." -ForegroundColor Yellow
$buildDir = "build\Release"
$dllPath = Join-Path $buildDir "ICDWrapper.dll"
$libPath = Join-Path $buildDir "ICDWrapper.lib"

if (-not (Test-Path $dllPath)) {
    Write-Error "ICDWrapper.dll not found in $buildDir"
    Write-Host "Please ensure Windows binaries are built first:" -ForegroundColor Red
    Write-Host "  mkdir build" -ForegroundColor Red
    Write-Host "  cd build" -ForegroundColor Red
    Write-Host "  cmake .." -ForegroundColor Red
    Write-Host "  cmake --build . --config Release" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $libPath)) {
    Write-Error "ICDWrapper.lib not found in $buildDir"
    exit 1
}

Write-Host "PASSED: Found existing binaries to package" -ForegroundColor Green

# Create Conan package
Write-Host "`nCreating Conan package..." -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

$conanParams = @()
if ($SkipProfile) { $conanParams += "-SkipProfile" }
if ($Publish) { 
    $conanParams += "-Publish" 
    $conanParams += "-Repository", $Repository
}

& ".\scripts\setup_conan_package_windows.ps1" @conanParams
if ($LASTEXITCODE -ne 0) {
    Write-Error "Conan packaging failed"
    exit 1
}

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "SUCCESS: ICDWrapperCpp packaged!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan

Write-Host "`nWhat was accomplished:" -ForegroundColor Yellow
Write-Host "PASSED: Verified existing Windows binaries (ICDWrapper.dll, ICDWrapper.lib)" -ForegroundColor Green
Write-Host "PASSED: Created Conan package icdwrappercpp/1.0.0" -ForegroundColor Green
Write-Host "PASSED: Tested package integration" -ForegroundColor Green
if ($Publish) {
    Write-Host "PASSED: Published package to repository: $Repository" -ForegroundColor Green
}

Write-Host "`nPackage is ready to use in other projects!" -ForegroundColor Yellow
if ($Publish) {
    Write-Host "Other projects can now consume the package from the repository." -ForegroundColor Yellow
}
