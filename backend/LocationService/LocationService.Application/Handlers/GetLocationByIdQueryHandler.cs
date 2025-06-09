using AutoMapper;
using LocationService.Application.DTOs;
using LocationService.Application.Interfaces;
using LocationService.Application.Queries;
using LocationService.Domain.Exceptions;
using MediatR;

namespace LocationService.Application.Handlers
{
	public class GetLocationByIdQueryHandler : IRequestHandler<GetLocationByIdQuery, LocationDto>
	{
		private readonly ILocationRepository _locationRepository;
		private readonly IMapper _mapper;

		public GetLocationByIdQueryHandler(ILocationRepository locationRepository, IMapper mapper)
		{
			_locationRepository = locationRepository;
			_mapper = mapper;
		}

		public async Task<LocationDto> Handle(GetLocationByIdQuery request, CancellationToken cancellationToken)
		{
			var location = await _locationRepository.GetByIdAsync(request.Id);
            
			if (location == null)
			{
				throw new DomainException($"Location with ID {request.Id} not found");
			}

			return _mapper.Map<LocationDto>(location);
		}
	}
}