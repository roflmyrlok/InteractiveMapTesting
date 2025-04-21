using System.Linq.Expressions;
using Location = LocationService.Domain.Entities.Location;
using LocationDetail = LocationService.Domain.Entities.LocationDetail;

namespace LocationService.Application.Interfaces
{
	public interface ILocationRepository
	{
		Task<IEnumerable<Location>> GetAllAsync();
		Task<Location> GetByIdAsync(string id);
		Task<IEnumerable<Location>> FindAsync(Expression<Func<Location, bool>> predicate);
		Task<Location> AddAsync(Location location);
		Task UpdateAsync(Location location);
		Task DeleteAsync(string id);
		Task<bool> ExistsAsync(string id);
	}

	public interface ILocationDetailRepository
	{
		Task<LocationDetail> GetByIdAsync(string id);
		Task<IEnumerable<LocationDetail>> GetByLocationIdAsync(string locationId);
		Task<LocationDetail> AddAsync(LocationDetail detail);
		Task UpdateAsync(LocationDetail detail);
		Task DeleteAsync(string id);
	}
}