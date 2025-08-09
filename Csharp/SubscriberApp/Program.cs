
using System;
using ICDWrapper;

namespace CsharpDDS
{
	class Subscriber
	{
		static void Main(string[] args)
		{
			Console.WriteLine("Subscriber starting (Ctrl+C to exit)...");
			if (ICDWrapper.ICDWrapper.dds_init("HelloWorldTopic") == 0)
			{
				Console.WriteLine("Failed to init DDS facade.");
				return;
			}
			Console.CancelKeyPress += (s,e)=> { e.Cancel = true; _stop = true; };
			// Using wrapper method rather than private P/Invoke
			while(!_stop)
			{
				string msg = ICDWrapper.ICDWrapper.dds_take_message(null);
				if (msg != null)
					Console.WriteLine($"Received: message='{msg}'");
				else
					System.Threading.Thread.Sleep(200);
			}
			ICDWrapper.ICDWrapper.dds_shutdown();
			Console.WriteLine("Subscriber stopped.");
		}
		static bool _stop = false;
	}
}
