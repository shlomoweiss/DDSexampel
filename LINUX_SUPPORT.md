# Linux Support for DDS Project

This document describes how to build and run the DDS project on Linux.

## Prerequisites

### 1. Install FastDDS on Linux

#### Option 1: Install from packages (Ubuntu/Debian)
```bash
# Add eProsima repositories
curl -s https://raw.githubusercontent.com/eProsima/Fast-DDS/master/fastdds.repos | sudo tee /etc/apt/sources.list.d/fastdds.list
curl -s https://raw.githubusercontent.com/eProsima/Fast-DDS/master/fastdds.gpg | sudo apt-key add -

# Update and install
sudo apt update
sudo apt install libfastdds-dev libfastcdr-dev
```

#### Option 2: Build from source
```bash
# Install dependencies
sudo apt install cmake g++ python3-pip
pip3 install colcon-common-extensions

# Create workspace
mkdir ~/fastdds_ws && cd ~/fastdds_ws

# Clone repositories
git clone https://github.com/eProsima/foonathan_memory_vendor.git src/foonathan_memory_vendor
git clone https://github.com/eProsima/Fast-CDR.git src/Fast-CDR
git clone https://github.com/eProsima/Fast-DDS.git src/Fast-DDS

# Build
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release
source install/setup.bash
```

### 2. Install Node.js Development Tools
```bash
sudo apt install nodejs npm build-essential
```

### 3. Install Python Development Tools (for SWIG bindings)
```bash
sudo apt install python3-dev swig
```

## Building the Project

### 1. Build the DDS Library
```bash
cd DDSmessage
chmod +x build-linux.sh
./build-linux.sh
```

### 2. Build Node.js Addon
```bash
cd nodejs
chmod +x build-linux.sh
./build-linux.sh
```

## Running Examples

### 1. Set up environment
```bash
cd nodejs
chmod +x setup-env.sh
source setup-env.sh
```

### 2. Run tests
```bash
# Basic functionality test
node examples/test.js

# Domain test
node examples/test-domain.js
```

### 3. Run Publisher/Subscriber
```bash
# Terminal 1 - Publisher
chmod +x run-publisher.sh
./run-publisher.sh TestTopic

# Terminal 2 - Subscriber
chmod +x run-subscriber.sh
./run-subscriber.sh
```

## Troubleshooting

### Library Not Found Errors
If you get library loading errors, ensure:
1. FastDDS is properly installed
2. LD_LIBRARY_PATH includes FastDDS libraries: `/usr/local/lib`
3. LD_LIBRARY_PATH includes the DDS facade library: `../DDSmessage/build`

### CMake Configuration Issues
- Ensure CMake version >= 3.15
- Check that FastDDS development packages are installed
- Verify compiler supports C++11

### Node.js Build Issues
- Ensure node-gyp is installed: `npm install -g node-gyp`
- Check that build tools are available: `sudo apt install build-essential`
- Verify Python development headers: `sudo apt install python3-dev`

## Environment Variables

### Required Environment Variables
```bash
# Library path (add to ~/.bashrc for persistence)
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/lib:$(pwd)/DDSmessage/build"

# Optional: Set DDS domain ID
export DDS_DOMAIN_ID="25"
```

### FastDDS Configuration
Create `~/.fastdds/profiles.xml` for custom DDS configuration:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<profiles xmlns="http://www.eprosima.com/XMLSchemas/fastRTPS_Profiles">
    <participant profile_name="default_participant">
        <rtps>
            <builtin>
                <discovery_config>
                    <leaseDuration>
                        <sec>20</sec>
                    </leaseDuration>
                </discovery_config>
            </builtin>
        </rtps>
    </participant>
</profiles>
```

## Cross-Platform Development

The project now supports both Windows and Linux:
- Windows: Use PowerShell scripts (`.ps1`) and Visual Studio build tools
- Linux: Use Bash scripts (`.sh`) and GCC/Make build tools

Build configurations are automatically detected by CMake and node-gyp based on the target platform.
