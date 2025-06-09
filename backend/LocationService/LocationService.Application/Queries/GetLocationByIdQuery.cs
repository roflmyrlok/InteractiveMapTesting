using LocationService.Application.DTOs;
using MediatR;

namespace LocationService.Application.Queries
{
	public class GetLocationByIdQuery : IRequest<LocationDto>
	{
		public Guid Id { get; set; }
	}
}