#!/bin/bash
# Setup environment and run subscriber on Linux

# Change to the nodejs directory
cd "$(dirname "$0")"

# Add library directories to LD_LIBRARY_PATH
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/lib:$(pwd)/../DDSmessage/build"

# Set DDS domain ID if provided
if [ -n "$1" ]; then
    export DDS_DOMAIN_ID="$1"
fi

# Run subscriber with remaining arguments
shift
node examples/subscriber.js "$@"
