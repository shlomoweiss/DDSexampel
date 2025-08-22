# Cross-platform native library extraction script
Write-Host "Extracting native libraries for cross-platform NuGet package..." -ForegroundColor Green

# Clean up
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "runtimes", "win", "linux", "temp_*"

# Create runtime structure
New-Item -ItemType Directory -Force -Path "runtimes/win-x64/native" | Out-Null
New-Item -ItemType Directory -Force -Path "runtimes/linux-x64/native" | Out-Null

Write-Host "Installing and extracting Windows libraries..." -ForegroundColor Cyan

# Install Windows packages
conan install . --build=missing --remote=local-conan --settings os=Windows --output-folder=temp_win

if ($LASTEXITCODE -eq 0) {
    # Find Windows DLLs in Conan cache and copy them
    $winPackages = conan cache path icdwrappercpp/1.0.0 2>$null
    if ($winPackages) {
        $dllFiles = Get-ChildItem -Path "$winPackages*" -Recurse -Include "*.dll" -ErrorAction SilentlyContinue
        foreach ($dll in $dllFiles) {
            Copy-Item $dll.FullName -Destination "runtimes/win-x64/native/" -Force
            Write-Host "  Copied: $($dll.Name)" -ForegroundColor Gray
        }
    }
}

Write-Host "Installing and extracting Linux libraries..." -ForegroundColor Cyan

# Install Linux packages  
conan install . --build=missing --remote=local-conan --settings os=Linux --output-folder=temp_linux

if ($LASTEXITCODE -eq 0) {
    # Find Linux .so files in Conan cache and copy them
    $linuxPackages = conan cache path icdwrappercpp/1.0.0 2>$null
    if ($linuxPackages) {
        $soFiles = Get-ChildItem -Path "$linuxPackages*" -Recurse -Include "*.so*" -ErrorAction SilentlyContinue
        foreach ($so in $soFiles) {
            Copy-Item $so.FullName -Destination "runtimes/linux-x64/native/" -Force
            Write-Host "  Copied: $($so.Name)" -ForegroundColor Gray
        }
    }
}

# Also handle ddsmessage package
Write-Host "Extracting ddsmessage libraries..." -ForegroundColor Cyan
$ddsPath = conan cache path ddsmessage/1.0.0 2>$null
if ($ddsPath) {
    $ddsFiles = Get-ChildItem -Path "$ddsPath*" -Recurse -Include "*.dll", "*.so*" -ErrorAction SilentlyContinue
    foreach ($file in $ddsFiles) {
        if ($file.Extension -eq ".dll") {
            Copy-Item $file.FullName -Destination "runtimes/win-x64/native/" -Force
            Write-Host "  Copied DDS: $($file.Name)" -ForegroundColor Gray
        } elseif ($file.Extension -like ".so*") {
            Copy-Item $file.FullName -Destination "runtimes/linux-x64/native/" -Force  
            Write-Host "  Copied DDS: $($file.Name)" -ForegroundColor Gray
        }
    }
}

# Clean up temp folders
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "temp_*"

# Copy Windows DLLs to bin folders for development
if (Test-Path "runtimes/win-x64/native") {
    New-Item -ItemType Directory -Force -Path "bin/Debug/net9.0", "bin/Release/net9.0" | Out-Null
    Copy-Item "runtimes/win-x64/native/*.dll" -Destination "bin/Debug/net9.0/" -Force -ErrorAction SilentlyContinue
    Copy-Item "runtimes/win-x64/native/*.dll" -Destination "bin/Release/net9.0/" -Force -ErrorAction SilentlyContinue
}

# Show results
Write-Host "Runtime structure created:" -ForegroundColor Green
if (Test-Path "runtimes") {
    Get-ChildItem -Path "runtimes" -Recurse | Format-Table Name, Length -AutoSize
} else {
    Write-Host "No runtime folders created" -ForegroundColor Red
}

Write-Host "Cross-platform native library extraction completed!" -ForegroundColor Green
