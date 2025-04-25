using Google.Protobuf.WellKnownTypes;
using LocationService.Application.Commands;
using LocationService.Application.Interfaces;
using LocationService.Domain.Entities;
using MediatR;

namespace LocationService.Application.Handlers;

public class CreateLocationCommandHandler : IRequestHandler<CreateLocationCommand, Location>
{
	private readonly ILocationRepository _locationRepository;

	public CreateLocationCommandHandler(ILocationRepository locationRepository)
	{
		_locationRepository = locationRepository;
	}

	public async Task<Location> Handle(CreateLocationCommand request, CancellationToken cancellationToken)
	{
		var location = new Location
		{
			Id = request.Id ?? Guid.NewGuid().ToString(),
			Latitude = request.Latitude,
			Longitude = request.Longitude,
			Address = request.Address,
			CreatedAt = Timestamp.FromDateTime(DateTime.UtcNow)
		};

		if (request.Details != null)
		{
			foreach (var detailCmd in request.Details)
			{
				var locationDetail = new LocationDetail
				{
					Id = detailCmd.Id ?? Guid.NewGuid().ToString(),
					LocationId = location.Id,
					PropertyName = detailCmd.PropertyName,
					PropertyValue = detailCmd.PropertyValue
				};
                
				location.Details.Add(locationDetail);
			}
		}

		return await _locationRepository.AddAsync(location);
	}
}