# Complete NuGet Package Creation and Publishing Script
# This script: extracts native libraries, builds, packages, and publishes to NuGet server

param(
    [string]$Version,
    [string]$Configuration = "Release",
    [string]$NuGetServer = "http://localhost:5555/",
    [string]$ApiKey = "123456",
    [switch]$SkipExtraction,
    [switch]$SkipPublish
)

Write-Host "ICDWrapperSharp Complete NuGet Package Creation and Publishing" -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Green

# Set the script location as the working directory
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptPath

# Step 1: Extract Native Libraries (unless skipped)
if (-not $SkipExtraction) {
    Write-Host "`n1. Extracting native libraries from Conan packages..." -ForegroundColor Cyan
    
    if (Test-Path "extract-native-libs.ps1") {
        .\extract-native-libs.ps1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to extract native libraries!" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Warning: extract-native-libs.ps1 not found. Proceeding without native library extraction." -ForegroundColor Yellow
    }
} else {
    Write-Host "`n1. Skipping native library extraction..." -ForegroundColor Yellow
}

# Step 2: Update version if provided
if ($Version) {
    Write-Host "`n2. Updating version to $Version..." -ForegroundColor Cyan
    $csprojContent = Get-Content "ICDWrapperSharp.csproj"
    $csprojContent = $csprojContent -replace '<PackageVersion>[\d\.]+</PackageVersion>', "<PackageVersion>$Version</PackageVersion>"
    Set-Content "ICDWrapperSharp.csproj" $csprojContent
    Write-Host "Version updated successfully!" -ForegroundColor Green
} else {
    Write-Host "`n2. Using existing version from project file..." -ForegroundColor Cyan
    # Extract current version
    $csprojContent = Get-Content "ICDWrapperSharp.csproj"
    $versionLine = $csprojContent | Where-Object { $_ -match '<PackageVersion>(.*)</PackageVersion>' }
    if ($versionLine) {
        $Version = $Matches[1]
        Write-Host "Current version: $Version" -ForegroundColor Green
    } else {
        $Version = "1.0.0"
        Write-Host "No version found, defaulting to: $Version" -ForegroundColor Yellow
    }
}

# Step 3: Clean previous builds
Write-Host "`n3. Cleaning previous builds..." -ForegroundColor Cyan
Remove-Item -Path "bin", "obj" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "*.nupkg", "*.snupkg" -Force -ErrorAction SilentlyContinue
Write-Host "Previous builds cleaned!" -ForegroundColor Green

# Step 4: Build the project
Write-Host "`n4. Building C# project..." -ForegroundColor Cyan
dotnet build -c $Configuration
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "Build completed successfully!" -ForegroundColor Green

# Step 5: Create NuGet package
Write-Host "`n5. Creating NuGet package..." -ForegroundColor Cyan
dotnet pack -c $Configuration -o . --no-build

if ($LASTEXITCODE -eq 0) {
    $packageFile = Get-ChildItem -Filter "*.nupkg" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    Write-Host "NuGet package created successfully!" -ForegroundColor Green
    Write-Host "Package file: $($packageFile.Name)" -ForegroundColor White
    Write-Host "Package size: $([math]::Round($packageFile.Length / 1KB, 2)) KB" -ForegroundColor White
    
    # Show package contents
    Write-Host "`nPackage structure:" -ForegroundColor Cyan
    $tempZip = $packageFile.Name -replace "\.nupkg$", ".zip"
    Copy-Item $packageFile.FullName $tempZip -Force
    
    try {
        $tempExtract = "temp_extract_$([System.Guid]::NewGuid().ToString('N')[0..7] -join '')"
        Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force
        
        Write-Host "  Package contents:" -ForegroundColor Yellow
        Get-ChildItem -Path $tempExtract -Recurse -File | ForEach-Object {
            $relativePath = $_.FullName.Substring($tempExtract.Length + 1)
            $sizeKB = [math]::Round($_.Length / 1KB, 1)
            Write-Host "    $relativePath ($sizeKB KB)" -ForegroundColor Gray
        }
        
        # Cleanup
        Remove-Item -Path $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "    Could not extract package for content verification" -ForegroundColor Yellow
    }
    
    Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "Package creation failed!" -ForegroundColor Red
    exit 1
}

# Step 6: Publish to NuGet server (unless skipped)
if (-not $SkipPublish) {
    Write-Host "`n6. Publishing to NuGet server..." -ForegroundColor Cyan
    Write-Host "Server: $NuGetServer" -ForegroundColor White
    
    $publishCommand = "dotnet nuget push -s `"$NuGetServer`" -k `"$ApiKey`" --skip-duplicate --force-english-output `"$($packageFile.FullName)`""
    Write-Host "Command: $publishCommand" -ForegroundColor Gray
    
    Invoke-Expression $publishCommand
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Package published successfully!" -ForegroundColor Green
    } else {
        Write-Host "Package publishing failed (exit code: $LASTEXITCODE)" -ForegroundColor Red
        Write-Host "This might be expected if the package already exists and --skip-duplicate was used" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n6. Skipping NuGet publishing..." -ForegroundColor Yellow
    Write-Host "To publish manually, run:" -ForegroundColor White
    Write-Host "dotnet nuget push -s `"$NuGetServer`" -k `"$ApiKey`" `"$($packageFile.FullName)`"" -ForegroundColor Gray
}

Write-Host "`n=============================================================" -ForegroundColor Green
Write-Host "Complete! Package: $($packageFile.Name)" -ForegroundColor Green
if (-not $SkipPublish) {
    Write-Host "Published to: $NuGetServer" -ForegroundColor Green
}
Write-Host "=============================================================" -ForegroundColor Green
