#!/bin/bash
# Package script for creating ICDWrapperCpp Conan package on Linux
# This script packages existing binaries without building

# NOTE: Before running this script, manually activate the conda environment:
# conda activate conan-env

# NOTE: To publish to conan repository, manually login using:
# conan remote login -p <YOUR_TOKEN> local-conan shlomo

echo "Packaging existing Linux binaries for ICDWrapperCpp..."

# Verify binaries exist
if [ ! -f "build_linux/libICDWrapper.so" ]; then
    echo "libICDWrapper.so not found in build_linux/"
    echo "Please build the project first before packaging"
    exit 1
fi

echo "Found existing Linux binaries!"

echo "Creating Conan package..."

# Create the package using the Linux profile
conan create . --profile=profiles/linux --build=missing
if [ $? -ne 0 ]; then
    echo "Conan package creation failed"
    exit 1
fi

echo "ICDWrapperCpp Conan package created successfully!"
echo ""
echo "To use this package in another project, add to your conanfile.py:"
echo "  def requirements(self):"
echo "      self.requires('icdwrappercpp/1.0.0')"
echo ""
echo "To publish the package to your remote repository:"
echo "  conan upload icdwrappercpp/1.0.0 -r=local-conan --all"
