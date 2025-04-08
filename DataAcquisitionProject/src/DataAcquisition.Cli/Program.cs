using System;
using System.CommandLine;
using System.Threading.Tasks;
using DataAcquisition.Cli.Commands;

namespace DataAcquisition.Cli
{
	public class Program
	{
		public static async Task<int> Main(string[] args)
		{
			var rootCommand = new RootCommand("Data Acquisition Tool for fetching and transforming location data");

			var importCommand = ImportCommand.Create();
			rootCommand.Add(importCommand);

			var exportCommand = ExportCommand.Create();
			rootCommand.Add(exportCommand);

			return await rootCommand.InvokeAsync(args);
		}
	}
}