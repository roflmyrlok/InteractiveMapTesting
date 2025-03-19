using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using LocationService.Application.DTOs;
using LocationService.Application.Interfaces;

namespace LocationService.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class LocationsController : ControllerBase
    {
        private readonly ILocationService _locationService;

        public LocationsController(ILocationService locationService)
        {
            _locationService = locationService;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var locations = await _locationService.GetAllLocationsAsync();
            return Ok(locations);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            var location = await _locationService.GetLocationByIdAsync(id);
            return Ok(location);
        }

        [HttpGet("nearby")]
        public async Task<IActionResult> GetNearby(
            [FromQuery] double latitude, 
            [FromQuery] double longitude, 
            [FromQuery] double radiusKm = 10)
        {
            var locations = await _locationService.FindNearbyLocationsAsync(latitude, longitude, radiusKm);
            return Ok(locations);
        }

        [HttpGet("by-property")]
        public async Task<IActionResult> GetByProperty(
            [FromQuery] string key, 
            [FromQuery] string value)
        {
            var locations = await _locationService.FindLocationsByPropertyAsync(key, value);
            return Ok(locations);
        }

        [HttpPost]
        [Authorize]
        public async Task<IActionResult> Create(CreateLocationDto createLocationDto)
        {
            var createdLocation = await _locationService.CreateLocationAsync(createLocationDto);
            return CreatedAtAction(nameof(GetById), new { id = createdLocation.Id }, createdLocation);
        }

        [HttpPut]
        [Authorize]
        public async Task<IActionResult> Update(UpdateLocationDto updateLocationDto)
        {
            var updatedLocation = await _locationService.UpdateLocationAsync(updateLocationDto);
            return Ok(updatedLocation);
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> Delete(Guid id)
        {
            await _locationService.DeleteLocationAsync(id);
            return NoContent();
        }

        [HttpPost("{locationId}/details")]
        [Authorize]
        public async Task<IActionResult> AddDetail(Guid locationId, CreateLocationDetailDto detailDto)
        {
            var updatedLocation = await _locationService.AddLocationDetailAsync(locationId, detailDto);
            return Ok(updatedLocation);
        }

        [HttpPut("{locationId}/details/{detailId}")]
        [Authorize]
        public async Task<IActionResult> UpdateDetail(
            Guid locationId, 
            Guid detailId, 
            CreateLocationDetailDto detailDto)
        {
            var updatedLocation = await _locationService.UpdateLocationDetailAsync(locationId, detailId, detailDto);
            return Ok(updatedLocation);
        }

        [HttpDelete("{locationId}/details/{detailId}")]
        [Authorize]
        public async Task<IActionResult> RemoveDetail(Guid locationId, Guid detailId)
        {
            var updatedLocation = await _locationService.RemoveLocationDetailAsync(locationId, detailId);
            return Ok(updatedLocation);
        }
    }
}