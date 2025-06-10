using ReviewService.Application.DTOs;

namespace ReviewService.Application.Interfaces;

public interface ILocationInstantFeedbackService
{
	Task SubmitInstantFeedbackAsync(Guid userId, LocationInstantFeedbackDto feedbackDto);
	Task<LocationInstantStatusDto?> GetLocationInstantStatusAsync(Guid locationId);
	Task<List<LocationInstantStatusSummaryDto>> GetLocationInstantStatusSummariesAsync(List<Guid> locationIds);
}