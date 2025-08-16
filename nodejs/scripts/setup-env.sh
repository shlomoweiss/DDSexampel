#!/bin/bash
# Setup DDS Node.js addon environment for Linux


echo "Setting up DDS Node.js addon environment for Linux..."

# Set library path for FastDDS and DDS facade
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/lib:$(pwd)/dds-src/build"

echo "Environment setup complete!"
echo "You can now run:"
echo "  node examples/test.js       - Run comprehensive test"
echo "  node examples/publisher.js  - Run publisher example"
echo "  node examples/subscriber.js - Run subscriber example"
echo ""
echo "To make these environment variables persistent, add this to your ~/.bashrc:"
echo "export LD_LIBRARY_PATH=\"\${LD_LIBRARY_PATH}:/usr/local/lib:$(pwd)/../DDSmessage/build\""
