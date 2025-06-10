using ReviewService.Domain.Entities;

namespace ReviewService.Application.Interfaces;

public interface ILocationInstantStatusRepository
{
	Task<LocationInstantStatus?> GetByLocationIdAsync(Guid locationId);
	Task<List<LocationInstantStatus>> GetByLocationIdsAsync(List<Guid> locationIds);
	Task<LocationInstantStatus> AddAsync(LocationInstantStatus status);
	Task<LocationInstantStatus> UpdateAsync(LocationInstantStatus status);
	Task<bool> DeleteAsync(Guid id);
}