namespace LocationService.Application.DTOs
{
	public class LocationDto
	{
		public Guid Id { get; set; }
		public string Name { get; set; }
		public double Latitude { get; set; }
		public double Longitude { get; set; }
		public string Address { get; set; }
		public string City { get; set; }
		public string State { get; set; }
		public string Country { get; set; }
		public string PostalCode { get; set; }
		public DateTime CreatedAt { get; set; }
		public ICollection<LocationDetailDto> Details { get; set; } = new List<LocationDetailDto>();
	}

	public class LocationDetailDto
	{
		public Guid Id { get; set; }
		public string PropertyName { get; set; }
		public string PropertyValue { get; set; }
	}

	public class CreateLocationDto
	{
		public string Name { get; set; }
		public double Latitude { get; set; }
		public double Longitude { get; set; }
		public string Address { get; set; }
		public string City { get; set; }
		public string State { get; set; }
		public string Country { get; set; }
		public string PostalCode { get; set; }
		public ICollection<CreateLocationDetailDto> Details { get; set; } = new List<CreateLocationDetailDto>();
	}

	public class CreateLocationDetailDto
	{
		public string PropertyName { get; set; }
		public string PropertyValue { get; set; }
	}

	public class UpdateLocationDto
	{
		public Guid Id { get; set; }
		public string Name { get; set; }
		public double? Latitude { get; set; }
		public double? Longitude { get; set; }
		public string Address { get; set; }
		public string City { get; set; }
		public string State { get; set; }
		public string Country { get; set; }
		public string PostalCode { get; set; }
	}
}