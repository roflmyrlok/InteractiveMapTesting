using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ReviewService.Application.DTOs;
using ReviewService.Application.Interfaces;
using System.Security.Claims;

namespace ReviewService.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class LocationInstantFeedbackController : ControllerBase
{
    private readonly ILocationInstantFeedbackService _feedbackService;

    public LocationInstantFeedbackController(ILocationInstantFeedbackService feedbackService)
    {
        _feedbackService = feedbackService;
    }

    /// <summary>
    /// Submit instant feedback for a location (creates new or updates existing)
    /// </summary>
    /// <param name="request">Feedback submission request</param>
    /// <returns>Success or error result</returns>
    [HttpPost("submit")]
    public async Task<IActionResult> SubmitInstantFeedback([FromBody] SubmitInstantFeedbackRequest request)
    {
        var userId = GetUserIdFromToken();
        if (userId == Guid.Empty)
        {
            return Unauthorized("Invalid user token");
        }

        try
        {
            var feedbackDto = new LocationInstantFeedbackDto
            {
                LocationId = request.LocationId,
                FeedbackType = request.FeedbackType
            };

            await _feedbackService.SubmitInstantFeedbackAsync(userId, feedbackDto);
            return Ok(new { message = "Instant feedback submitted successfully" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Get detailed instant status for a specific location
    /// </summary>
    /// <param name="locationId">Location ID</param>
    /// <returns>Detailed location instant status</returns>
    [HttpGet("status/{locationId}")]
    public async Task<IActionResult> GetLocationInstantStatus(Guid locationId)
    {
        try
        {
            var status = await _feedbackService.GetLocationInstantStatusAsync(locationId);
            
            if (status == null)
            {
                return NotFound($"Status not found for location {locationId}");
            }
            
            return Ok(status);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Get instant status summaries for multiple locations (for map display)
    /// </summary>
    /// <param name="request">List of location IDs</param>
    /// <returns>List of location status summaries with color codes</returns>
    [HttpPost("statuses")]
    public async Task<IActionResult> GetLocationInstantStatuses([FromBody] GetLocationInstantStatusesRequest request)
    {
        if (request.LocationIds == null || request.LocationIds.Count == 0)
        {
            return BadRequest("Location IDs list cannot be empty");
        }

        try
        {
            var statuses = await _feedbackService.GetLocationInstantStatusSummariesAsync(request.LocationIds);
            return Ok(statuses);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    private Guid GetUserIdFromToken()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (Guid.TryParse(userIdClaim, out var userId))
        {
            return userId;
        }
        return Guid.Empty;
    }
}