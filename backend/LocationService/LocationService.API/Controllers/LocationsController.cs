using LocationService.Application.Commands;
using LocationService.Application.Queries;
using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace LocationService.API.Controllers
{
	[ApiController]
	[Route("api/[controller]")]
	public class LocationsController : ControllerBase
	{
		private readonly IMediator _mediator;

		public LocationsController(IMediator mediator)
		{
			_mediator = mediator;
		}

		[HttpPost]
		public async Task<IActionResult> Create([FromBody] CreateLocationCommand command)
		{
			var locationId = await _mediator.Send(command);
			return CreatedAtAction(nameof(GetById), new { id = locationId }, new { Id = locationId });
		}

		[HttpGet("nearby")]
		public async Task<IActionResult> GetNearby(
			[FromQuery] double latitude,
			[FromQuery] double longitude,
			[FromQuery] double radiusKm = 10)
		{
			var query = new GetNearbyLocationsQuery
			{
				Latitude = latitude,
				Longitude = longitude,
				RadiusKm = radiusKm
			};
            
			var locations = await _mediator.Send(query);
			return Ok(locations);
		}
        
		[HttpGet("{id}")]
		public async Task<IActionResult> GetById(Guid id)
		{
			return Ok();
		}
	}
}