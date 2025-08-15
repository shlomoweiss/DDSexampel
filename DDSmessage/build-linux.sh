#!/bin/bash
# Build script for DDS library on Linux

# Change to DDSmessage directory
cd "$(dirname "$0")"

echo "Building DDS library for Linux..."

# Create build directory if it doesn't exist
mkdir -p build
cd build

# Configure with CMake
echo "Configuring with CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Release

# Build the project
echo "Building the project..."
make -j$(nproc)

if [ $? -eq 0 ]; then
    echo "Build successful! Library created at: $(pwd)/libICD.so"
    echo ""
    echo "Next steps:"
    echo "1. Install FastDDS dependencies if not already installed"
    echo "2. Set LD_LIBRARY_PATH to include this directory and FastDDS libraries"
    echo "3. Build Node.js addon with: cd ../nodejs && npm install"
else
    echo "Build failed!"
    exit 1
fi
