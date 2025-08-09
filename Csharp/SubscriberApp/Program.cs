
using System;
using ICDWrapper;

namespace CsharpDDS
{
	class Subscriber
	{
		static void Main(string[] args)
		{
			Console.WriteLine("HelloWorld Subscriber starting (Ctrl+C to exit)...");
			if (ICDWrapper.ICDWrapper.dds_init("HelloWorldTopic") == 0)
			{
				Console.WriteLine("Failed to init DDS facade.");
				return;
			}
			Console.CancelKeyPress += (s,e)=> { e.Cancel = true; _stop = true; };
			
			Console.WriteLine("Waiting for HelloWorld messages with two fields:");
			Console.WriteLine("  - index (uint32_t): message counter from publisher");
			Console.WriteLine("  - message (string): descriptive text from publisher");
			Console.WriteLine();
			
			// Using the simple method that works
			while(!_stop)
			{
				// Method 1: Get just the message (current working approach)
				string msg = ICDWrapper.ICDWrapper.dds_take_message(null);
				
				if (msg != null)
				{
					Console.WriteLine($"✓ Received HelloWorld message: '{msg}'");
					
					// The HelloWorld struct actually contains both fields:
					// - uint32_t index (the incrementing counter from publisher)
					// - std::string message (the descriptive text we see)
					// The C++ dds_write(counter, msg) call publishes both fields
					// but our C# wrapper currently only exposes the string part easily
				}
				else
				{
					System.Threading.Thread.Sleep(200);
				}
			}
			ICDWrapper.ICDWrapper.dds_shutdown();
			Console.WriteLine("Subscriber stopped.");
		}
		static bool _stop = false;
	}
}
