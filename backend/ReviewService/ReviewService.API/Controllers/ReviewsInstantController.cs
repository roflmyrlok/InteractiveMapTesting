using System;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ReviewService.Application.DTOs;
using ReviewService.Application.Interfaces;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;

namespace ReviewService.API.Controllers;

[ApiController]
[Route("api/reviews/LocationInstantFeedback")]
[Authorize]
public class LocationInstantFeedbackController : ControllerBase
{
    private readonly ILocationInstantFeedbackService _feedbackService;
    private readonly ILogger<LocationInstantFeedbackController> _logger;

    public LocationInstantFeedbackController(ILocationInstantFeedbackService feedbackService, ILogger<LocationInstantFeedbackController> logger)
    {
        _feedbackService = feedbackService;
        _logger = logger;
    }

    /// <summary>
    /// Submit instant feedback for a location (creates new or updates existing)
    /// This endpoint is for quick instant feedback submissions (All Good, Problem Inside, Can't Get In)
    /// </summary>
    /// <param name="request">Instant feedback submission request</param>
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
            _logger.LogInformation("Submitting instant feedback for location {LocationId} by user {UserId} with type {FeedbackType}", 
                request.LocationId, userId, request.FeedbackType);

            var feedbackDto = new LocationInstantFeedbackDto
            {
                LocationId = request.LocationId,
                FeedbackType = request.FeedbackType
            };

            await _feedbackService.SubmitInstantFeedbackAsync(userId, feedbackDto);
            
            _logger.LogInformation("Successfully submitted instant feedback for location {LocationId}", request.LocationId);
            return Ok(new { message = "Instant feedback submitted successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error submitting instant feedback for location {LocationId}", request.LocationId);
            return StatusCode(500, new { StatusCode = 500, Message = "An unexpected error occurred." });
        }
    }

    /// <summary>
    /// Get detailed instant status for a specific location
    /// </summary>
    /// <param name="locationId">Location ID</param>
    /// <returns>Detailed location instant status with counts and color code</returns>
    [HttpGet("status/{locationId}")]
    public async Task<IActionResult> GetLocationInstantStatus(Guid locationId)
    {
        try
        {
            _logger.LogInformation("Getting instant status for location {LocationId}", locationId);
            
            var status = await _feedbackService.GetLocationInstantStatusAsync(locationId);
            
            if (status == null)
            {
                _logger.LogWarning("Status not found for location {LocationId}", locationId);
                return NotFound($"Status not found for location {locationId}");
            }
            
            return Ok(status);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting instant status for location {LocationId}", locationId);
            return StatusCode(500, new { StatusCode = 500, Message = "An unexpected error occurred." });
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
            _logger.LogInformation("Getting instant statuses for {Count} locations", request.LocationIds.Count);
            
            var statuses = await _feedbackService.GetLocationInstantStatusSummariesAsync(request.LocationIds);
            
            _logger.LogInformation("Successfully retrieved {Count} instant status summaries", statuses.Count);
            return Ok(statuses);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting instant statuses for locations");
            return StatusCode(500, new { StatusCode = 500, Message = "An unexpected error occurred." });
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