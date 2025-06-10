using System;
using System.Threading.Tasks;

namespace ReviewService.Application.Interfaces;

public interface ILocationService
{ 
	Task<bool> ValidateLocationExistsAsync(Guid locationId);
}