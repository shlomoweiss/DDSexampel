# Creating Python Bindings from SWIG Interface

This guide explains how to create Python bindings for the DDS facade using the `ICD.i` SWIG interface file.

## Overview

The `ICD.i` file is a SWIG interface that defines how to wrap the C++ DDS facade for use in other languages. This guide focuses on creating Python bindings.

## Prerequisites

### Required Software
1. **SWIG 4.0+**: SWIG (Simplified Wrapper and Interface Generator)
   - Download from: https://www.swig.org/download.html
   - Ensure `swig` is in your system PATH

2. **Python 3.8+**: Python with development headers
   - For Windows: Install Python from python.org
   - Ensure `python` is in your system PATH

3. **Visual Studio Build Tools**: C++ compiler for Windows
   - Visual Studio 2019/2022 with C++ build tools
   - Or Visual Studio Build Tools standalone

4. **FastDDS Library**: Already installed at `C:\fastdds 3.2.2\`

5. **Built DDS Message Library**: The ICD library should be built
   - Location: `DDSmessage\build\Release\ICD.dll`

## SWIG Interface File (`ICD.i`)

The interface file includes:
- **Module name**: `ICDWrapper`
- **C++ headers**: All necessary DDS and facade headers
- **Type mappings**: Standard types (int, string, vector)
- **Exposed classes**: `HelloWorld` and related DDS types
- **C facade functions**: Both legacy and struct-based APIs
- **Helper functions**: Custom `dds_take_string()` for easier Python usage

## Step-by-Step Instructions

### 1. Create Python Wrapper Directory

```bash
mkdir swig\ICDWrapperPython
cd swig\ICDWrapperPython
```

### 2. Generate SWIG Wrapper

Run SWIG to generate the Python wrapper code:

```bash
swig -python -c++ "-I../../DDSmessage" -cpperraswarn -o ICD_wrap.cxx ../ICD.i
```

**Parameters explained:**
- `-python`: Generate Python bindings
- `-c++`: Input is C++ code
- `"-I../../DDSmessage"`: Include directory for headers
- `-cpperraswarn`: Treat C preprocessor errors as warnings
- `-o ICD_wrap.cxx`: Output wrapper file name
- `../ICD.i`: Input SWIG interface file

**Generated files:**
- `ICD_wrap.cxx`: C++ wrapper code
- `ICDWrapper.py`: Python module interface

### 3. Create Setup Script

Create `setup.py` for building the Python extension:

```python
from distutils.core import setup, Extension
import os
import sys

# Define paths
dds_message_dir = os.path.join('..', '..', 'DDSmessage')
dds_build_dir = os.path.join(dds_message_dir, 'build', 'Release')

# FastDDS installation path
fastdds_root = r'C:\fastdds 3.2.2'
fastdds_include = os.path.join(fastdds_root, 'include')
fastdds_lib = os.path.join(fastdds_root, 'lib', 'x64Win64VS2019')

# Include directories
include_dirs = [
    dds_message_dir,
    fastdds_include,
    os.path.join(fastdds_include, 'fastcdr'),
    os.path.join(fastdds_include, 'fastdds'),
    os.path.join(fastdds_include, 'fastrtps'),
    os.path.join(fastdds_include, 'foonathan_memory'),
]

# Library directories  
library_dirs = [
    dds_build_dir,
    fastdds_lib
]

# Libraries to link (note version numbers)
libraries = [
    'ICD',              # Our compiled ICD library
    'fastdds-3.2',      # FastDDS with version
    'fastcdr-2.3'       # FastCDR with version
]

# Define the extension module
icd_module = Extension(
    '_ICDWrapper',      # Module name (with underscore prefix)
    sources=[
        'ICD_wrap.cxx',     # SWIG-generated wrapper
    ],
    include_dirs=include_dirs,
    library_dirs=library_dirs,
    libraries=libraries,
    define_macros=[
        ('WIN32_LEAN_AND_MEAN', None),
        ('_WIN32_WINNT', '0x0601'),
    ],
    extra_compile_args=['/std:c++17'] if sys.platform == 'win32' else ['-std=c++17'],
    language='c++'
)

setup(
    name='ICDWrapper',
    version='1.0',
    ext_modules=[icd_module],
    py_modules=['ICDWrapper'],
)
```

### 4. Build Python Extension

Compile the extension module:

```bash
python setup.py build_ext --inplace
```

**Generated files:**
- `_ICDWrapper.cp312-win_amd64.pyd`: Compiled Python extension
- `build/`: Temporary build directory

### 5. Test the Bindings

Create a test script:

```python
import os
import sys

# Setup DLL paths (required for Python 3.8+)
if sys.version_info >= (3, 8):
    os.add_dll_directory(r'C:\fastdds 3.2.2\bin\x64Win64VS2019')
    os.add_dll_directory(r'C:\cpp-prj\DDSexampel\DDSmessage\build\Release')

# Import the wrapper
import ICDWrapper

# Test basic functionality
hello = ICDWrapper.HelloWorld()
hello.index(42)
hello.message("Hello from Python!")

print("✓ Python bindings working!")
```

## Automated Build Script

Create `build.bat` for Windows:

```batch
@echo off
echo Generating SWIG wrapper...
swig -python -c++ "-I../../DDSmessage" -cpperraswarn -o ICD_wrap.cxx ../ICD.i

if errorlevel 1 (
    echo SWIG generation failed!
    pause
    exit /b 1
)

echo Building Python extension...
python setup.py build_ext --inplace

if errorlevel 1 (
    echo Python build failed!
    pause
    exit /b 1
)

echo Build completed successfully!
pause
```

## Usage Examples

### Basic DDS Operations

```python
import ICDWrapper

# Initialize DDS
success = ICDWrapper.dds_init("TestTopic")
if success:
    # Publish using legacy method
    ICDWrapper.dds_write(42, "Hello World!")
    
    # Publish using struct method
    hello = ICDWrapper.HelloWorld()
    hello.index(123)
    hello.message("Struct message")
    ICDWrapper.dds_write_struct(hello)
    
    # Receive messages
    index_out = ICDWrapper.new_uintp()
    message = ICDWrapper.dds_take_string(index_out)
    if message:
        index = ICDWrapper.uintp_value(index_out)
        print(f"Received: {index}, {message}")
    ICDWrapper.delete_uintp(index_out)
    
    # Cleanup
    ICDWrapper.dds_shutdown()
```

## Available Functions

The Python wrapper exposes all functions from `dds_facade.hpp`:

### Initialization
- `dds_init(topic_name)`: Initialize DDS with topic
- `dds_init_with_domain(topic_name, domain_id)`: Initialize with specific domain

### Publishing
- `dds_write(index, message)`: Legacy publish method
- `dds_write_struct(hello_world)`: Struct-based publish

### Subscribing
- `dds_take(index_out, buffer, buffer_len)`: Legacy receive
- `dds_take_struct(hello_world_out)`: Struct-based receive
- `dds_take_string(index_out)`: Helper for string messages
- `dds_take_message(index_out)`: Convenience method

### Cleanup
- `dds_shutdown()`: Release all DDS resources

### Classes
- `HelloWorld`: Main message type with `index()` and `message()` methods

## Troubleshooting

### Common Issues

1. **Import Error: DLL load failed**
   - Ensure FastDDS DLLs are in PATH or use `os.add_dll_directory()`
   - Check that ICD.dll is accessible

2. **SWIG Generation Errors**
   - Verify include paths are correct
   - Use `-cpperraswarn` to ignore C preprocessor warnings

3. **Build Errors**
   - Check library names match installed versions (e.g., `fastdds-3.2`)
   - Ensure Visual Studio C++ tools are installed

4. **Runtime Errors**
   - Set `DDS_DOMAIN_ID` environment variable if needed
   - Always call `dds_shutdown()` to clean up

### Verification Steps

1. Check SWIG installation: `swig -version`
2. Verify Python development headers are installed
3. Confirm FastDDS libraries are accessible
4. Test basic import: `python -c "import ICDWrapper"`

## Files Structure

After successful build:

```
ICDWrapperPython/
├── setup.py                    # Build configuration
├── build.bat                   # Automated build script
├── ICD_wrap.cxx               # SWIG-generated wrapper
├── ICDWrapper.py              # Python module interface
├── _ICDWrapper.*.pyd          # Compiled extension
├── build/                     # Build artifacts
└── __pycache__/              # Python cache
```

## Notes

- The SWIG interface (`ICD.i`) defines what gets exposed to Python
- Library version numbers in setup.py must match your FastDDS installation
- DLL path setup is crucial for Python 3.8+ on Windows
- Both legacy and modern DDS APIs are available through the wrapper
