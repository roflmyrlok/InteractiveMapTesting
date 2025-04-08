using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Threading.Tasks;
using DataAcquisition.Core.Interfaces;
using DataAcquisition.Core.Models;

namespace DataAcquisition.Kyiv.Services
{
    public class JsonFileDataExporter : IDataExporter<Location>
    {
        private readonly JsonSerializerOptions _jsonOptions;

        public JsonFileDataExporter()
        {
            _jsonOptions = new JsonSerializerOptions
            {
                WriteIndented = true,
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            };
        }

        public async Task<bool> ExportDataAsync(IEnumerable<Location> data, string destination)
        {
            if (data == null)
                throw new ArgumentNullException(nameof(data));

            if (string.IsNullOrWhiteSpace(destination))
                throw new ArgumentException("Destination file path cannot be empty", nameof(destination));

            try
            {
                var directory = Path.GetDirectoryName(destination);
                if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
                {
                    Directory.CreateDirectory(directory);
                }

                var locationDtos = new List<CreateLocationDto>();
                foreach (var location in data)
                {
                    var locationDto = new CreateLocationDto
                    {
                        Name = location.Name,
                        Latitude = location.Latitude,
                        Longitude = location.Longitude,
                        Address = location.Address,
                        City = location.City,
                        State = location.State,
                        Country = location.Country,
                        PostalCode = location.PostalCode,
                        Details = new List<CreateLocationDetailDto>()
                    };

                    foreach (var detail in location.Details)
                    {
                        locationDto.Details.Add(new CreateLocationDetailDto
                        {
                            PropertyName = detail.PropertyName,
                            PropertyValue = detail.PropertyValue
                        });
                    }

                    locationDtos.Add(locationDto);
                }

                await using var fileStream = new FileStream(destination, FileMode.Create);
                await JsonSerializer.SerializeAsync(fileStream, locationDtos, _jsonOptions);

                return true;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"Error exporting to file: {ex.Message}");
                return false;
            }
        }
    }
}