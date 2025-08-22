# Package script for creating ICDWrapperCpp Conan package on Windows
# This script packages existing binaries without building

# NOTE: Before running this script, manually activate the conda environment:
# conda activate conan-env

# NOTE: To publish to conan repository, manually login using:
# conan remote login -p <YOUR_TOKEN> local-conan shlomo

Write-Host "Packaging existing Windows binaries for ICDWrapperCpp..."

# Verify binaries exist
if (-not (Test-Path "build\Release\ICDWrapper.dll")) {
    Write-Error "ICDWrapper.dll not found in build\Release\"
    Write-Error "Please build the project first before packaging"
    exit 1
}

if (-not (Test-Path "build\Release\ICDWrapper.lib")) {
    Write-Error "ICDWrapper.lib not found in build\Release\"
    Write-Error "Please build the project first before packaging"
    exit 1
}

Write-Host "Found existing Windows binaries!"

Write-Host "Creating Conan package..."

# Create the package using the Windows profile
conan create . --profile=profiles/windows --build=missing
if ($LASTEXITCODE -ne 0) {
    Write-Error "Conan package creation failed"
    exit 1
}

Write-Host "ICDWrapperCpp Conan package created successfully!"
Write-Host ""
Write-Host "To use this package in another project, add to your conanfile.py:"
Write-Host "  def requirements(self):"
Write-Host "      self.requires('icdwrappercpp/1.0.0')"
Write-Host ""
Write-Host "To publish the package to your remote repository:"
Write-Host "  conan upload icdwrappercpp/1.0.0 -r=local-conan --all"
