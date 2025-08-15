#!/usr/bin/env python3
"""
Test DDS functionality with Python bindings
"""

import os
import sys
import time

# Set up DLL directories for Python 3.8+
if sys.version_info >= (3, 8):
    os.add_dll_directory(r'C:\fastdds 3.2.2\bin\x64Win64VS2019')
    os.add_dll_directory(r'C:\cpp-prj\DDSexampel\DDSmessage\build\Release')

os.environ['PATH'] = os.environ.get('PATH', '') + ';C:\\fastdds 3.2.2\\bin\\x64Win64VS2019;C:\\cpp-prj\\DDSexampel\\DDSmessage\\build\\Release'

try:
    import ICDWrapper
    print("✓ ICDWrapper imported successfully!")
except ImportError as e:
    print(f"✗ Failed to import ICDWrapper: {e}")
    sys.exit(1)

def test_publisher():
    """Test publishing messages"""
    print("\n=== Testing DDS Publisher ===")
    
    # Initialize DDS
    success = ICDWrapper.dds_init("TestTopic")
    if not success:
        print("✗ Failed to initialize DDS")
        return False
    
    print("✓ DDS initialized successfully")
    
    try:
        # Test legacy write method
        print("\nTesting legacy write method...")
        for i in range(3):
            success = ICDWrapper.dds_write(i, f"Legacy message #{i}")
            if success:
                print(f"✓ Published: index={i}, message='Legacy message #{i}'")
            else:
                print(f"✗ Failed to publish message {i}")
            time.sleep(0.2)
        
        # Test struct write method
        print("\nTesting struct write method...")
        for i in range(3, 6):
            hello = ICDWrapper.HelloWorld()
            hello.index = i
            hello.message = f"Struct message #{i}"
            
            success = ICDWrapper.dds_write_struct(hello)
            if success:
                print(f"✓ Published struct: index={hello.index}, message='{hello.message}'")
            else:
                print(f"✗ Failed to publish struct message {i}")
            time.sleep(0.2)
    
    except Exception as e:
        print(f"✗ Error during publishing: {e}")
        return False
    finally:
        ICDWrapper.dds_shutdown()
        print("✓ DDS shutdown completed")
    
    return True

def test_subscriber():
    """Test receiving messages"""
    print("\n=== Testing DDS Subscriber ===")
    
    # Initialize DDS
    success = ICDWrapper.dds_init("TestTopic")
    if not success:
        print("✗ Failed to initialize DDS")
        return False
    
    print("✓ DDS initialized successfully")
    print("Listening for messages for 5 seconds...")
    
    messages_received = 0
    start_time = time.time()
    
    try:
        while time.time() - start_time < 5.0:
            # Try taking with string method
            index_out = ICDWrapper.new_uintp()
            message = ICDWrapper.dds_take_string(index_out)
            
            if message:
                index = ICDWrapper.uintp_value(index_out)
                print(f"✓ Received: index={index}, message='{message}'")
                messages_received += 1
            else:
                # Try struct method
                hello = ICDWrapper.HelloWorld()
                success = ICDWrapper.dds_take_struct(hello)
                if success:
                    print(f"✓ Received struct: index={hello.index}, message='{hello.message}'")
                    messages_received += 1
            
            ICDWrapper.delete_uintp(index_out)
            time.sleep(0.1)
    
    except Exception as e:
        print(f"✗ Error during subscription: {e}")
        return False
    finally:
        ICDWrapper.dds_shutdown()
        print("✓ DDS shutdown completed")
    
    print(f"Total messages received: {messages_received}")
    return True

def main():
    """Main test function"""
    print("DDS Python Bindings Test")
    print("========================")
    
    if len(sys.argv) > 1:
        mode = sys.argv[1].lower()
        if mode == 'pub':
            return test_publisher()
        elif mode == 'sub':
            return test_subscriber()
        else:
            print("Usage: python test_dds.py [pub|sub]")
            return False
    else:
        # Run both tests in sequence
        print("Running both publisher and subscriber tests...")
        pub_result = test_publisher()
        time.sleep(1)
        sub_result = test_subscriber()
        return pub_result and sub_result

if __name__ == "__main__":
    try:
        success = main()
        if success:
            print("\n✓ All tests completed successfully!")
        else:
            print("\n✗ Some tests failed!")
            sys.exit(1)
    except KeyboardInterrupt:
        print("\nTest interrupted by user")
    except Exception as e:
        print(f"\nUnexpected error: {e}")
        sys.exit(1)
