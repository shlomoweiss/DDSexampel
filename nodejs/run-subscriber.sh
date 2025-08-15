#!/bin/bash
# Setup environment and run subscriber

# Add DLL directories to PATH
export PATH="$PATH:/c/fastdds 3.2.2/bin/x64Win64VS2019:/c/cpp-prj/DDSexampel/DDSmessage/build/Release"

# Run subscriber
node examples/subscriber.js
