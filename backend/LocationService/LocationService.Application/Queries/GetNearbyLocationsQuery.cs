using MediatR;
using Location = LocationService.Domain.Entities.Location;

namespace LocationService.Application.Queries
{
	public class GetNearbyLocationsQuery : IRequest<IEnumerable<Location>>
	{
		public double Latitude { get; set; }
		public double Longitude { get; set; }
		public double RadiusKm { get; set; } = 0.5;
	}
}