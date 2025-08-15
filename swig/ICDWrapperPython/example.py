#!/usr/bin/env python3
"""
Example Python script demonstrating DDS facade usage
"""

import sys
import time
import ICDWrapper

def publisher_example():
    """Example of publishing messages using DDS facade"""
    print("=== DDS Publisher Example ===")
    
    # Initialize DDS
    success = ICDWrapper.dds_init("TestTopic")
    if not success:
        print("Failed to initialize DDS")
        return False
    
    print("DDS initialized successfully")
    
    try:
        # Method 1: Using legacy write function
        print("\nPublishing with legacy method...")
        for i in range(5):
            message = f"Legacy message #{i}"
            success = ICDWrapper.dds_write(i, message)
            if success:
                print(f"Published: index={i}, message='{message}'")
            else:
                print(f"Failed to publish message {i}")
            time.sleep(0.5)
        
        # Method 2: Using struct-based write function
        print("\nPublishing with struct method...")
        for i in range(5, 10):
            hello = ICDWrapper.HelloWorld()
            hello.index = i
            hello.message = f"Struct message #{i}"
            
            success = ICDWrapper.dds_write_struct(hello)
            if success:
                print(f"Published struct: index={hello.index}, message='{hello.message}'")
            else:
                print(f"Failed to publish struct message {i}")
            time.sleep(0.5)
                
    finally:
        ICDWrapper.dds_shutdown()
        print("\nDDS shutdown completed")
    
    return True

def subscriber_example():
    """Example of subscribing to messages using DDS facade"""
    print("=== DDS Subscriber Example ===")
    
    # Initialize DDS
    success = ICDWrapper.dds_init("TestTopic")
    if not success:
        print("Failed to initialize DDS")
        return False
    
    print("DDS initialized successfully")
    print("Waiting for messages... (Press Ctrl+C to stop)")
    
    try:
        message_count = 0
        while message_count < 20:  # Limit for demo
            # Method 1: Using the convenient string-based take
            index_out = ICDWrapper.new_uintp()
            message = ICDWrapper.dds_take_string(index_out)
            
            if message:
                index = ICDWrapper.uintp_value(index_out)
                print(f"Received: index={index}, message='{message}'")
                message_count += 1
            else:
                # Method 2: Using struct-based take
                hello = ICDWrapper.HelloWorld()
                success = ICDWrapper.dds_take_struct(hello)
                if success:
                    print(f"Received struct: index={hello.index}, message='{hello.message}'")
                    message_count += 1
            
            ICDWrapper.delete_uintp(index_out)
            time.sleep(0.1)
                
    except KeyboardInterrupt:
        print("\nInterrupted by user")
    finally:
        ICDWrapper.dds_shutdown()
        print("\nDDS shutdown completed")
    
    return True

def main():
    """Main function - choose publisher or subscriber mode"""
    if len(sys.argv) != 2 or sys.argv[1] not in ['pub', 'sub']:
        print("Usage: python example.py [pub|sub]")
        print("  pub - Run as publisher")
        print("  sub - Run as subscriber")
        return 1
    
    mode = sys.argv[1]
    
    try:
        if mode == 'pub':
            publisher_example()
        elif mode == 'sub':
            subscriber_example()
    except Exception as e:
        print(f"Error: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
