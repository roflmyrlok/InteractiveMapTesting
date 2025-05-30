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

		[HttpGet]
		public async Task<IActionResult> GetAll()
		{
			var query = new GetAllLocationsQuery();
			var locations = await _mediator.Send(query);
			return Ok(locations);
		}

		[HttpGet("{id}")]
		public async Task<IActionResult> GetById(Guid id)
		{
			try
			{
				var query = new GetLocationByIdQuery { Id = id };
				var location = await _mediator.Send(query);
				return Ok(location);
			}
			catch (Exception)
			{
				return NotFound();
			}
		}

		[HttpGet("validate/{id}")]
		public async Task<IActionResult> ValidateLocation(Guid id)
		{
			try
			{
				var query = new GetLocationByIdQuery { Id = id };
				var location = await _mediator.Send(query);
				return Ok(new { exists = location != null });
			}
			catch (Exception)
			{
				return Ok(new { exists = false });
			}
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

		[HttpPost]
		public async Task<IActionResult> Create([FromBody] CreateLocationCommand command)
		{
			var locationId = await _mediator.Send(command);
			return CreatedAtAction(nameof(GetById), new { id = locationId }, new { Id = locationId });
		}
	}
}