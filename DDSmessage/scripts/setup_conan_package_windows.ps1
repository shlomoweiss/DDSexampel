# Windows PowerShell script to package DDSmessage binaries with Conan
# This script packages EXISTING binaries (does not build them)

param(
    [switch]$SkipProfile = $false,
    [switch]$Publish = $false,
    [string]$Repository = "http://localhost:8081/artifactory/api/conan/local-conan"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DDSmessage Conan Packaging (Windows)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NOTE: Make sure conda-env environment is activated before running this script" -ForegroundColor Yellow

# Step 1: Check if Conan is available
Write-Host "`n1. Checking Conan installation..." -ForegroundColor Yellow
try {
    $conanVersion = conan --version
    if ($LASTEXITCODE -eq 0) {
        Write-Host "PASSED: Conan is available: $conanVersion" -ForegroundColor Green
    } else {
        Write-Error "Conan is not available in conda-env environment"
        exit 1
    }
} catch {
    Write-Error "Error checking Conan: $_"
    exit 1
}

# Step 2: Create/update Conan profile (unless skipped)
if (-not $SkipProfile) {
    Write-Host "`n2. Setting up Conan profile..." -ForegroundColor Yellow
    try {
        conan profile detect
        if ($LASTEXITCODE -eq 0) {
            Write-Host "PASSED: Conan profile created/updated successfully" -ForegroundColor Green
        } else {
            Write-Warning "Conan profile setup had issues, but continuing..."
        }
    } catch {
        Write-Warning "Error setting up Conan profile: $_"
        Write-Host "Continuing with existing profile..." -ForegroundColor Yellow
    }
} else {
    Write-Host "`n2. Skipping Conan profile setup (using existing)" -ForegroundColor Yellow
}

# Step 3: Verify Windows binaries exist
Write-Host "`n3. Verifying Windows binaries..." -ForegroundColor Yellow
$buildDir = "build\Release"
$dllPath = Join-Path $buildDir "ICD.dll"
$libPath = Join-Path $buildDir "ICD.lib"

if (-not (Test-Path $dllPath)) {
    Write-Error "ICD.dll not found in $buildDir"
    Write-Host "Please build the Windows binaries first using:" -ForegroundColor Red
    Write-Host "  mkdir build" -ForegroundColor Red
    Write-Host "  cd build" -ForegroundColor Red
    Write-Host "  cmake .." -ForegroundColor Red
    Write-Host "  cmake --build . --config Release" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $libPath)) {
    Write-Error "ICD.lib not found in $buildDir"
    exit 1
}

Write-Host "PASSED: Found ICD.dll: $(Get-Item $dllPath | Select-Object -ExpandProperty Length) bytes" -ForegroundColor Green
Write-Host "PASSED: Found ICD.lib: $(Get-Item $libPath | Select-Object -ExpandProperty Length) bytes" -ForegroundColor Green

# Step 4: Create the Conan package
Write-Host "`n4. Creating Conan package..." -ForegroundColor Yellow
try {
    conan create . --build=missing
    if ($LASTEXITCODE -eq 0) {
        Write-Host "PASSED: Conan package created successfully!" -ForegroundColor Green
    } else {
        Write-Error "Failed to create Conan package"
        exit 1
    }
} catch {
    Write-Error "Error creating Conan package: $_"
    exit 1
}

# Step 5: Verify package was created
Write-Host "`n5. Verifying package creation..." -ForegroundColor Yellow
try {
    $packageList = conan list "ddsmessage/*"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "PASSED: Package verification:" -ForegroundColor Green
        Write-Host "$packageList" -ForegroundColor Gray
    }
} catch {
    Write-Warning "Could not verify package list, but package creation appeared successful"
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "SUCCESS: DDSmessage Conan package created!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nTo use this package in other projects:" -ForegroundColor Yellow
Write-Host "1. Add to conanfile.py:" -ForegroundColor White
Write-Host "   def requirements(self):" -ForegroundColor Gray
Write-Host "       self.requires('ddsmessage/1.0.0')" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Add to CMakeLists.txt:" -ForegroundColor White
Write-Host "   find_package(ddsmessage REQUIRED)" -ForegroundColor Gray
Write-Host "   target_link_libraries(your_target ddsmessage::ddsmessage)" -ForegroundColor Gray

Write-Host "`nPackage Details:" -ForegroundColor Yellow
try {
    conan list "ddsmessage/1.0.0:*"
} catch {
    Write-Host "Could not display package details" -ForegroundColor Red
}

# Step 6: Publish to repository (if requested)
if ($Publish) {
    Write-Host "`n7. Publishing to Conan repository..." -ForegroundColor Yellow
    Write-Host "Repository: $Repository" -ForegroundColor Gray
    
    # Important authentication notice
    Write-Host "`nIMPORTANT: Ensure you are logged in to the repository!" -ForegroundColor Red
    Write-Host "If not logged in, run this command manually first:" -ForegroundColor Red
    Write-Host "conan remote login -p <token> local-conan <username>" -ForegroundColor Gray
    Write-Host ""
    
    try {
        # Add the remote repository if not already added
        Write-Host "Adding/updating remote repository..." -ForegroundColor Gray
        conan remote add local-conan $Repository --force
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to add remote repository, but continuing..."
        } else {
            Write-Host "PASSED: Remote repository configured" -ForegroundColor Green
        }
        
        # Upload the package
        Write-Host "Uploading package to repository..." -ForegroundColor Gray
        conan upload "ddsmessage/1.0.0" --remote=local-conan --confirm
        if ($LASTEXITCODE -eq 0) {
            Write-Host "PASSED: Package published successfully to $Repository" -ForegroundColor Green
        } else {
            Write-Error "Failed to publish package to repository"
            Write-Host "This might be due to authentication issues." -ForegroundColor Red
            Write-Host "Please ensure you are logged in with:" -ForegroundColor Red
            Write-Host "conan remote login -p <token> local-conan <username>" -ForegroundColor Gray
            exit 1
        }
    } catch {
        Write-Error "Error publishing package: $_"
        Write-Host "Please check your authentication and repository configuration." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "`n7. Skipping publish step (use -Publish to upload to repository)" -ForegroundColor Yellow
}
