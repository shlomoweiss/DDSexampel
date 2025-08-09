using System;
using ICDWrapper;

namespace CsharpDDS
{
	class Publisher
	{
		static void Main(string[] args)
		{
			Console.WriteLine("HelloWorld Publisher starting (Ctrl+C to exit)...");
			if (ICDWrapper.ICDWrapper.dds_init("HelloWorldTopic") == 0)
			{
				Console.WriteLine("Failed to init DDS facade.");
				return;
			}

			Console.CancelKeyPress += (s,e)=> { e.Cancel = true; _stop = true; };
			uint counter = 0;
			
			Console.WriteLine("Publishing HelloWorld messages with two fields:");
			Console.WriteLine("  - index (uint32_t): incrementing counter");
			Console.WriteLine("  - message (string): descriptive text");
			Console.WriteLine();
			
			while(!_stop)
			{
				counter++;
				string msg = $"Hello DDS from C# Publisher! Count: {counter} @ {DateTime.Now:HH:mm:ss}";
				
				// Send HelloWorld struct with both fields: index and message
				if (ICDWrapper.ICDWrapper.dds_write(counter, msg) == 1)
					Console.WriteLine($"✓ Published HelloWorld - index={counter}, message='{msg}'");
				else
					Console.WriteLine($"✗ Failed to publish message #{counter}");
					
				System.Threading.Thread.Sleep(TimeSpan.FromSeconds(3));
			}
			ICDWrapper.ICDWrapper.dds_shutdown();
			Console.WriteLine("Publisher stopped.");
		}

		static bool _stop = false;
	}
}
