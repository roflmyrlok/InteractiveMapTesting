using System.Linq.Expressions;
using LocationService.Application.Interfaces;
using LocationService.Domain.Entities;
using LocationService.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

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

        public async Task<Location> GetByIdAsync(Guid id)
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
            _context.Locations.Add(location);
            await _context.SaveChangesAsync();
            return location;
        }

        public async Task UpdateAsync(Location location)
        {
            _context.Entry(location).State = EntityState.Modified;
            await _context.SaveChangesAsync();
        }

        public async Task DeleteAsync(Guid id)
        {
            var location = await _context.Locations.FindAsync(id);
            if (location != null)
            {
                _context.Locations.Remove(location);
                await _context.SaveChangesAsync();
            }
        }

        public async Task<bool> ExistsAsync(Guid id)
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

        public async Task<LocationDetail> GetByIdAsync(Guid id)
        {
            return await _context.LocationDetails
                .Include(d => d.Location)
                .FirstOrDefaultAsync(d => d.Id == id);
        }

        public async Task<IEnumerable<LocationDetail>> GetByLocationIdAsync(Guid locationId)
        {
            return await _context.LocationDetails
                .Where(d => d.LocationId == locationId)
                .ToListAsync();
        }

        public async Task<LocationDetail> AddAsync(LocationDetail detail)
        {
            _context.LocationDetails.Add(detail);
            await _context.SaveChangesAsync();
            return detail;
        }

        public async Task UpdateAsync(LocationDetail detail)
        {
            _context.Entry(detail).State = EntityState.Modified;
            await _context.SaveChangesAsync();
        }

        public async Task DeleteAsync(Guid id)
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