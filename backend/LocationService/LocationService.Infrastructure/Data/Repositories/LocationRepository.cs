using System.Linq.Expressions;
using Google.Protobuf.WellKnownTypes;
using LocationService.Application.Interfaces;
using LocationService.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace LocationService.Infrastructure.Data.Repositories;

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

    public async Task<Location?> GetByIdAsync(string id)
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
        location.Id = string.IsNullOrWhiteSpace(location.Id) 
            ? Guid.NewGuid().ToString() 
            : location.Id;
        
        location.CreatedAt ??= Timestamp.FromDateTime(DateTime.UtcNow);
        
        foreach (var detail in location.Details)
        {
            detail.Id = string.IsNullOrWhiteSpace(detail.Id) 
                ? Guid.NewGuid().ToString() 
                : detail.Id;
            detail.LocationId = location.Id;
        }

        _context.Locations.Add(location);
        await _context.SaveChangesAsync();
        return location;
    }

    public async Task UpdateAsync(Location location)
    {
        _context.Locations.Update(location);
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