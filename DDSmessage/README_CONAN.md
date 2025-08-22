# DDSmessage Conan Package

This package contains the DDSmessage binaries for both Windows and Linux platforms.

## Package Contents

- **Headers**: All necessary header files (*.hpp, *.h)
- **Windows binaries**: 
  - `ICD.dll` - Dynamic library
  - `ICD.lib` - Import library
- **Linux binaries**: 
  - `libICD.so` - Shared library

## Usage

### In your conanfile.py:
```python
def requirements(self):
    self.requires("ddsmessage/1.0.0")
```

### In your CMakeLists.txt:
```cmake
find_package(ddsmessage REQUIRED)
target_link_libraries(your_target ddsmessage::ddsmessage)
```

## Building the Package

### Prerequisites
- FastDDS 3.x
- FastCDR 2.x
- CMake 3.15+
- Conan 2.x

### Windows
```bash
# Build the binaries first
mkdir build
cd build
cmake .. 
cmake --build . --config Release
cd ..

# Create the package
conan create . --build=missing
```

### Linux
```bash
# Build the binaries first
mkdir build_linux
cd build_linux
cmake .. 
cmake --build . --config Release
cd ..

# Create the package
conan create . --build=missing
```

## Package Structure

```
ddsmessage/
├── include/           # Header files
├── bin/
│   └── windows/       # Windows DLLs
└── lib/
    ├── windows/       # Windows import libraries
    └── linux/         # Linux shared libraries
```
