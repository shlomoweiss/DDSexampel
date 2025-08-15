# Setup environment and run publisher

# Change to the nodejs directory
Set-Location "C:\cpp-prj\DDSexampel\nodejs"

# Add DLL directories to PATH
$env:PATH += ";C:\fastdds 3.2.2\bin\x64Win64VS2019"
$env:PATH += ";C:\cpp-prj\DDSexampel\DDSmessage\build\Release"

Write-Host "Starting DDS Publisher..." -ForegroundColor Green
node examples/publisher.js
