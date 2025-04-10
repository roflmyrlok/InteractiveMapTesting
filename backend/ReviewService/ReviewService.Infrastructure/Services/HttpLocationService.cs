using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ReviewService.Application.Interfaces;
using ReviewService.Domain.Exceptions;
using ReviewService.Infrastructure.Configuration;

namespace ReviewService.Infrastructure.Services;

public class HttpLocationService : ILocationService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<HttpLocationService> _logger;
    private readonly ServicesConfiguration _configuration;

    public HttpLocationService(
        HttpClient httpClient,
        IOptions<ServicesConfiguration> configuration,
        ILogger<HttpLocationService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
        _configuration = configuration.Value;
    }

    public async Task<bool> ValidateLocationExistsAsync(Guid locationId)
    {
        try
        {
            var response = await _httpClient.GetAsync($"api/locations/validate/{locationId}");
            
            if (response.IsSuccessStatusCode)
            {
                var content = await response.Content.ReadAsStringAsync();
                _logger.LogInformation("Response content from location service: {Content}", content);
                
                var result = JsonSerializer.Deserialize<LocationValidationResult>(content, 
                    new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                
                // Just return the result, don't throw exception here
                return result?.Exists ?? false;
            }
            
            if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
            {
                return false;
            }
            
            _logger.LogError("Failed to validate location. Status code: {StatusCode}", response.StatusCode);
            throw new DomainException("Location validation service is currently unavailable. Please try again later.");
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "Error connecting to location service");
            throw new DomainException("Location validation service is currently unavailable. Please try again later.");
        }
    }
    
    private class LocationValidationResult
    {
        public bool Exists { get; set; }
    }
}