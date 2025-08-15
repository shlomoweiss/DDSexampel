#!/bin/bash
# Build Node.js addon for Linux

# Change to nodejs directory
cd "$(dirname "$0")"

echo "Building Node.js DDS addon for Linux..."

# Make sure the DDS library is built first
if [ ! -f "../DDSmessage/build/libICD.so" ]; then
    echo "DDS library not found. Building it first..."
    cd ../DDSmessage
    ./build-linux.sh
    cd ../nodejs
fi

# Install Node.js dependencies
echo "Installing Node.js dependencies..."
npm install

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo ""
    echo "To run examples:"
    echo "1. Source environment: source setup-env.sh"
    echo "2. Run test: node examples/test.js"
    echo "3. Run publisher: ./run-publisher.sh TestTopic"
    echo "4. Run subscriber: ./run-subscriber.sh"
else
    echo "Build failed!"
    exit 1
fi
