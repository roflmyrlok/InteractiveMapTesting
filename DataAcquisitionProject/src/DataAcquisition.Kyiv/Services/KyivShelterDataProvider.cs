using System;
using System.IO;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;
using DataAcquisition.Core.Interfaces;
using DataAcquisition.Kyiv.Models;

namespace DataAcquisition.Kyiv.Services
{
    public class KyivShelterDataProvider : IDataProvider<KyivShelterResponse>
    {
        private readonly HttpClient _httpClient;
        private readonly JsonSerializerOptions _jsonOptions;

        public KyivShelterDataProvider(HttpClient httpClient = null)
        {
            _httpClient = httpClient ?? new HttpClient();
            _jsonOptions = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };
        }

        public async Task<KyivShelterResponse> GetDataAsync(string source)
        {
            if (string.IsNullOrWhiteSpace(source))
                throw new ArgumentException("Source cannot be null or empty", nameof(source));

            try
            {
                string jsonContent;

                if (Uri.TryCreate(source, UriKind.Absolute, out Uri uriResult) && 
                    (uriResult.Scheme == Uri.UriSchemeHttp || uriResult.Scheme == Uri.UriSchemeHttps))
                {
                    jsonContent = await _httpClient.GetStringAsync(source);
                }
                else
                {
                    if (!File.Exists(source))
                        throw new FileNotFoundException($"File not found: {source}");

                    jsonContent = await File.ReadAllTextAsync(source);
                }

                var response = JsonSerializer.Deserialize<KyivShelterResponse>(jsonContent, _jsonOptions);
                
                if (response == null)
                    throw new JsonException("Failed to deserialize response");

                return response;
            }
            catch (HttpRequestException ex)
            {
                throw new Exception($"Failed to retrieve data from URL: {ex.Message}", ex);
            }
            catch (JsonException ex)
            {
                throw new Exception($"Failed to parse JSON data: {ex.Message}", ex);
            }
            catch (Exception ex)
            {
                throw new Exception($"An error occurred while getting data: {ex.Message}", ex);
            }
        }
    }
}