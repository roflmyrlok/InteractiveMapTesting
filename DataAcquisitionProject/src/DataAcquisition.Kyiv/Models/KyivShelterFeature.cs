using System.Text.Json.Serialization;

namespace DataAcquisition.Kyiv.Models
{
	public class KyivShelterFeature
	{
		[JsonPropertyName("attributes")]
		public KyivShelterAttributes Attributes { get; set; }
        
		[JsonPropertyName("geometry")]
		public Geometry Geometry { get; set; }
	}

	public class Geometry
	{
		[JsonPropertyName("x")]
		public double X { get; set; }
        
		[JsonPropertyName("y")]
		public double Y { get; set; }
	}
}