#!/usr/bin/env python3
"""
Simple test to check if ICDWrapper can be imported
"""

import os
import sys

# Add DLL paths to environment
os.environ['PATH'] = os.environ.get('PATH', '') + ';C:\\fastdds 3.2.2\\bin\\x64Win64VS2019;C:\\cpp-prj\\DDSexampel\\DDSmessage\\build\\Release'

print("Python version:", sys.version)
print("Current working directory:", os.getcwd())

try:
    print("Attempting to import ICDWrapper...")
    import ICDWrapper
    print("✓ ICDWrapper imported successfully!")
    
    print("\nAvailable functions and classes:")
    members = [attr for attr in dir(ICDWrapper) if not attr.startswith('_')]
    for member in sorted(members):
        print(f"  - {member}")
    
    # Test basic functionality
    print("\nTesting basic DDS functions...")
    
    # Check if we can create a HelloWorld object
    try:
        hello = ICDWrapper.HelloWorld()
        hello.index = 42
        hello.message = "Test from Python!"
        print(f"✓ HelloWorld object created: index={hello.index}, message='{hello.message}'")
    except Exception as e:
        print(f"✗ Failed to create HelloWorld object: {e}")
    
    # Test DDS functions (without actually initializing DDS)
    try:
        print("✓ DDS functions are available:")
        print(f"  - dds_init: {hasattr(ICDWrapper, 'dds_init')}")
        print(f"  - dds_write: {hasattr(ICDWrapper, 'dds_write')}")
        print(f"  - dds_take_string: {hasattr(ICDWrapper, 'dds_take_string')}")
        print(f"  - dds_shutdown: {hasattr(ICDWrapper, 'dds_shutdown')}")
    except Exception as e:
        print(f"✗ Error checking DDS functions: {e}")

except ImportError as e:
    print(f"✗ Failed to import ICDWrapper: {e}")
    print("\nTroubleshooting tips:")
    print("1. Make sure FastDDS DLLs are in PATH")
    print("2. Make sure ICD.dll is in PATH") 
    print("3. Check that _ICDWrapper.pyd was built correctly")
    
except Exception as e:
    print(f"✗ Unexpected error: {e}")

input("Press Enter to continue...")
