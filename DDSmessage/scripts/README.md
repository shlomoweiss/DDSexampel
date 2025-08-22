# DDSmessage Conan Packaging Scripts

This directory contains automation scripts for packaging EXISTING DDSmessage binaries using Conan.

**Note**: These scripts do NOT build the binaries - they package pre-built binaries that already exist.

## Scripts Overview

### Windows Scripts (PowerShell)

1. **`setup_conan_package_windows.ps1`** - Sets up Conan environment and packages existing Windows binaries
2. **`complete_packaging_windows.ps1`** - Complete packaging workflow with verification

### Linux Scripts (Bash)

1. **`setup_conan_package_linux.sh`** - Sets up Conan environment and packages existing Linux binaries
2. **`complete_packaging_linux.sh`** - Complete packaging workflow with verification

## Prerequisites

### Windows
- Windows 10/11
- Conda/Miniconda with `conda-env` environment
- Conan 2.x installed in `conda-env`
- **Pre-built Windows binaries** in `build/Release/` (ICD.dll, ICD.lib)

### Linux
- Linux (Ubuntu/CentOS/etc.)
- Conda/Miniconda with `conda-env` environment
- Conan 2.x installed in `conda-env`
- **Pre-built Linux binaries** in `build_linux/` or `build/` (libICD.so)

## Building Binaries First

Before using these packaging scripts, you need to build the binaries:

### Windows
```powershell
mkdir build
cd build
cmake ..
cmake --build . --config Release
cd ..
```

### Linux
```bash
mkdir build_linux
cd build_linux
cmake ..
cmake --build . --config Release
cd ..
```

## Quick Start

**IMPORTANT**: Before running any packaging scripts, you must manually activate the conda environment:

```bash
# Activate the conda environment first
conda activate conan-env
```

### Windows

```powershell
# First activate conda environment
conda activate conan-env

# Complete packaging workflow (recommended)
.\scripts\complete_packaging_windows.ps1

# Package and publish to repository (login required first!)
# Run these first: 
# conan remote add local-conan http://localhost:8081/artifactory/api/conan/local-conan
# conan remote login -p <token> local-conan <username>
.\scripts\complete_packaging_windows.ps1 -Publish

# Just core packaging
.\scripts\setup_conan_package_windows.ps1

# Package and publish to repository (login required first!)
.\scripts\setup_conan_package_windows.ps1 -Publish
```

### Linux

```bash
# First activate conda environment
conda activate conan-env

# Make scripts executable first
chmod +x scripts/*.sh

# Complete packaging workflow (recommended)
./scripts/complete_packaging_linux.sh

# Package and publish to repository (login required first!)
# Run these first: 
# conan remote add local-conan http://localhost:8081/artifactory/api/conan/local-conan
# conan remote login -p <token> local-conan shlomo
./scripts/complete_packaging_linux.sh --publish

# Just core packaging
./scripts/setup_conan_package_linux.sh

# Package and publish to repository (login required first!)
./scripts/setup_conan_package_linux.sh --publish
```

## Script Options

### Windows PowerShell Scripts

#### `setup_conan_package_windows.ps1`
```powershell
# Standard package creation
.\scripts\setup_conan_package_windows.ps1

# Skip Conan profile detection (use existing)
.\scripts\setup_conan_package_windows.ps1 -SkipProfile

# Package and publish to default repository
.\scripts\setup_conan_package_windows.ps1 -Publish

# Package and publish to custom repository
.\scripts\setup_conan_package_windows.ps1 -Publish -Repository "http://your-server:8081/artifactory/api/conan/your-repo"

# All options combined
.\scripts\setup_conan_package_windows.ps1 -SkipProfile -Publish
```

#### `complete_packaging_windows.ps1`
```powershell
# Complete packaging workflow
.\scripts\complete_packaging_windows.ps1

# Skip Conan profile detection
.\scripts\complete_packaging_windows.ps1 -SkipProfile

# Package and publish to default repository
.\scripts\complete_packaging_windows.ps1 -Publish

# Package and publish to custom repository
.\scripts\complete_packaging_windows.ps1 -Publish -Repository "http://your-server:8081/artifactory/api/conan/your-repo"

# All options combined
.\scripts\complete_packaging_windows.ps1 -SkipProfile -Publish
```

### Linux Bash Scripts

#### `setup_conan_package_linux.sh`
```bash
# Standard package creation
./scripts/setup_conan_package_linux.sh

# Skip Conan profile detection (use existing)
./scripts/setup_conan_package_linux.sh --skip-profile

# Package and publish to default repository
./scripts/setup_conan_package_linux.sh --publish

# Package and publish to custom repository
./scripts/setup_conan_package_linux.sh --publish --repository "http://your-server:8081/artifactory/api/conan/your-repo"

# All options combined
./scripts/setup_conan_package_linux.sh --skip-profile --publish
```

#### `complete_packaging_linux.sh`
```bash
# Complete packaging workflow
./scripts/complete_packaging_linux.sh

# Skip Conan profile detection
./scripts/complete_packaging_linux.sh --skip-profile

# Package and publish to default repository
./scripts/complete_packaging_linux.sh --publish

# Package and publish to custom repository
./scripts/complete_packaging_linux.sh --publish --repository "http://your-server:8081/artifactory/api/conan/your-repo"

# All options combined
./scripts/complete_packaging_linux.sh --skip-profile --publish
```

## What the Scripts Do

### Packaging Scripts
1. Activate conda-env environment
2. Check Conan installation
3. Create/update Conan profile (if needed)
4. Verify required binaries exist (built separately)
5. Create Conan package with `conan create`
6. Verify package creation
7. Publish to repository (if requested)
8. Display usage instructions

### Complete Workflow Scripts
1. Verify existing binaries are present
2. Run Conan packaging script
3. Provide success summary

## Repository Configuration

The scripts are configured to publish to your local Artifactory repository:
- **Default Repository URL**: `http://localhost:8081/artifactory/api/conan/local-conan`
- **Remote Name**: `local-conan`

### Authentication (Required for Publishing)

**IMPORTANT**: Before using the publish functionality, you must login manually:

```bash
# Login to the repository (run this manually before using -Publish/--publish)
conan remote login -p <YOUR_TOKEN> local-conan shlomo
```

**Note**: Keep your credentials secure - never include them in automated scripts!

### Publishing Workflow

1. **Login to repository** (one-time setup or when credentials expire):
   ```bash
   # First add the remote repository
   conan remote add local-conan http://localhost:8081/artifactory/api/conan/local-conan
   
   # Then login
   conan remote login -p <YOUR_TOKEN> local-conan shlomo
   ```

2. **Run packaging script with publish option**:
   
   **Windows:**
   ```powershell
   .\scripts\complete_packaging_windows.ps1 -Publish
   ```
   
   **Linux:**
   ```bash
   ./scripts/complete_packaging_linux.sh --publish
   ```

### Important Security Notes

- **Never include credentials in scripts** - always login manually
- **Keep credentials secure** - don't commit them to version control
- **Login is persistent** - you only need to login once per session/machine
- **If publish fails** - check authentication with `conan remote list-users local-conan`

## Expected Output Structure

After successful execution:

```
DDSmessage/
├── build/Release/          # Windows binaries
│   ├── ICD.dll
│   └── ICD.lib
├── build_linux/            # Linux binaries
│   └── libICD.so
└── scripts/                # This directory
```

## Conan Package Usage

After package creation, use in other projects:

### conanfile.py
```python
def requirements(self):
    self.requires("ddsmessage/1.0.0")
```

### CMakeLists.txt
```cmake
find_package(ddsmessage REQUIRED)
target_link_libraries(your_target ddsmessage::ddsmessage)
```

## Troubleshooting

### Common Issues

1. **Conda environment not found**
   - Ensure `conda-env` environment exists
   - Install Conan: `conda activate conan-env && pip install conan`

2. **Binaries not found**
   - Build binaries first before running packaging scripts
   - Check that binaries are in the expected locations (build/Release/ or build_linux/)

3. **Conan profile issues**
   - Use `--skip-profile` option if profile already exists
   - Manually run `conan profile detect` if needed

4. **Permission issues (Linux)**
   - Make scripts executable: `chmod +x scripts/*.sh`
   - Check file permissions on build directories

5. **Publishing authentication issues**
   - Add remote first: `conan remote add local-conan http://localhost:8081/artifactory/api/conan/local-conan`
   - Login: `conan remote login -p <token> local-conan <username>`
   - Check login status: `conan remote list-users local-conan`
   - Verify repository URL is accessible: `curl http://localhost:8081/artifactory/api/conan/local-conan`

6. **Repository connection issues**
   - Ensure Artifactory is running on localhost:8081
   - Check if the repository URL is correct
   - Verify network connectivity to the repository

### Getting Help

Run any script with `-h` or `--help` for detailed usage information:

```bash
# Linux
./scripts/complete_packaging_linux.sh --help

# Windows
Get-Help .\scripts\complete_packaging_windows.ps1 -Detailed
```
