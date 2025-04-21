using System.Linq.Expressions;
using LocationService.Application.Interfaces;
using Microsoft.EntityFrameworkCore;
using Location = LocationService.Domain.Entities.Location;
using LocationDetail = LocationService.Domain.Entities.LocationDetail;

namespace LocationService.Infrastructure.Data.Repositories
{
    public class LocationRepository : ILocationRepository
    {
        private readonly LocationDbContext _context;

        public LocationRepository(LocationDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<Location>> GetAllAsync()
        {
            return await _context.Locations
                .Include(l => l.Details)
                .ToListAsync();
        }

        public async Task<Location> GetByIdAsync(string id)
        {
            return await _context.Locations
                .Include(l => l.Details)
                .FirstOrDefaultAsync(l => l.Id == id);
        }

        public async Task<IEnumerable<Location>> FindAsync(Expression<Func<Location, bool>> predicate)
        {
            return await _context.Locations
                .Include(l => l.Details)
                .Where(predicate)
                .ToListAsync();
        }

        public async Task<Location> AddAsync(Location location)
        {
            if (string.IsNullOrEmpty(location.Id))
            {
                location.Id = Guid.NewGuid().ToString();
            }

            foreach (var detail in location.Details)
            {
                if (string.IsNullOrEmpty(detail.Id))
                {
                    detail.Id = Guid.NewGuid().ToString();
                }
                detail.LocationId = location.Id;
            }

            _context.Locations.Add(location);
            await _context.SaveChangesAsync();
            return location;
        }

        public async Task UpdateAsync(Location location)
        {
            _context.Entry(location).State = EntityState.Modified;
            await _context.SaveChangesAsync();
        }

        public async Task DeleteAsync(string id)
        {
            var location = await _context.Locations.FindAsync(id);
            if (location != null)
            {
                _context.Locations.Remove(location);
                await _context.SaveChangesAsync();
            }
        }

        public async Task<bool> ExistsAsync(string id)
        {
            return await _context.Locations.AnyAsync(l => l.Id == id);
        }
    }

    public class LocationDetailRepository : ILocationDetailRepository
    {
        private readonly LocationDbContext _context;

        public LocationDetailRepository(LocationDbContext context)
        {
            _context = context;
        }

        public async Task<LocationDetail> GetByIdAsync(string id)
        {
            return await _context.LocationDetails
                .FirstOrDefaultAsync(d => d.Id == id);
        }

        public async Task<IEnumerable<LocationDetail>> GetByLocationIdAsync(string locationId)
        {
            return await _context.LocationDetails
                .Where(d => d.LocationId == locationId)
                .ToListAsync();
        }

        public async Task<LocationDetail> AddAsync(LocationDetail detail)
        {
            if (string.IsNullOrEmpty(detail.Id))
            {
                detail.Id = Guid.NewGuid().ToString();
            }
            
            _context.LocationDetails.Add(detail);
            await _context.SaveChangesAsync();
            return detail;
        }

        public async Task UpdateAsync(LocationDetail detail)
        {
            _context.Entry(detail).State = EntityState.Modified;
            await _context.SaveChangesAsync();
        }

        public async Task DeleteAsync(string id)
        {
            var detail = await _context.LocationDetails.FindAsync(id);
            if (detail != null)
            {
                _context.LocationDetails.Remove(detail);
                await _context.SaveChangesAsync();
            }
        }
    }
}