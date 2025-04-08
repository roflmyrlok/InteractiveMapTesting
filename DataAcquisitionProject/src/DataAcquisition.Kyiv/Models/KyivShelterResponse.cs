using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace DataAcquisition.Kyiv.Models
{
	public class KyivShelterResponse
	{
		[JsonPropertyName("displayFieldName")]
		public string DisplayFieldName { get; set; }
        
		[JsonPropertyName("fieldAliases")]
		public Dictionary<string, string> FieldAliases { get; set; }
        
		[JsonPropertyName("geometryType")]
		public string GeometryType { get; set; }
        
		[JsonPropertyName("spatialReference")]
		public SpatialReference SpatialReference { get; set; }
        
		[JsonPropertyName("fields")]
		public List<Field> Fields { get; set; }
        
		[JsonPropertyName("features")]
		public List<KyivShelterFeature> Features { get; set; }
	}

	public class SpatialReference
	{
		[JsonPropertyName("wkid")]
		public int Wkid { get; set; }
        
		[JsonPropertyName("latestWkid")]
		public int LatestWkid { get; set; }
	}

	public class Field
	{
		[JsonPropertyName("name")]
		public string Name { get; set; }
        
		[JsonPropertyName("type")]
		public string Type { get; set; }
        
		[JsonPropertyName("alias")]
		public string Alias { get; set; }
        
		[JsonPropertyName("length")]
		public int? Length { get; set; }
	}
}