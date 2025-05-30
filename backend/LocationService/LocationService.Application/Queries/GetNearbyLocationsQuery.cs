using LocationService.Application.DTOs;
using MediatR;

namespace LocationService.Application.Queries
{
	public class GetNearbyLocationsQuery : IRequest<IEnumerable<LocationDto>>
	{
		public double Latitude { get; set; }
		public double Longitude { get; set; }
		public double RadiusKm { get; set; } = 0.5;
	}
}