using System;
using System.CommandLine;
using System.CommandLine.Invocation;
using System.IO;
using System.Net.Http;
using System.Threading.Tasks;
using DataAcquisition.Cli.Options;
using DataAcquisition.Kyiv.Models;
using DataAcquisition.Kyiv.Services;

namespace DataAcquisition.Cli.Commands
{
    public static class ImportCommand
    {
        public static Command Create()
        {
            var command = new Command("import", "Import location data from a source")
            {
                new Option<string>(
                    new[] { "--source", "-s" },
                    "Source file path or URL"
                )
                {
                    IsRequired = true
                },
                new Option<string>(
                    new[] { "--output", "-o" },
                    "Output file path for the imported data"
                )
                {
                    IsRequired = true
                },
                new Option<string>(
                    new[] { "--type", "-t" },
                    () => "kyiv",
                    "Type of data source (kyiv)"
                ),
                new Option<string>(
                    new[] { "--city" },
                    () => "Kyiv",
                    "Default city for the data"
                ),
                new Option<string>(
                    new[] { "--state" },
                    () => "Kyiv",
                    "Default state/region for the data"
                ),
                new Option<string>(
                    new[] { "--country" },
                    () => "Ukraine",
                    "Default country for the data"
                )
            };

            command.Handler = CommandHandler.Create<ImportOptions>(async options =>
            {
                Console.WriteLine($"Importing data from {options.Source} ({options.Type})...");

                try
                {
                    switch (options.Type.ToLower())
                    {
                        case "kyiv":
                            return await ImportKyivData(options.Source, options.Output, options.City, options.State, options.Country);
                        default:
                            Console.Error.WriteLine($"Unsupported data type: {options.Type}");
                            return 1;
                    }
                }
                catch (Exception ex)
                {
                    Console.Error.WriteLine($"Error during import: {ex.Message}");
                    return 1;
                }
            });

            return command;
        }

        private static async Task<int> ImportKyivData(string source, string output, string city, string state, string country)
        {
            try
            {
                var dataProvider = new KyivShelterDataProvider(new HttpClient());
                var shelterData = await dataProvider.GetDataAsync(source);
                Console.WriteLine($"Fetched {shelterData.Features?.Count ?? 0} features from source");

                var transformer = new KyivShelterDataTransformer(city, state, country);
                var locations = transformer.Transform(shelterData);

                var exporter = new JsonFileDataExporter();
                var success = await exporter.ExportDataAsync(locations, output);

                if (success)
                {
                    Console.WriteLine($"Data successfully imported and saved to {output}");
                    return 0;
                }
                else
                {
                    Console.Error.WriteLine("Failed to export data");
                    return 1;
                }
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"Error importing Kyiv data: {ex.Message}");
                return 1;
            }
        }
    }
}