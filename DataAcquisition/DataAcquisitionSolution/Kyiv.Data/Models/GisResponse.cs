using System.Text.Json.Serialization;

namespace Kyiv.Data.Models;

public class GisResponse
{
	[JsonPropertyName("features")]
	public List<GisFeature> Features { get; set; } = new();
}

public class GisFeature
{
	[JsonPropertyName("attributes")]
	public Dictionary<string, object?> Attributes { get; set; } = new();
    
	[JsonPropertyName("geometry")]
	public GisGeometry Geometry { get; set; } = new();
}

public class GisGeometry
{
	[JsonPropertyName("x")]
	public double X { get; set; }
    
	[JsonPropertyName("y")]
	public double Y { get; set; }
}