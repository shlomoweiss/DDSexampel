# Setup DDS Node.js addon environment

# Change to the nodejs directory
Set-Location "C:\cpp-prj\DDSexampel\nodejs"

Write-Host "Setting up DDS Node.js addon environment..." -ForegroundColor Green

# Add FastDDS DLLs to PATH
$env:PATH += ";C:\fastdds 3.2.2\bin\x64Win64VS2019"

# Add DDS facade DLL to PATH  
$env:PATH += ";C:\cpp-prj\DDSexampel\DDSmessage\build\Release"

Write-Host "Environment setup complete!" -ForegroundColor Green
Write-Host "You can now run:" -ForegroundColor Yellow
Write-Host "  node examples/test.js       - Run comprehensive test" -ForegroundColor Cyan
Write-Host "  node examples/publisher.js  - Run publisher example" -ForegroundColor Cyan
Write-Host "  node examples/subscriber.js - Run subscriber example" -ForegroundColor Cyan
Write-Host ""
