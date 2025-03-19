using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ReviewService.API.Services;
using ReviewService.Application.DTOs;
using ReviewService.Application.Interfaces;

namespace ReviewService.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ReviewsController : ControllerBase
{
    private readonly IReviewService _reviewService;
    private readonly ILogger<ReviewsController> _logger;

    public ReviewsController(IReviewService reviewService, ILogger<ReviewsController> logger)
    {
        _reviewService = reviewService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var reviews = await _reviewService.GetAllReviewsAsync();
        return Ok(reviews);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var review = await _reviewService.GetReviewByIdAsync(id);
        return Ok(review);
    }

    [HttpGet("by-user/{userId}")]
    public async Task<IActionResult> GetByUserId(Guid userId)
    {
        var reviews = await _reviewService.GetReviewsByUserIdAsync(userId);
        return Ok(reviews);
    }

    [HttpGet("by-location/{locationId}")]
    public async Task<IActionResult> GetByLocationId(Guid locationId)
    {
        var reviews = await _reviewService.GetReviewsByLocationIdAsync(locationId);
        return Ok(reviews);
    }

    [HttpGet("average-rating/{locationId}")]
    public async Task<IActionResult> GetAverageRating(Guid locationId)
    {
        var averageRating = await _reviewService.GetAverageRatingForLocationAsync(locationId);
        return Ok(new { locationId, averageRating });
    }

    [HttpPost]
    [Authorize]
    public async Task<IActionResult> Create(CreateReviewDto createReviewDto)
    {
        try
        {
            // Log all available claims to help with debugging
            _logger.LogInformation("Authorization header present: {hasAuth}", Request.Headers.ContainsKey("Authorization"));
            _logger.LogInformation("Claims found in token: {claimCount}", User.Claims.Count());
            foreach (var claim in User.Claims)
            {
                _logger.LogInformation("Claim: {type} = {value}", claim.Type, claim.Value);
            }
            
            var userId = JwtHelper.GetUserIdFromToken(User);
            _logger.LogInformation("Successfully extracted user ID: {userId}", userId);
            
            var createdReview = await _reviewService.CreateReviewAsync(createReviewDto, userId);
            return CreatedAtAction(nameof(GetById), new { id = createdReview.Id }, createdReview);
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning(ex, "Unauthorized access attempt: {message}", ex.Message);
            return Unauthorized(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating review");
            return StatusCode(500, new { message = "An error occurred while creating the review" });
        }
    }

    [HttpPut]
    [Authorize]
    public async Task<IActionResult> Update(UpdateReviewDto updateReviewDto)
    {
        try
        {
            var userId = JwtHelper.GetUserIdFromToken(User);
            var updatedReview = await _reviewService.UpdateReviewAsync(updateReviewDto, userId);
            return Ok(updatedReview);
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning(ex, "Unauthorized access attempt: {message}", ex.Message);
            return Unauthorized(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating review");
            return StatusCode(500, new { message = "An error occurred while updating the review" });
        }
    }

    [HttpDelete("{id}")]
    [Authorize]
    public async Task<IActionResult> Delete(Guid id)
    {
        try
        {
            var userId = JwtHelper.GetUserIdFromToken(User);
            await _reviewService.DeleteReviewAsync(id, userId);
            return NoContent();
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning(ex, "Unauthorized access attempt: {message}", ex.Message);
            return Unauthorized(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting review");
            return StatusCode(500, new { message = "An error occurred while deleting the review" });
        }
    }
}