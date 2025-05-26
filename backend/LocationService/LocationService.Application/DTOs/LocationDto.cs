namespace LocationService.Application.DTOs
{
	public class LocationDto
	{
		public Guid Id { get; set; }
		public double Latitude { get; set; }
		public double Longitude { get; set; }
		public string Address { get; set; }
		public DateTime CreatedAt { get; set; }
		public DateTime? UpdatedAt { get; set; }
		public ICollection<LocationDetailDto> Details { get; set; } = new List<LocationDetailDto>();
	}
}