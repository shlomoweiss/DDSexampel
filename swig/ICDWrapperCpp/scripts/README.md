# ICDWrapperCpp Conan Package Scripts

This folder contains scripts for packaging ICDWrapperCpp using Conan.

**Note**: These scripts package existing pre-built binaries. Make sure to build the project first using Visual Studio or CMake before running the packaging scripts.

## Prerequisites

1. **Build the project first:**
   - Windows: Use Visual Studio or CMake to build the project in Release mode
   - Linux: Use CMake to build the project in Release mode

2. **Activate conda environment manually:**
   ```bash
   conda activate conan-env
   ```

3. **Login to Conan remote (for publishing):**
   ```bash
   conan remote login -p <api token> local-conan <username>
   ```

## Scripts

### Windows
- `complete_packaging_windows.ps1` - Complete packaging process for Windows (packages existing binaries)
- `setup_conan_package_windows.ps1` - Setup script for Windows environment

### Linux  
- `complete_packaging_linux.sh` - Complete packaging process for Linux (packages existing binaries)
- `setup_conan_package_linux.sh` - Setup script for Linux environment

## Usage

### Windows
```powershell
# First build the project using Visual Studio or CMake
# Then activate conda environment
conda activate conan-env

# Run packaging
.\scripts\complete_packaging_windows.ps1
```

### Linux
```bash
# First build the project using CMake
# Then activate conda environment
conda activate conan-env

# Run packaging
./scripts/complete_packaging_linux.sh
```

## Package Dependencies

The ICDWrapperCpp package depends on:
- `ddsmessage/1.0.0` - The base DDS message library

## Conan Profiles

The package includes platform-specific Conan profiles:
- `profiles/windows` - Windows-specific settings (Visual Studio, x86_64)
- `profiles/linux` - Linux-specific settings (GCC, x86_64)

These profiles are automatically used by the packaging scripts.

## Publishing

After successful package creation, you can publish to your remote repository:

```bash
conan upload icdwrappercpp/1.0.0 -r=local-conan --all
```
