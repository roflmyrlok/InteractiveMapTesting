using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace DataAcquisition.Core.Models
{
	public class CreateLocationDto
	{
		[JsonPropertyName("name")]
		public string Name { get; set; }
        
		[JsonPropertyName("latitude")]
		public double Latitude { get; set; }
        
		[JsonPropertyName("longitude")]
		public double Longitude { get; set; }
        
		[JsonPropertyName("address")]
		public string Address { get; set; }
        
		[JsonPropertyName("city")]
		public string City { get; set; }
        
		[JsonPropertyName("state")]
		public string State { get; set; }
        
		[JsonPropertyName("country")]
		public string Country { get; set; }
        
		[JsonPropertyName("postalCode")]
		public string PostalCode { get; set; }
        
		[JsonPropertyName("details")]
		public List<CreateLocationDetailDto> Details { get; set; } = new List<CreateLocationDetailDto>();
	}
}