using LocationService.Application.Commands;
using LocationService.Application.Interfaces;
using MediatR;
using Google.Protobuf.WellKnownTypes;
using Location = LocationService.Domain.Entities.Location;
using LocationDetail = LocationService.Domain.Entities.LocationDetail;

namespace LocationService.Application.Handlers
{
	public class CreateLocationCommandHandler : IRequestHandler<CreateLocationCommand, string>
	{
		private readonly ILocationRepository _locationRepository;

		public CreateLocationCommandHandler(ILocationRepository locationRepository)
		{
			_locationRepository = locationRepository;
		}

		public async Task<string> Handle(CreateLocationCommand request, CancellationToken cancellationToken)
		{
			var location = new Location
			{
				Id = Guid.NewGuid().ToString(),
				Latitude = request.Latitude,
				Longitude = request.Longitude,
				Address = request.Address,
				CreatedAt = Timestamp.FromDateTime(DateTime.UtcNow)
			};

			foreach (var detailDto in request.Details)
			{
				location.Details.Add(new LocationDetail
				{
					Id = Guid.NewGuid().ToString(),
					LocationId = location.Id,
					PropertyName = detailDto.PropertyName,
					PropertyValue = detailDto.PropertyValue
				});
			}

			await _locationRepository.AddAsync(location);
            
			return location.Id;
		}
	}
}