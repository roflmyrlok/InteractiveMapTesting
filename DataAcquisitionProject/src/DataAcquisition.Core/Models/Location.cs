using System.Collections.Generic;

namespace DataAcquisition.Core.Models
{
	public class Location
	{
		public string Id { get; set; }
		public string Name { get; set; }
		public double Latitude { get; set; }
		public double Longitude { get; set; }
		public string Address { get; set; }
		public string City { get; set; }
		public string State { get; set; }
		public string Country { get; set; }
		public string PostalCode { get; set; }
		public List<LocationDetail> Details { get; set; } = new List<LocationDetail>();
	}
}