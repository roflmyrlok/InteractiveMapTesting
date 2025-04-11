// backend/LocationService/LocationService.Application/Queries/GetNearbyLocationsQuery.cs
using System.Collections.Generic;
using LocationService.Domain.Entities;
using MediatR;

namespace LocationService.Application.Queries
{
	public class GetNearbyLocationsQuery : IRequest<IEnumerable<Location>>
	{
		public double Latitude { get; set; }
		public double Longitude { get; set; }
		public double RadiusKm { get; set; } = 0.5;
	}
}