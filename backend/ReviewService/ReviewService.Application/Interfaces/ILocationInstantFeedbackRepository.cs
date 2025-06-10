using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using ReviewService.Domain.Entities;

namespace ReviewService.Application.Interfaces;

public interface ILocationInstantFeedbackRepository
{
	Task<LocationInstantFeedback?> GetByLocationAndUserAsync(Guid locationId, Guid userId);
	Task<LocationInstantFeedback> AddAsync(LocationInstantFeedback feedback);
	Task<LocationInstantFeedback> UpdateAsync(LocationInstantFeedback feedback);
	Task<List<LocationInstantFeedback>> GetByLocationIdAsync(Guid locationId);
	Task<bool> DeleteAsync(Guid id);
}