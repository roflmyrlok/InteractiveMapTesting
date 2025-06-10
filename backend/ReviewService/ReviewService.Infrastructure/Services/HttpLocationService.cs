using System;
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
            _logger.LogInformation("Validating location with ID: {LocationId}", locationId);
            
            var response = await _httpClient.GetAsync($"api/locations/validate/{locationId}");
            
            if (response.IsSuccessStatusCode)
            {
                var content = await response.Content.ReadAsStringAsync();
                _logger.LogInformation("Response content from location service: {Content}", content);
                
                var result = JsonSerializer.Deserialize<LocationValidationResult>(content, 
                    new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                
                var exists = result?.Exists ?? false;
                _logger.LogInformation("Location {LocationId} exists: {Exists}", locationId, exists);
                return exists;
            }
            
            if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
            {
                _logger.LogInformation("Location {LocationId} not found (404)", locationId);
                return false;
            }
            
            _logger.LogError("Failed to validate location. Status code: {StatusCode}", response.StatusCode);
            
            // Instead of throwing an exception, let's try a fallback approach
            // Try to get the location directly
            return await TryGetLocationDirectly(locationId);
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "Error connecting to location service for location {LocationId}", locationId);
            
            // Try fallback approach
            return await TryGetLocationDirectly(locationId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error validating location {LocationId}", locationId);
            return false;
        }
    }
    
    private async Task<bool> TryGetLocationDirectly(Guid locationId)
    {
        try
        {
            _logger.LogInformation("Trying direct location fetch for ID: {LocationId}", locationId);
            
            var response = await _httpClient.GetAsync($"api/locations/{locationId}");
            
            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation("Location {LocationId} found via direct fetch", locationId);
                return true;
            }
            
            _logger.LogInformation("Location {LocationId} not found via direct fetch", locationId);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in direct location fetch for {LocationId}", locationId);
            return false;
        }
    }
    
    private class LocationValidationResult
    {
        public bool Exists { get; set; }
    }
}