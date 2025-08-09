using System;
using ICDWrapper;

namespace CsharpDDS
{
	class Publisher
	{
		static void Main(string[] args)
		{
			Console.WriteLine("Publisher starting (Ctrl+C to exit)...");
			if (ICDWrapper.ICDWrapper.dds_init("HelloWorldTopic") == 0)
			{
				Console.WriteLine("Failed to init DDS facade.");
				return;
			}

			Console.CancelKeyPress += (s,e)=> { e.Cancel = true; _stop = true; };
			uint counter = 0;
			while(!_stop)
			{
				counter++;
				string msg = $"Hello DDS #{counter} @ {DateTime.Now:O}";
				if (ICDWrapper.ICDWrapper.dds_write(counter, msg) == 1)
					Console.WriteLine($"Published: index={counter} message='{msg}'");
				else
					Console.WriteLine("Publish failed");
				System.Threading.Thread.Sleep(TimeSpan.FromSeconds(5));
			}
			ICDWrapper.ICDWrapper.dds_shutdown();
			Console.WriteLine("Publisher stopped.");
		}

		static bool _stop = false;
	}
}
