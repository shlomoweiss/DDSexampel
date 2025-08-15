# ICDWrapper Python Bindings

This directory contains Python bindings for the DDS facade generated using SWIG.

## Prerequisites

1. **SWIG**: Install SWIG for generating Python bindings
2. **Python**: Python 3.x with development headers
3. **FastDDS**: FastDDS library installed (path configured in setup.py)
4. **Visual Studio**: C++ compiler for Windows

## Build Instructions

1. **Generate SWIG wrapper**:
   ```bash
   swig -python -c++ -I../../DDSmessage -o ICD_wrap.cxx ../ICD.i
   ```

2. **Build the Python extension**:
   ```bash
   python setup.py build_ext --inplace
   ```

## Usage Example

```python
import ICDWrapper

# Initialize DDS
success = ICDWrapper.dds_init("TestTopic")
if success:
    print("DDS initialized successfully")
    
    # Create and publish a message
    hello = ICDWrapper.HelloWorld()
    hello.index = 42
    hello.message = "Hello from Python!"
    
    # Write using struct method
    ICDWrapper.dds_write_struct(hello)
    
    # Or write using legacy method
    ICDWrapper.dds_write(123, "Legacy message")
    
    # Take messages
    index_out = ICDWrapper.new_uintp()
    message = ICDWrapper.dds_take_string(index_out)
    if message:
        index = ICDWrapper.uintp_value(index_out)
        print(f"Received: index={index}, message={message}")
    
    # Shutdown
    ICDWrapper.dds_shutdown()
```

## Files

- `setup.py`: Python distutils setup for building the extension
- `ICD_wrap.cxx`: SWIG-generated C++ wrapper (generated)
- `ICDWrapper.py`: SWIG-generated Python module (generated)
- `_ICDWrapper.pyd`: Compiled Python extension (generated)
