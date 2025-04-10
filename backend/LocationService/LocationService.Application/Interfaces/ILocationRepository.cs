using System.Linq.Expressions;
using LocationService.Domain.Entities;

namespace LocationService.Application.Interfaces
{
	public interface ILocationRepository
	{
		Task<IEnumerable<Location>> GetAllAsync();
		Task<Location> GetByIdAsync(Guid id);
		Task<IEnumerable<Location>> FindAsync(Expression<Func<Location, bool>> predicate);
		Task<Location> AddAsync(Location location);
		Task UpdateAsync(Location location);
		Task DeleteAsync(Guid id);
		Task<bool> ExistsAsync(Guid id);
	}

	public interface ILocationDetailRepository
	{
		Task<LocationDetail> GetByIdAsync(Guid id);
		Task<IEnumerable<LocationDetail>> GetByLocationIdAsync(Guid locationId);
		Task<LocationDetail> AddAsync(LocationDetail detail);
		Task UpdateAsync(LocationDetail detail);
		Task DeleteAsync(Guid id);
	}
}