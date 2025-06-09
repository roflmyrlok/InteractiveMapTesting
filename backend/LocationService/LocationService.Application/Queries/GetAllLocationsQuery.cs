using LocationService.Application.DTOs;
using MediatR;

namespace LocationService.Application.Queries
{
	public class GetAllLocationsQuery : IRequest<IEnumerable<LocationDto>>
	{
	}
}