using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using DataAcquisition.Core.Interfaces;
using DataAcquisition.Core.Models;

namespace DataAcquisition.Kyiv.Services
{
    public class ApiDataExporter : IDataExporter<Location>
    {
        private readonly HttpClient _httpClient;
        private readonly JsonSerializerOptions _jsonOptions;
        private readonly string _apiKey;

        public ApiDataExporter(HttpClient httpClient = null, string apiKey = null)
        {
            _httpClient = httpClient ?? new HttpClient();
            _apiKey = apiKey;
            _jsonOptions = new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            };
        }

        public async Task<bool> ExportDataAsync(IEnumerable<Location> data, string destination)
        {
            if (data == null)
                throw new ArgumentNullException(nameof(data));

            if (string.IsNullOrWhiteSpace(destination))
                throw new ArgumentException("API endpoint URL cannot be empty", nameof(destination));

            try
            {
                if (!string.IsNullOrEmpty(_apiKey))
                {
                    if (!_httpClient.DefaultRequestHeaders.Contains("Authorization"))
                    {
                        _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {_apiKey}");
                    }
                }

                int successCount = 0;
                int errorCount = 0;

                foreach (var location in data)
                {
                    try
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

                        var json = JsonSerializer.Serialize(locationDto, _jsonOptions);
                        var content = new StringContent(json, Encoding.UTF8, "application/json");
                        var response = await _httpClient.PostAsync(destination, content);

                        if (response.IsSuccessStatusCode)
                        {
                            successCount++;
                        }
                        else
                        {
                            var errorContent = await response.Content.ReadAsStringAsync();
                            Console.Error.WriteLine($"Error posting location {location.Id}: {response.StatusCode} - {errorContent}");
                            errorCount++;
                        }
                    }
                    catch (Exception ex)
                    {
                        Console.Error.WriteLine($"Error exporting location {location.Id}: {ex.Message}");
                        errorCount++;
                    }
                }

                Console.WriteLine($"Export completed. Success: {successCount}, Errors: {errorCount}");
                return errorCount == 0;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"Error during API export: {ex.Message}");
                return false;
            }
        }
    }
}