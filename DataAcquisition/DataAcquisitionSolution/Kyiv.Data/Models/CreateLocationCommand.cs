using System.Text.Json.Serialization;

namespace Kyiv.Data.Models;

public class CreateLocationCommand
{
	[JsonPropertyName("latitude")]
	public double Latitude { get; set; }
    
	[JsonPropertyName("longitude")]
	public double Longitude { get; set; }
    
	[JsonPropertyName("address")]
	public string Address { get; set; } = string.Empty;
    
	[JsonPropertyName("details")]
	public List<LocationDetailDto> Details { get; set; } = new();
}

public class LocationDetailDto
{
	[JsonPropertyName("propertyName")]
	public string PropertyName { get; set; } = string.Empty;
    
	[JsonPropertyName("propertyValue")]
	public string PropertyValue { get; set; } = string.Empty;
}