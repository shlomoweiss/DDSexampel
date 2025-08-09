using System;
using ICDWrapper;

namespace CsharpDDS
{
    class StructSubscriber
    {
        static void Main(string[] args)
        {
            Console.WriteLine("HelloWorld Struct Subscriber starting (Ctrl+C to exit)...");
            if (ICDWrapper.ICDWrapper.dds_init("HelloWorldTopic") == 0)
            {
                Console.WriteLine("Failed to init DDS facade.");
                return;
            }

            Console.CancelKeyPress += (s, e) => { e.Cancel = true; _stop = true; };

            Console.WriteLine("Receiving complete HelloWorld struct objects:");
            Console.WriteLine("  ✓ Using dds_take_struct(HelloWorld)");
            Console.WriteLine("  ✓ Access to all fields directly");
            Console.WriteLine();

            while (!_stop)
            {
                // Create an empty HelloWorld struct to receive data
                var receivedStruct = new HelloWorld();

                // Take a complete struct
                if (ICDWrapper.ICDWrapper.dds_take_struct(receivedStruct) == 1)
                {
                    Console.WriteLine($"✓ Received HelloWorld struct:");
                    Console.WriteLine($"    index: {receivedStruct.index()}");
                    Console.WriteLine($"    message: '{receivedStruct.message()}'");
                    Console.WriteLine();
                    
                    // You can now access all fields of the HelloWorld struct!
                    // When you add more fields to HelloWorld, they'll be accessible here
                    // without changing the API calls
                }
                else
                {
                    System.Threading.Thread.Sleep(200);
                }

                receivedStruct.Dispose(); // Clean up
            }
            
            ICDWrapper.ICDWrapper.dds_shutdown();
            Console.WriteLine("Struct Subscriber stopped.");
        }

        static bool _stop = false;
    }
}
