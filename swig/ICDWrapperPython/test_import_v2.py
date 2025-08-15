#!/usr/bin/env python3
"""
Alternative test with explicit DLL directory addition (Python 3.8+)
"""

import os
import sys

print("Python version:", sys.version)

# For Python 3.8+, we need to explicitly add DLL directories
if sys.version_info >= (3, 8):
    print("Using os.add_dll_directory for Python 3.8+")
    try:
        os.add_dll_directory(r'C:\fastdds 3.2.2\bin\x64Win64VS2019')
        os.add_dll_directory(r'C:\cpp-prj\DDSexampel\DDSmessage\build\Release')
        print("✓ DLL directories added")
    except Exception as e:
        print(f"✗ Error adding DLL directories: {e}")

# Also add to PATH as backup
os.environ['PATH'] = os.environ.get('PATH', '') + ';C:\\fastdds 3.2.2\\bin\\x64Win64VS2019;C:\\cpp-prj\\DDSexampel\\DDSmessage\\build\\Release'

try:
    print("Attempting to import ICDWrapper...")
    import ICDWrapper
    print("✓ ICDWrapper imported successfully!")
    
    print("\nAvailable functions and classes:")
    members = [attr for attr in dir(ICDWrapper) if not attr.startswith('_')]
    for member in sorted(members):
        print(f"  - {member}")
    
    # Test creating HelloWorld object
    try:
        hello = ICDWrapper.HelloWorld()
        hello.index = 42
        hello.message = "Test from Python!"
        print(f"✓ HelloWorld object created: index={hello.index}, message='{hello.message}'")
    except Exception as e:
        print(f"✗ Failed to create HelloWorld object: {e}")
    
    print("✓ Python bindings are working!")

except ImportError as e:
    print(f"✗ Failed to import ICDWrapper: {e}")
except Exception as e:
    print(f"✗ Unexpected error: {e}")

input("Press Enter to continue...")
