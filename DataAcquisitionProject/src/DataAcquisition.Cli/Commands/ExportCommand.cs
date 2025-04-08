using System;
using System.CommandLine;
using System.CommandLine.Invocation;
using System.IO;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;
using DataAcquisition.Cli.Options;
using DataAcquisition.Core.Models;
using DataAcquisition.Kyiv.Services;

namespace DataAcquisition.Cli.Commands
{
	public static class ExportCommand
	{
		public static Command Create()
		{
			var command = new Command("export", "Export location data to a destination")
			{
				new Option<string>(
					new[] { "--source", "-s" },
					"Source file path containing location data"
				)
				{
					IsRequired = true
				},
				new Option<string>(
					new[] { "--destination", "-d" },
					"Destination URL or file path"
				)
				{
					IsRequired = true
				},
				new Option<string>(
					new[] { "--mode", "-m" },
					() => "file",
					"Export mode (file or api)"
				),
				new Option<string>(
					new[] { "--api-key", "-k" },
					"API key for authentication (if exporting to API)"
				)
			};

			command.Handler = CommandHandler.Create<ExportOptions>(async options =>
			{
				Console.WriteLine($"Exporting data to {options.Destination} using {options.Mode} mode...");

				try
				{
					if (!File.Exists(options.Source))
                    {
                        Console.Error.WriteLine($"Source file not found: {options.Source}");
                        return 1;
                    }

                    var jsonContent = await File.ReadAllTextAsync(options.Source);
                    var serializerOptions = new JsonSerializerOptions
                    {
                        PropertyNameCaseInsensitive = true
                    };
                    var locations = JsonSerializer.Deserialize<Location[]>(jsonContent, serializerOptions);

                    if (locations == null || locations.Length == 0)
                    {
                        Console.Error.WriteLine("No locations found in source file");
                        return 1;
                    }

                    Console.WriteLine($"Found {locations.Length} locations to export");

                    bool success = false;
                    switch (options.Mode.ToLower())
                    {
                        case "file":
                            var fileExporter = new JsonFileDataExporter();
                            success = await fileExporter.ExportDataAsync(locations, options.Destination);
                            break;

                        case "api":
                            var httpClient = new HttpClient();
                            var apiExporter = new ApiDataExporter(httpClient, options.ApiKey);
                            success = await apiExporter.ExportDataAsync(locations, options.Destination);
                            break;

                        default:
                            Console.Error.WriteLine($"Unsupported export mode: {options.Mode}");
                            return 1;
                    }

                    if (success)
                    {
                        Console.WriteLine("Export completed successfully");
                        return 0;
                    }
                    else
                    {
                        Console.Error.WriteLine("Export failed");
                        return 1;
                    }
                }
                catch (Exception ex)
                {
                    Console.Error.WriteLine($"Error during export: {ex.Message}");
                    return 1;
                }
            });

            return command;
        }
    }
}