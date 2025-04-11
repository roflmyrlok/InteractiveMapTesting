using LocationService.Application.Interfaces;
using LocationService.Application.Queries;
using LocationService.Domain.Entities;
using MediatR;

namespace LocationService.Application.Handlers
{
	public class GetNearbyLocationsQueryHandler : IRequestHandler<GetNearbyLocationsQuery, IEnumerable<Location>>
	{
		private readonly ILocationRepository _locationRepository;

		public GetNearbyLocationsQueryHandler(ILocationRepository locationRepository)
		{
			_locationRepository = locationRepository;
		}

		public async Task<IEnumerable<Location>> Handle(GetNearbyLocationsQuery request, CancellationToken cancellationToken)
		{
			var allLocations = await _locationRepository.GetAllAsync();
            
			return allLocations.Where(location => 
				CalculateDistance(request.Latitude, request.Longitude, location.Latitude, location.Longitude) <= request.RadiusKm
			).ToList();
		}
        
		private double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
		{
			const double R = 6371; // Earth's radius in kilometers
            
			var dLat = ToRadians(lat2 - lat1);
			var dLon = ToRadians(lon2 - lon1);
            
			var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
			        Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
			        Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
            
			var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
            
			return R * c;
		}

		private double ToRadians(double degrees)
		{
			return degrees * Math.PI / 180;
		}
	}
}