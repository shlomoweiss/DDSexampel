#!/usr/bin/env python3
"""
Simple DDS initialization test
"""

import os
import sys

# Set up DLL directories
if sys.version_info >= (3, 8):
    os.add_dll_directory(r'C:\fastdds 3.2.2\bin\x64Win64VS2019')
    os.add_dll_directory(r'C:\cpp-prj\DDSexampel\DDSmessage\build\Release')

os.environ['PATH'] = os.environ.get('PATH', '') + ';C:\\fastdds 3.2.2\\bin\\x64Win64VS2019;C:\\cpp-prj\\DDSexampel\\DDSmessage\\build\\Release'

try:
    import ICDWrapper
    print("✓ ICDWrapper imported successfully!")
    
    # Test domain-specific initialization
    print("Testing DDS initialization with domain ID...")
    
    # Set domain ID environment variable
    os.environ['DDS_DOMAIN_ID'] = '25'
    
    # Try initializing with specific domain
    success = ICDWrapper.dds_init_with_domain("TestTopic", 25)
    
    if success:
        print("✓ DDS initialized successfully with domain 25")
        
        # Quick test - try to create and set HelloWorld object
        hello = ICDWrapper.HelloWorld()
        hello.index = 1
        hello.message = "Quick test"
        print(f"✓ HelloWorld object ready: index={hello.index}, message='{hello.message}'")
        
        # Shutdown immediately
        ICDWrapper.dds_shutdown()
        print("✓ DDS shutdown completed")
    else:
        print("✗ DDS initialization failed")

except Exception as e:
    print(f"✗ Error: {e}")
    import traceback
    traceback.print_exc()
