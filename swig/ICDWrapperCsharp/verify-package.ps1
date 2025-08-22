# Verify ICDWrapperSharp NuGet Package
# This script verifies the contents and structure of the created NuGet package

param(
    [string]$PackagePath = "ICDWrapperSharp.1.0.0.nupkg"
)

Write-Host "Verifying ICDWrapperSharp NuGet Package..." -ForegroundColor Green

if (-not (Test-Path $PackagePath)) {
    Write-Host "Error: Package file not found: $PackagePath" -ForegroundColor Red
    exit 1
}

# Extract package for verification
$TempDir = "temp_verification"
$ZipPath = $PackagePath -replace "\.nupkg$", ".zip"
Copy-Item $PackagePath $ZipPath -Force
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force

Write-Host "Package Contents:" -ForegroundColor Yellow

# Check managed DLL
$ManagedDll = Join-Path $TempDir "lib\net9.0\ICDWrapperSharp.dll"
if (Test-Path $ManagedDll) {
    $ManagedSize = (Get-Item $ManagedDll).Length
    Write-Host "  ✅ Managed DLL: lib/net9.0/ICDWrapperSharp.dll ($ManagedSize bytes)" -ForegroundColor Green
} else {
    Write-Host "  ❌ Managed DLL: MISSING" -ForegroundColor Red
}

# Check native DLL
$NativeDll = Join-Path $TempDir "runtimes\win-x64\native\ICDWrapper.dll"
if (Test-Path $NativeDll) {
    $NativeSize = (Get-Item $NativeDll).Length
    Write-Host "  ✅ Native DLL: runtimes/win-x64/native/ICDWrapper.dll ($NativeSize bytes)" -ForegroundColor Green
} else {
    Write-Host "  ❌ Native DLL: MISSING" -ForegroundColor Red
}

# Check nuspec file
$NuspecFile = Join-Path $TempDir "ICDWrapperSharp.nuspec"
if (Test-Path $NuspecFile) {
    Write-Host "  ✅ Package metadata: ICDWrapperSharp.nuspec" -ForegroundColor Green
    $Content = Get-Content $NuspecFile
    $Version = ($Content | Select-String "<version>").ToString().Trim()
    $Id = ($Content | Select-String "<id>").ToString().Trim()
    Write-Host "    $Id" -ForegroundColor Cyan
    Write-Host "    $Version" -ForegroundColor Cyan
} else {
    Write-Host "  ❌ Package metadata: MISSING" -ForegroundColor Red
}

# Package size
$PackageSize = (Get-Item $PackagePath).Length
Write-Host "  📦 Total package size: $PackageSize bytes" -ForegroundColor Cyan

# Cleanup
Remove-Item -Path $TempDir -Recurse -Force
Remove-Item -Path $ZipPath -Force

Write-Host "Verification complete!" -ForegroundColor Green

Write-Host "`nTo install this package in a project:" -ForegroundColor Yellow
Write-Host "  1. Copy the .nupkg file to your local package source" -ForegroundColor White
Write-Host "  2. Add local package source: nuget sources add -name Local -source C:\path\to\package\folder" -ForegroundColor White
Write-Host "  3. Install package: dotnet add package ICDWrapperSharp --source Local" -ForegroundColor White
