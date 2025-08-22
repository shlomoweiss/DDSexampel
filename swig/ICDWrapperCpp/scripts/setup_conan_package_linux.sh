#!/bin/bash
# Linux Bash script to package ICDWrapperCpp binaries with Conan
# This script packages EXISTING binaries (does not build them)

set -e  # Exit on any error

# Initialize default values
SKIP_PROFILE=false
PUBLISH=false
REPOSITORY="http://localhost:8081/artifactory/api/conan/local-conan"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-profile)
            SKIP_PROFILE=true
            shift
            ;;
        --publish)
            PUBLISH=true
            shift
            ;;
        --repository)
            REPOSITORY="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--skip-profile] [--publish] [--repository URL]"
            exit 1
            ;;
    esac
done

echo "========================================"
echo "ICDWrapperCpp Conan Packaging (Linux)"
echo "========================================"

# Step 1: Check if Conan is available
echo ""
echo "1. Checking Conan installation..."
if command -v conan >/dev/null 2>&1; then
    CONAN_VERSION=$(conan --version)
    echo "PASSED: Conan is available: $CONAN_VERSION"
else
    echo "FAILED: Conan is not available"
    echo "Please install Conan first:"
    echo "  pip install conan"
    echo "or"
    echo "  apt install conan  # on Ubuntu/Debian"
    echo "or"
    echo "  dnf install conan  # on Fedora/RHEL"
    exit 1
fi

# Step 2: Create/update Conan profile (unless skipped)
if [ "$SKIP_PROFILE" = false ]; then
    echo ""
    echo "2. Setting up Conan profile..."
    if conan profile detect; then
        echo "PASSED: Conan profile created/updated successfully"
    else
        echo "WARNING: Conan profile setup had issues, but continuing..."
    fi
else
    echo ""
    echo "2. Skipping Conan profile setup (using existing)"
fi

# Step 4: Verify Linux binaries exist
echo ""
echo "3. Verifying Linux binaries..."
BUILD_DIR="build_linux"
SO_FILE=""

# Look for shared library files
if [ -d "$BUILD_DIR" ]; then
    SO_FILE=$(find "$BUILD_DIR" -name "libICDWrapper.so*" | head -n 1)
fi

# If not found in build_linux, check regular build directory
if [ -z "$SO_FILE" ] && [ -d "build" ]; then
    SO_FILE=$(find "build" -name "libICDWrapper.so*" | head -n 1)
    if [ -n "$SO_FILE" ]; then
        BUILD_DIR="build"
    fi
fi

if [ -z "$SO_FILE" ]; then
    echo "FAILED: libICDWrapper.so not found in build_linux/ or build/"
    echo "Please build the Linux binaries first using:"
    echo "  mkdir build_linux"
    echo "  cd build_linux"
    echo "  cmake .."
    echo "  cmake --build . --config Release"
    echo "  cd .."
    exit 1
fi

SO_SIZE=$(stat -c%s "$SO_FILE" 2>/dev/null || stat -f%z "$SO_FILE" 2>/dev/null)
echo "PASSED: Found $(basename "$SO_FILE"): $SO_SIZE bytes"

# Step 5: Create the Conan package
echo ""
echo "4. Creating Conan package..."
if conan create . --build=missing; then
    echo "PASSED: Conan package created successfully!"
else
    echo "FAILED: Failed to create Conan package"
    exit 1
fi

# Step 6: Verify package was created
echo ""
echo "5. Verifying package creation..."
if conan list "icdwrappercpp/*" >/dev/null 2>&1; then
    echo "PASSED: Package verification:"
    conan list "icdwrappercpp/*"
else
    echo "WARNING: Could not verify package list, but package creation appeared successful"
fi

echo ""
echo "========================================"
echo "SUCCESS: ICDWrapperCpp Conan package created!"
echo "========================================"

echo ""
echo "To use this package in other projects:"
echo "1. Add to conanfile.py:"
echo "   def requirements(self):"
echo "       self.requires('icdwrappercpp/1.0.0')"
echo ""
echo "2. Add to CMakeLists.txt:"
echo "   find_package(icdwrappercpp REQUIRED)"
echo "   target_link_libraries(your_target icdwrappercpp::icdwrappercpp)"

echo ""
echo "Package Details:"
conan list "icdwrappercpp/1.0.0:*" || echo "Could not display package details"

# Step 7: Publish to repository (if requested)
if [ "$PUBLISH" = true ]; then
    echo ""
    echo "6. Publishing to Conan repository..."
    echo "Repository: $REPOSITORY"
    
    # Important authentication notice
    echo ""
    echo "IMPORTANT: Ensure you are logged in to the repository!"
    echo "If not logged in, run this command manually first:"
    echo "conan remote login -p <token> local-conan <username>"
    echo ""
    
    # Add the remote repository if not already added
    echo "Adding/updating remote repository..."
    if conan remote add local-artifactory "$REPOSITORY" --force; then
        echo "PASSED: Remote repository configured"
    else
        echo "WARNING: Failed to add remote repository, but continuing..."
    fi
    
    # Upload the package
    echo "Uploading package to repository..."
    if conan upload "icdwrappercpp/1.0.0" --remote=local-artifactory --confirm; then
        echo "PASSED: Package published successfully to $REPOSITORY"
    else
        echo "FAILED: Failed to publish package to repository"
        echo "This might be due to authentication issues."
        echo "Please ensure you are logged in with:"
        echo "conan remote login -p <token> local-conan <username>"
        exit 1
    fi
else
    echo ""
    echo "6. Skipping publish step (use --publish to upload to repository)"
fi
