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
    private readonly IImageUploadService _imageUploadService;
    private readonly ILogger<ReviewsController> _logger;

    public ReviewsController(IReviewService reviewService, IImageUploadService imageUploadService, ILogger<ReviewsController> logger)
    {
        _reviewService = reviewService;
        _imageUploadService = imageUploadService;
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

    [HttpGet("images/{reviewId}/{fileName}")]
    public async Task<IActionResult> GetImage(Guid reviewId, string fileName)
    {
        try
        {
            var key = $"reviews/{reviewId}/{fileName}";
            var imageResult = await _imageUploadService.GetImageStreamAsync(key);
            
            return File(imageResult.Stream, imageResult.ContentType);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving image {FileName} for review {ReviewId}", fileName, reviewId);
            return NotFound();
        }
    }

    [HttpPost]
    [Authorize]
    public async Task<IActionResult> Create([FromForm] CreateReviewWithImagesDto createReviewDto)
    {
        try
        {
            _logger.LogInformation("Authorization header present: {hasAuth}", Request.Headers.ContainsKey("Authorization"));
            _logger.LogInformation("Claims found in token: {claimCount}", User.Claims.Count());
            foreach (var claim in User.Claims)
            {
                _logger.LogInformation("Claim: {type} = {value}", claim.Type, claim.Value);
            }
            
            var userId = JwtHelper.GetUserIdFromToken(User);
            _logger.LogInformation("Successfully extracted user ID: {userId}", userId);

            var reviewDto = new CreateReviewDto
            {
                LocationId = createReviewDto.LocationId,
                Rating = createReviewDto.Rating,
                Content = createReviewDto.Content,
                ImageUrls = new List<string>()
            };

            var createdReview = await _reviewService.CreateReviewAsync(reviewDto, userId);

            if (createReviewDto.Images != null && createReviewDto.Images.Count > 0)
            {
                try
                {
                    var imageUrls = await _imageUploadService.UploadImagesAsync(createReviewDto.Images, createdReview.Id);
                    
                    var updateDto = new UpdateReviewDto
                    {
                        Id = createdReview.Id,
                        Rating = createdReview.Rating,
                        Content = createdReview.Content,
                        ImageUrls = imageUrls
                    };
                    
                    createdReview = await _reviewService.UpdateReviewAsync(updateDto, userId);
                    _logger.LogInformation("Successfully uploaded {count} images for review {reviewId}", imageUrls.Count, createdReview.Id);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to upload images for review {reviewId}", createdReview.Id);
                    // Don't fail the entire request if image upload fails
                }
            }
            
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

    [HttpPost("json")]
    [Authorize]
    public async Task<IActionResult> CreateJson([FromBody] CreateReviewDto createReviewDto)
    {
        try
        {
            var userId = JwtHelper.GetUserIdFromToken(User);
            _logger.LogInformation("Creating review via JSON endpoint for user {userId}", userId);

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
            _logger.LogError(ex, "Error creating review via JSON");
            return StatusCode(500, new { message = "An error occurred while creating the review" });
        }
    }

    [HttpPost("upload-images/{reviewId}")]
    [Authorize]
    public async Task<IActionResult> UploadImages(Guid reviewId, IFormFileCollection images)
    {
        try
        {
            var userId = JwtHelper.GetUserIdFromToken(User);
            
            // Verify the user owns this review
            var review = await _reviewService.GetReviewByIdAsync(reviewId);
            if (review.UserId != userId)
            {
                return Forbid("You can only upload images to your own reviews");
            }

            if (images == null || images.Count == 0)
            {
                return BadRequest("No images provided");
            }

            var imageUrls = await _imageUploadService.UploadImagesAsync(images, reviewId);
            
            // Update the review with new image URLs
            var existingImageUrls = review.ImageUrls ?? new List<string>();
            existingImageUrls.AddRange(imageUrls);

            var updateDto = new UpdateReviewDto
            {
                Id = reviewId,
                Rating = review.Rating,
                Content = review.Content,
                ImageUrls = existingImageUrls
            };

            var updatedReview = await _reviewService.UpdateReviewAsync(updateDto, userId);

            return Ok(new { 
                message = "Images uploaded successfully", 
                imageUrls = imageUrls,
                review = updatedReview
            });
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning(ex, "Unauthorized access attempt: {message}", ex.Message);
            return Unauthorized(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading images for review {reviewId}", reviewId);
            return StatusCode(500, new { message = "An error occurred while uploading images" });
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
            
            // Get review to check ownership and get image URLs for cleanup
            var review = await _reviewService.GetReviewByIdAsync(id);
            if (review.UserId != userId)
            {
                return Forbid("You can only delete your own reviews");
            }

            // Delete associated images from S3
            if (review.ImageUrls != null && review.ImageUrls.Count > 0)
            {
                try
                {
                    await _imageUploadService.DeleteImagesAsync(review.ImageUrls);
                    _logger.LogInformation("Successfully deleted {count} images for review {reviewId}", review.ImageUrls.Count, id);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to delete images for review {reviewId}", id);
                    // Continue with review deletion even if image deletion fails
                }
            }

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

    [HttpDelete("image")]
    [Authorize]
    public async Task<IActionResult> DeleteImage([FromBody] DeleteImageDto deleteImageDto)
    {
        try
        {
            var userId = JwtHelper.GetUserIdFromToken(User);
            
            // Get review to verify ownership
            var review = await _reviewService.GetReviewByIdAsync(deleteImageDto.ReviewId);
            if (review.UserId != userId)
            {
                return Forbid("You can only delete images from your own reviews");
            }

            // Remove the image URL from the review
            var updatedImageUrls = review.ImageUrls?.Where(url => url != deleteImageDto.ImageUrl).ToList() ?? new List<string>();
            
            var updateDto = new UpdateReviewDto
            {
                Id = deleteImageDto.ReviewId,
                Rating = review.Rating,
                Content = review.Content,
                ImageUrls = updatedImageUrls
            };

            await _reviewService.UpdateReviewAsync(updateDto, userId);

            // Delete the image from S3
            var deleted = await _imageUploadService.DeleteImageAsync(deleteImageDto.ImageUrl);
            
            return Ok(new { 
                message = deleted ? "Image deleted successfully" : "Image deletion completed",
                deleted = deleted
            });
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning(ex, "Unauthorized access attempt: {message}", ex.Message);
            return Unauthorized(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting image");
            return StatusCode(500, new { message = "An error occurred while deleting the image" });
        }
    }
}

public class CreateReviewWithImagesDto
{
    public Guid LocationId { get; set; }
    public int Rating { get; set; }
    public string Content { get; set; }
    public IFormFileCollection Images { get; set; }
}

public class DeleteImageDto
{
    public Guid ReviewId { get; set; }
    public string ImageUrl { get; set; }
}