using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using ReviewService.Application.Interfaces;
using ReviewService.Domain.Entities;
using ReviewService.Infrastructure.Data;

namespace ReviewService.Infrastructure.Repositories;

public class LocationInstantStatusRepository : ILocationInstantStatusRepository
{
	private readonly ReviewDbContext _context;

	public LocationInstantStatusRepository(ReviewDbContext context)
	{
		_context = context;
	}

	public async Task<LocationInstantStatus?> GetByLocationIdAsync(Guid locationId)
	{
		return await _context.LocationInstantStatuses
			.FirstOrDefaultAsync(s => s.LocationId == locationId);
	}

	public async Task<List<LocationInstantStatus>> GetByLocationIdsAsync(List<Guid> locationIds)
	{
		return await _context.LocationInstantStatuses
			.Where(s => locationIds.Contains(s.LocationId))
			.ToListAsync();
	}

	public async Task<LocationInstantStatus> AddAsync(LocationInstantStatus status)
	{
		_context.LocationInstantStatuses.Add(status);
		await _context.SaveChangesAsync();
		return status;
	}

	public async Task<LocationInstantStatus> UpdateAsync(LocationInstantStatus status)
	{
		_context.LocationInstantStatuses.Update(status);
		await _context.SaveChangesAsync();
		return status;
	}

	public async Task<bool> DeleteAsync(Guid id)
	{
		var status = await _context.LocationInstantStatuses.FindAsync(id);
		if (status == null)
			return false;

		_context.LocationInstantStatuses.Remove(status);
		await _context.SaveChangesAsync();
		return true;
	}
}