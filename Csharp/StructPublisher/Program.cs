using System;
using ICDWrapper;

namespace CsharpDDS
{
    class StructPublisher
    {
        static void Main(string[] args)
        {
            Console.WriteLine("HelloWorld Struct Publisher starting (Ctrl+C to exit)...");
            if (ICDWrapper.ICDWrapper.dds_init("HelloWorldTopic") == 0)
            {
                Console.WriteLine("Failed to init DDS facade.");
                return;
            }

            Console.CancelKeyPress += (s, e) => { e.Cancel = true; _stop = true; };
            uint counter = 0;

            Console.WriteLine("Publishing complete HelloWorld struct objects:");
            Console.WriteLine("  ✓ Using dds_write_struct(HelloWorld)");
            Console.WriteLine("  ✓ Easy to extend with more fields");
            Console.WriteLine();

            while (!_stop)
            {
                counter++;
                
                // Create a complete HelloWorld struct
                var helloWorld = new HelloWorld();
                helloWorld.index(counter);
                helloWorld.message($"Struct-based message #{counter} @ {DateTime.Now:HH:mm:ss}");

                // Publish the complete struct
                if (ICDWrapper.ICDWrapper.dds_write_struct(helloWorld) == 1)
                {
                    Console.WriteLine($"✓ Published HelloWorld struct:");
                    Console.WriteLine($"    index: {helloWorld.index()}");
                    Console.WriteLine($"    message: '{helloWorld.message()}'");
                }
                else
                {
                    Console.WriteLine($"✗ Failed to publish HelloWorld struct #{counter}");
                }

                Console.WriteLine();
                helloWorld.Dispose(); // Clean up
                System.Threading.Thread.Sleep(TimeSpan.FromSeconds(3));
            }
            
            ICDWrapper.ICDWrapper.dds_shutdown();
            Console.WriteLine("Struct Publisher stopped.");
        }

        static bool _stop = false;
    }
}
