using System.Text;
using System.Text.Json;
using Kyiv.Data.Models;

class Program
{
    static async Task Main(string[] args)
    {
        Console.WriteLine("=== Kyiv Shelters Data Acquisition ===");
        Console.WriteLine();

        // Get user inputs
        bool refreshData = GetBooleanInput("Refresh data from Kyiv API? (t/f): ");
        string token = GetStringInput("Enter authentication token: ");
        string kyivApi = GetStringInput("Enter Kyiv API URL: ");
        string serviceApi = GetStringInput("Enter Location Service API URL: ");

        Console.WriteLine();
        Console.WriteLine("Starting data processing...");

        try
        {
            string jsonData;
            
            if (refreshData)
            {
                Console.WriteLine("Fetching data from Kyiv API...");
                jsonData = await FetchDataFromKyivApi(kyivApi);
                
                Console.WriteLine("Saving data locally...");
                await SaveDataLocally(jsonData);
            }
            else
            {
                Console.WriteLine("Loading data from local file...");
                jsonData = await LoadLocalData();
            }

            Console.WriteLine("Processing shelter data...");
            var shelters = ProcessShelterData(jsonData);
            
            Console.WriteLine($"Found {shelters.Count} shelters to process");
            
            Console.WriteLine("Creating locations in service...");
            await CreateLocationsInService(shelters, serviceApi, token);
            
            Console.WriteLine("Data processing completed successfully!");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error: {ex.Message}");
            Environment.Exit(1);
        }
    }

    static bool GetBooleanInput(string prompt)
    {
        while (true)
        {
            Console.Write(prompt);
            var input = Console.ReadLine()?.ToLower();
            
            if (input == "t" || input == "true")
                return true;
            if (input == "f" || input == "false")
                return false;
                
            Console.WriteLine("Please enter 't' for true or 'f' for false");
        }
    }

    static string GetStringInput(string prompt)
    {
        while (true)
        {
            Console.Write(prompt);
            var input = Console.ReadLine();
            
            if (!string.IsNullOrWhiteSpace(input))
                return input.Trim();
                
            Console.WriteLine("Input cannot be empty");
        }
    }

    static async Task<string> FetchDataFromKyivApi(string apiUrl)
    {
        using var httpClient = new HttpClient();
        httpClient.Timeout = TimeSpan.FromMinutes(5);
        
        try
        {
            var response = await httpClient.GetStringAsync(apiUrl);
            return response;
        }
        catch (Exception ex)
        {
            throw new Exception($"Failed to fetch data from Kyiv API: {ex.Message}");
        }
    }

    static async Task SaveDataLocally(string jsonData)
    {
        try
        {
            await File.WriteAllTextAsync("kyiv_shelters.json", jsonData);
        }
        catch (Exception ex)
        {
            throw new Exception($"Failed to save data locally: {ex.Message}");
        }
    }

    static async Task<string> LoadLocalData()
    {
        const string fileName = "kyiv_shelters.json";
        
        if (!File.Exists(fileName))
        {
            throw new Exception($"Local file '{fileName}' not found. Please refresh data first.");
        }

        try
        {
            return await File.ReadAllTextAsync(fileName);
        }
        catch (Exception ex)
        {
            throw new Exception($"Failed to load local data: {ex.Message}");
        }
    }

    static List<CreateLocationCommand> ProcessShelterData(string jsonData)
    {
        try
        {
            var gisResponse = JsonSerializer.Deserialize<GisResponse>(jsonData);
            
            if (gisResponse?.Features == null)
            {
                throw new Exception("Invalid data format: no features found");
            }

            var locations = new List<CreateLocationCommand>();

            foreach (var feature in gisResponse.Features)
            {
                try
                {
                    var location = ConvertFeatureToLocation(feature);
                    if (location != null)
                    {
                        locations.Add(location);
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Warning: Failed to process feature: {ex.Message}");
                }
            }

            return locations;
        }
        catch (JsonException ex)
        {
            throw new Exception($"Failed to parse JSON data: {ex.Message}");
        }
    }

    static CreateLocationCommand? ConvertFeatureToLocation(GisFeature feature)
    {
        if (feature.Geometry == null || feature.Attributes == null)
            return null;

        var address = GetAttributeValue(feature.Attributes, "address");
        if (string.IsNullOrWhiteSpace(address))
            return null;

        var location = new CreateLocationCommand
        {
            Latitude = feature.Geometry.Y,
            Longitude = feature.Geometry.X,
            Address = address,
            Details = new List<LocationDetailDto>()
        };

        // Add disabled people availability
        var disabledAccess = GetAttributeValue(feature.Attributes, "invalid");
        if (!string.IsNullOrWhiteSpace(disabledAccess))
        {
            location.Details.Add(new LocationDetailDto
            {
                PropertyName = "DisabledAccess",
                PropertyValue = disabledAccess
            });
        }

        // Add phone number
        var phone = GetAttributeValue(feature.Attributes, "tel");
        if (!string.IsNullOrWhiteSpace(phone))
        {
            location.Details.Add(new LocationDetailDto
            {
                PropertyName = "Phone",
                PropertyValue = phone
            });
        }

        // Add district
        var district = GetAttributeValue(feature.Attributes, "district");
        if (!string.IsNullOrWhiteSpace(district))
        {
            location.Details.Add(new LocationDetailDto
            {
                PropertyName = "District",
                PropertyValue = district
            });
        }

        // Add shelter type
        var shelterType = GetAttributeValue(feature.Attributes, "type");
        if (!string.IsNullOrWhiteSpace(shelterType))
        {
            location.Details.Add(new LocationDetailDto
            {
                PropertyName = "ShelterType",
                PropertyValue = shelterType
            });
        }

        // Add shelter kind
        var shelterKind = GetAttributeValue(feature.Attributes, "kind");
        if (!string.IsNullOrWhiteSpace(shelterKind))
        {
            location.Details.Add(new LocationDetailDto
            {
                PropertyName = "ShelterKind",
                PropertyValue = shelterKind
            });
        }

        // Add building type
        var buildingType = GetAttributeValue(feature.Attributes, "type_building");
        if (!string.IsNullOrWhiteSpace(buildingType))
        {
            location.Details.Add(new LocationDetailDto
            {
                PropertyName = "BuildingType",
                PropertyValue = buildingType
            });
        }

        // Add owner
        var owner = GetAttributeValue(feature.Attributes, "owner");
        if (!string.IsNullOrWhiteSpace(owner))
        {
            location.Details.Add(new LocationDetailDto
            {
                PropertyName = "Owner",
                PropertyValue = owner
            });
        }

        // Add ownership type
        var ownershipType = GetAttributeValue(feature.Attributes, "type_ownership");
        if (!string.IsNullOrWhiteSpace(ownershipType))
        {
            location.Details.Add(new LocationDetailDto
            {
                PropertyName = "OwnershipType",
                PropertyValue = ownershipType
            });
        }

        // Add working time
        var workingTime = GetAttributeValue(feature.Attributes, "working_time");
        if (!string.IsNullOrWhiteSpace(workingTime))
        {
            location.Details.Add(new LocationDetailDto
            {
                PropertyName = "WorkingTime",
                PropertyValue = workingTime
            });
        }

        // Add description
        var description = GetAttributeValue(feature.Attributes, "description");
        if (!string.IsNullOrWhiteSpace(description) && description != "-")
        {
            location.Details.Add(new LocationDetailDto
            {
                PropertyName = "Description",
                PropertyValue = description
            });
        }

        return location;
    }

    static string GetAttributeValue(Dictionary<string, object?> attributes, string key)
    {
        if (!attributes.TryGetValue(key, out var value) || value == null)
            return string.Empty;

        if (value is JsonElement jsonElement)
        {
            return jsonElement.ValueKind switch
            {
                JsonValueKind.String => jsonElement.GetString() ?? string.Empty,
                JsonValueKind.Number => jsonElement.GetDouble().ToString(),
                JsonValueKind.True => "true",
                JsonValueKind.False => "false",
                JsonValueKind.Null => string.Empty,
                _ => jsonElement.ToString()
            };
        }

        return value.ToString() ?? string.Empty;
    }

    static async Task CreateLocationsInService(List<CreateLocationCommand> locations, string serviceApiUrl, string token)
    {
        using var httpClient = new HttpClient();
        httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {token}");
        httpClient.DefaultRequestHeaders.Add("Accept", "application/json");
        httpClient.Timeout = TimeSpan.FromMinutes(10);

        int successCount = 0;
        int failureCount = 0;

        for (int i = 0; i < locations.Count; i++)
        {
            var location = locations[i];
            
            try
            {
                var json = JsonSerializer.Serialize(location, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var content = new StringContent(json, Encoding.UTF8, "application/json");
                var response = await httpClient.PostAsync(serviceApiUrl, content);

                if (response.IsSuccessStatusCode)
                {
                    successCount++;
                    Console.WriteLine($"[{i + 1}/{locations.Count}] ✓ Created: {location.Address}");
                }
                else
                {
                    failureCount++;
                    var errorContent = await response.Content.ReadAsStringAsync();
                    Console.WriteLine($"[{i + 1}/{locations.Count}] ✗ Failed: {location.Address} - {response.StatusCode}: {errorContent}");
                }
            }
            catch (Exception ex)
            {
                failureCount++;
                Console.WriteLine($"[{i + 1}/{locations.Count}] ✗ Error: {location.Address} - {ex.Message}");
            }

            // Small delay to avoid overwhelming the server
            if (i < locations.Count - 1)
            {
                await Task.Delay(100);
            }
        }

        Console.WriteLine();
        Console.WriteLine($"Results: {successCount} successful, {failureCount} failed");
    }
}