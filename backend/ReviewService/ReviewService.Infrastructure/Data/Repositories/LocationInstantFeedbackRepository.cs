using Microsoft.EntityFrameworkCore;
using ReviewService.Application.Interfaces;
using ReviewService.Domain.Entities;
using ReviewService.Infrastructure.Data;

namespace ReviewService.Infrastructure.Repositories;

public class LocationInstantFeedbackRepository : ILocationInstantFeedbackRepository
{
	private readonly ReviewDbContext _context;

	public LocationInstantFeedbackRepository(ReviewDbContext context)
	{
		_context = context;
	}

	public async Task<LocationInstantFeedback?> GetByLocationAndUserAsync(Guid locationId, Guid userId)
	{
		return await _context.LocationInstantFeedbacks
			.FirstOrDefaultAsync(f => f.LocationId == locationId && f.UserId == userId);
	}

	public async Task<LocationInstantFeedback> AddAsync(LocationInstantFeedback feedback)
	{
		_context.LocationInstantFeedbacks.Add(feedback);
		await _context.SaveChangesAsync();
		return feedback;
	}

	public async Task<LocationInstantFeedback> UpdateAsync(LocationInstantFeedback feedback)
	{
		_context.LocationInstantFeedbacks.Update(feedback);
		await _context.SaveChangesAsync();
		return feedback;
	}

	public async Task<List<LocationInstantFeedback>> GetByLocationIdAsync(Guid locationId)
	{
		return await _context.LocationInstantFeedbacks
			.Where(f => f.LocationId == locationId)
			.ToListAsync();
	}

	public async Task<bool> DeleteAsync(Guid id)
	{
		var feedback = await _context.LocationInstantFeedbacks.FindAsync(id);
		if (feedback == null)
			return false;

		_context.LocationInstantFeedbacks.Remove(feedback);
		await _context.SaveChangesAsync();
		return true;
	}
}