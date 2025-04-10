using ReviewService.Application.DTOs;

namespace ReviewService.Application.Interfaces;

public interface IReviewService
{
    Task<IEnumerable<ReviewDto>> GetAllReviewsAsync();
    Task<ReviewDto> GetReviewByIdAsync(Guid id);
    Task<IEnumerable<ReviewDto>> GetReviewsByUserIdAsync(Guid userId);
    Task<IEnumerable<ReviewDto>> GetReviewsByLocationIdAsync(Guid locationId);
    Task<ReviewDto> CreateReviewAsync(CreateReviewDto createReviewDto, Guid userId);
    Task<ReviewDto> UpdateReviewAsync(UpdateReviewDto updateReviewDto, Guid userId);
    Task DeleteReviewAsync(Guid id, Guid userId);
    Task<double> GetAverageRatingForLocationAsync(Guid locationId);
}
