using LocationService.Application.Commands;
using LocationService.Application.Interfaces;
using LocationService.Domain.Entities;
using MediatR;

namespace LocationService.Application.Handlers
{
	public class CreateLocationCommandHandler : IRequestHandler<CreateLocationCommand, Guid>
	{
		private readonly ILocationRepository _locationRepository;

		public CreateLocationCommandHandler(ILocationRepository locationRepository)
		{
			_locationRepository = locationRepository;
		}

		public async Task<Guid> Handle(CreateLocationCommand request, CancellationToken cancellationToken)
		{
			var location = new Location
			{
				Id = Guid.NewGuid(),
				Latitude = request.Latitude,
				Longitude = request.Longitude,
				Address = request.Address,
				CreatedAt = DateTime.UtcNow
			};

			foreach (var detailDto in request.Details)
			{
				location.Details.Add(new LocationDetail
				{
					Id = Guid.NewGuid(),
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