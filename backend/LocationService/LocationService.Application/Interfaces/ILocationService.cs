using LocationService.Application.DTOs;

namespace LocationService.Application.Interfaces
{
	public interface ILocationService
	{
		// Location CRUD operations
		Task<IEnumerable<LocationDto>> GetAllLocationsAsync();
		Task<LocationDto> GetLocationByIdAsync(Guid id);
		Task<LocationDto> CreateLocationAsync(CreateLocationDto createLocationDto);
		Task<LocationDto> UpdateLocationAsync(UpdateLocationDto updateLocationDto);
		Task DeleteLocationAsync(Guid id);

		// Location Details operations
		Task<LocationDto> AddLocationDetailAsync(Guid locationId, CreateLocationDetailDto detailDto);
		Task<LocationDto> UpdateLocationDetailAsync(Guid locationId, Guid detailId, CreateLocationDetailDto detailDto);
		Task<LocationDto> RemoveLocationDetailAsync(Guid locationId, Guid detailId);

		// Location Search operations
		Task<IEnumerable<LocationDto>> FindNearbyLocationsAsync(double latitude, double longitude, double radiusKm = 10);
		Task<IEnumerable<LocationDto>> FindLocationsByPropertyAsync(string key, string value);
	}
}