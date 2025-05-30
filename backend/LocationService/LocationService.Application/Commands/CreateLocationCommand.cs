using LocationService.Application.DTOs;
using MediatR;

namespace LocationService.Application.Commands
{
	public class CreateLocationCommand : IRequest<Guid>
	{
		public double Latitude { get; set; }
		public double Longitude { get; set; }
		public string Address { get; set; }
		public List<LocationDetailDto> Details { get; set; } = new List<LocationDetailDto>();
	}
	
}