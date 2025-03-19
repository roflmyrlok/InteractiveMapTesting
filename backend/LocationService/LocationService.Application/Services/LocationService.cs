using AutoMapper;
using LocationService.Application.DTOs;
using LocationService.Application.Interfaces;
using LocationService.Domain.Entities;
using LocationService.Domain.Exceptions;

namespace LocationService.Application.Services
{
    public class LocationService : ILocationService
    {
        private readonly ILocationRepository _locationRepository;
        private readonly ILocationDetailRepository _detailRepository;
        private readonly IMapper _mapper;

        public LocationService(
            ILocationRepository locationRepository, 
            ILocationDetailRepository detailRepository,
            IMapper mapper)
        {
            _locationRepository = locationRepository;
            _detailRepository = detailRepository;
            _mapper = mapper;
        }

        public async Task<IEnumerable<LocationDto>> GetAllLocationsAsync()
        {
            var locations = await _locationRepository.GetAllAsync();
            return _mapper.Map<IEnumerable<LocationDto>>(locations);
        }

        public async Task<LocationDto> GetLocationByIdAsync(Guid id)
        {
            var location = await _locationRepository.GetByIdAsync(id);
            
            if (location == null)
                throw new DomainException($"Location with ID {id} not found");

            return _mapper.Map<LocationDto>(location);
        }

        public async Task<LocationDto> CreateLocationAsync(CreateLocationDto createLocationDto)
        {
            var location = _mapper.Map<Location>(createLocationDto);
            location.Id = Guid.NewGuid();
            location.CreatedAt = DateTime.UtcNow;

            var createdLocation = await _locationRepository.AddAsync(location);
            return _mapper.Map<LocationDto>(createdLocation);
        }

        public async Task<LocationDto> UpdateLocationAsync(UpdateLocationDto updateLocationDto)
        {
            var existingLocation = await _locationRepository.GetByIdAsync(updateLocationDto.Id);
            
            if (existingLocation == null)
                throw new DomainException($"Location with ID {updateLocationDto.Id} not found");

            _mapper.Map(updateLocationDto, existingLocation);
            existingLocation.UpdatedAt = DateTime.UtcNow;

            await _locationRepository.UpdateAsync(existingLocation);
            return _mapper.Map<LocationDto>(existingLocation);
        }

        public async Task DeleteLocationAsync(Guid id)
        {
            if (!await _locationRepository.ExistsAsync(id))
                throw new DomainException($"Location with ID {id} not found");

            await _locationRepository.DeleteAsync(id);
        }

        public async Task<LocationDto> AddLocationDetailAsync(Guid locationId, CreateLocationDetailDto detailDto)
        {
            var location = await _locationRepository.GetByIdAsync(locationId);
            
            if (location == null)
                throw new DomainException($"Location with ID {locationId} not found");

            var detail = new LocationDetail
            {
                Id = Guid.NewGuid(),
                LocationId = locationId,
                PropertyName = detailDto.PropertyName,
                PropertyValue = detailDto.PropertyValue
            };

            location.Details.Add(detail);
            await _locationRepository.UpdateAsync(location);

            return _mapper.Map<LocationDto>(location);
        }

        public async Task<LocationDto> UpdateLocationDetailAsync(Guid locationId, Guid detailId, CreateLocationDetailDto detailDto)
        {
            var location = await _locationRepository.GetByIdAsync(locationId);
            
            if (location == null)
                throw new DomainException($"Location with ID {locationId} not found");

            var detail = location.Details.FirstOrDefault(d => d.Id == detailId);
            
            if (detail == null)
                throw new DomainException($"Location detail with ID {detailId} not found");

            detail.PropertyName = detailDto.PropertyName;
            detail.PropertyValue = detailDto.PropertyValue;

            await _locationRepository.UpdateAsync(location);
            return _mapper.Map<LocationDto>(location);
        }

        public async Task<LocationDto> RemoveLocationDetailAsync(Guid locationId, Guid detailId)
        {
            var location = await _locationRepository.GetByIdAsync(locationId);
            
            if (location == null)
                throw new DomainException($"Location with ID {locationId} not found");

            var detail = location.Details.FirstOrDefault(d => d.Id == detailId);
            
            if (detail == null)
                throw new DomainException($"Location detail with ID {detailId} not found");

            location.Details.Remove(detail);
            await _locationRepository.UpdateAsync(location);

            return _mapper.Map<LocationDto>(location);
        }

        public async Task<IEnumerable<LocationDto>> FindNearbyLocationsAsync(double latitude, double longitude, double radiusKm = 10)
        {
            var locations = await _locationRepository.GetAllAsync();

            var nearbyLocations = locations
                .Where(location => 
                {
                    var distanceInKm = CalculateDistance(latitude, longitude, location.Latitude, location.Longitude);
                    return distanceInKm <= radiusKm;
                })
                .ToList();

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

        public async Task<IEnumerable<LocationDto>> FindLocationsByPropertyAsync(string propertyName, string propertyValue)
        {
            var locations = await _locationRepository.FindAsync(
                l => l.Details.Any(d => 
                    d.PropertyName.ToLower() == propertyName.ToLower() && 
                    d.PropertyValue.ToLower() == propertyValue.ToLower())
            );

            return _mapper.Map<IEnumerable<LocationDto>>(locations);
        }
    }
}