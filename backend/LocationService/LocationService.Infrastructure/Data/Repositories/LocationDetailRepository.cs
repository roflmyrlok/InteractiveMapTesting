using LocationService.Application.Interfaces;
using LocationService.Domain.Entities;
using LocationService.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace LocationService.Infrastructure.Data.Repositories;

public class LocationDetailRepository : ILocationDetailRepository
{
	private readonly LocationDbContext _context;

	public LocationDetailRepository(LocationDbContext context)
	{
		_context = context;
	}

	public async Task<LocationDetail?> GetByIdAsync(string id)
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
		// Ensure ID is set if not provided
		detail.Id = string.IsNullOrWhiteSpace(detail.Id) 
			? Guid.NewGuid().ToString() 
			: detail.Id;

		_context.LocationDetails.Add(detail);
		await _context.SaveChangesAsync();
		return detail;
	}

	public async Task UpdateAsync(LocationDetail detail)
	{
		_context.LocationDetails.Update(detail);
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