using Google.Protobuf.WellKnownTypes;
using LocationService.Domain.Entities;
using MediatR;

namespace LocationService.Application.Commands;

public record CreateLocationCommand(
	string? Id,
	double Latitude, 
	double Longitude, 
	string Address, 
	List<CreateLocationDetailCommand>? Details
) : IRequest<Location>;

public record CreateLocationDetailCommand(
	string? Id, 
	string PropertyName, 
	string PropertyValue
);