using AutoMapper;
using LocationService.Application.DTOs;
using LocationService.Application.Interfaces;
using LocationService.Application.Queries;
using MediatR;

namespace LocationService.Application.Handlers
{
	public class GetNearbyLocationsQueryHandler : IRequestHandler<GetNearbyLocationsQuery, IEnumerable<LocationDto>>
	{
		private readonly ILocationRepository _locationRepository;
		private readonly IMapper _mapper;

		public GetNearbyLocationsQueryHandler(ILocationRepository locationRepository, IMapper mapper)
		{
			_locationRepository = locationRepository;
			_mapper = mapper;
		}

		public async Task<IEnumerable<LocationDto>> Handle(GetNearbyLocationsQuery request, CancellationToken cancellationToken)
		{
			var allLocations = await _locationRepository.GetAllAsync();
            
			var nearbyLocations = allLocations.Where(location => 
				CalculateDistance(request.Latitude, request.Longitude, location.Latitude, location.Longitude) <= request.RadiusKm
			).ToList();

			return _mapper.Map<IEnumerable<LocationDto>>(nearbyLocations);
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