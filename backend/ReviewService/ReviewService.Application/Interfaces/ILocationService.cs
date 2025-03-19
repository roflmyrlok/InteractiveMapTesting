namespace ReviewService.Application.Interfaces;

public interface ILocationService
{ 
	Task<bool> ValidateLocationExistsAsync(Guid locationId);
}