#!/usr/bin/env python3
"""
Complete guide for using DDS Python bindings
"""

import os
import sys

# Set up DLL directories for Python 3.8+
if sys.version_info >= (3, 8):
    os.add_dll_directory(r'C:\fastdds 3.2.2\bin\x64Win64VS2019')
    os.add_dll_directory(r'C:\cpp-prj\DDSexampel\DDSmessage\build\Release')

try:
    import ICDWrapper
    print("=== DDS Python Bindings Usage Guide ===\n")
    
    # 1. Creating HelloWorld objects
    print("1. Creating HelloWorld objects:")
    hello = ICDWrapper.HelloWorld()
    
    # Set properties using setter methods
    hello.index(42)  # Call as method to set
    hello.message("Hello from Python!")  # Call as method to set
    
    print(f"   Created HelloWorld: index={hello.index()}, message='{hello.message()}'")
    
    # 2. Show all available methods
    print("\n2. Available DDS Functions:")
    functions = [
        ('dds_init(topic_name)', 'Initialize DDS with topic name'),
        ('dds_init_with_domain(topic_name, domain_id)', 'Initialize DDS with topic and domain'),
        ('dds_write(index, message)', 'Publish using legacy method'),
        ('dds_write_struct(hello_world)', 'Publish using struct method'),
        ('dds_take_string(index_out_ptr)', 'Receive message as string'),
        ('dds_take_struct(hello_world_out)', 'Receive into struct'),
        ('dds_shutdown()', 'Clean up DDS resources'),
    ]
    
    for func, desc in functions:
        print(f"   • {func:<40} - {desc}")
    
    # 3. Usage example (without actually calling DDS functions)
    print("\n3. Example Usage Pattern:")
    print("""
   # Initialize DDS
   success = ICDWrapper.dds_init("TestTopic")
   if success:
       # Create and publish a message
       hello = ICDWrapper.HelloWorld()
       hello.index(123)
       hello.message("My message")
       
       # Publish using struct method
       ICDWrapper.dds_write_struct(hello)
       
       # Or publish using legacy method  
       ICDWrapper.dds_write(123, "My message")
       
       # To receive messages:
       received_hello = ICDWrapper.HelloWorld()
       if ICDWrapper.dds_take_struct(received_hello):
           print(f"Received: {received_hello.index()}, {received_hello.message()}")
       
       # Clean up
       ICDWrapper.dds_shutdown()
    """)
    
    print("4. Notes:")
    print("   • Use .index() and .message() as methods to get/set values")
    print("   • Always call dds_shutdown() to clean up resources")
    print("   • Set DDS_DOMAIN_ID environment variable if needed")
    print("   • The bindings provide access to both legacy and struct-based APIs")

except Exception as e:
    print(f"✗ Error: {e}")
    import traceback
    traceback.print_exc()
