using System.Text.Json.Serialization;

namespace DataAcquisition.Core.Models
{
	public class CreateLocationDetailDto
	{
		[JsonPropertyName("propertyName")]
		public string PropertyName { get; set; }
        
		[JsonPropertyName("propertyValue")]
		public string PropertyValue { get; set; }
	}
}