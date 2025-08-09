using System;
using ICDWrapper;

namespace HelloWorldDemo
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("HelloWorld Object Demo - Working with both fields");
            Console.WriteLine("================================================");
            
            // Demo 1: Creating and manipulating HelloWorld objects directly
            Console.WriteLine("\n1. Creating HelloWorld objects with two fields:");
            
            var hello1 = new HelloWorld();
            hello1.index(42);                        // Set index field (uint32_t)
            hello1.message("Direct object access!"); // Set message field (string)
            
            Console.WriteLine($"   HelloWorld object: index={hello1.index()}, message='{hello1.message()}'");
            
            var hello2 = new HelloWorld();
            hello2.index(100);
            hello2.message("Another HelloWorld instance");
            
            Console.WriteLine($"   HelloWorld object: index={hello2.index()}, message='{hello2.message()}'");
            
            // Demo 2: Copy constructor
            Console.WriteLine("\n2. Using copy constructor:");
            var hello3 = new HelloWorld(hello1);
            Console.WriteLine($"   Copied HelloWorld: index={hello3.index()}, message='{hello3.message()}'");
            
            // Demo 3: Modify existing object
            Console.WriteLine("\n3. Modifying existing object:");
            hello3.index(999);
            hello3.message("Modified message");
            Console.WriteLine($"   Modified HelloWorld: index={hello3.index()}, message='{hello3.message()}'");
            
            Console.WriteLine("\nThis demonstrates that your HelloWorld struct has two accessible fields:");
            Console.WriteLine("- index: uint32_t (accessible via index() method)");
            Console.WriteLine("- message: string (accessible via message() method)");
            Console.WriteLine("\nYour DDS publisher sends both fields using dds_write(index, message)");
            Console.WriteLine("Your DDS subscriber receives both fields, but the simple API only returns the message string");
            
            // Clean up
            hello1.Dispose();
            hello2.Dispose();
            hello3.Dispose();
            
            Console.WriteLine("\nPress any key to exit...");
            Console.ReadKey();
        }
    }
}
