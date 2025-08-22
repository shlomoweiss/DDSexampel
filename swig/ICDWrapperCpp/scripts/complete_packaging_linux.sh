#!/bin/bash
# Linux Bash script for ICDWrapperCpp Conan packaging
# This script packages EXISTING binaries (does not build them)

set -e  # Exit on any error

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
        -h|--help)
            echo "Usage: $0 [--skip-profile] [--publish] [--repository URL]"
            echo "Options:"
            echo "  --skip-profile       Skip Conan profile setup"
            echo "  --publish            Publish package to repository after creation"
            echo "  --repository URL     Repository URL (default: http://localhost:8081/artifactory/api/conan/local-conan)"
            echo "  -h, --help           Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "=========================================="
echo "ICDWrapperCpp Conan Packaging (Linux)"
echo "=========================================="

# Verify binaries exist before packaging
echo ""
echo "Verifying existing Linux binaries..."
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
    echo "❌ libICDWrapper.so not found in build_linux/ or build/"
    echo "Please ensure Linux binaries are built first:"
    echo "  mkdir build_linux"
    echo "  cd build_linux"
    echo "  cmake .."
    echo "  cmake --build . --config Release"
    echo "  cd .."
    exit 1
fi

echo "PASSED: Found existing binaries to package"

# Create Conan package
echo ""
echo "Creating Conan package..."
echo "========================================"

CONAN_PARAMS=""
if [ "$SKIP_PROFILE" = true ]; then
    CONAN_PARAMS="$CONAN_PARAMS --skip-profile"
fi
if [ "$PUBLISH" = true ]; then
    CONAN_PARAMS="$CONAN_PARAMS --publish --repository $REPOSITORY"
fi

./scripts/setup_conan_package_linux.sh $CONAN_PARAMS

echo ""
echo "=========================================="
echo "SUCCESS: ICDWrapperCpp packaged!"
echo "=========================================="

echo ""
echo "What was accomplished:"
echo "PASSED: Verified existing Linux binaries (libICDWrapper.so)"
echo "PASSED: Created Conan package icdwrappercpp/1.0.0"
echo "PASSED: Tested package integration"
if [ "$PUBLISH" = true ]; then
    echo "PASSED: Published package to repository: $REPOSITORY"
fi

echo ""
echo "Package is ready to use in other projects!"
if [ "$PUBLISH" = true ]; then
    echo "Other projects can now consume the package from the repository."
fi
