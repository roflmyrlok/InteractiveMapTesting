using AutoMapper;
using Microsoft.Extensions.Logging;
using ReviewService.Application.DTOs;
using ReviewService.Application.Interfaces;
using ReviewService.Domain.Entities;
using ReviewService.Domain.Exceptions;

namespace ReviewService.Application.Services;

public class ReviewService : IReviewService
{
    private readonly IReviewRepository _reviewRepository;
    private readonly ILocationService _locationService;
    private readonly IMapper _mapper;
    private readonly ILogger<ReviewService> _logger;

    public ReviewService(
        IReviewRepository reviewRepository, 
        ILocationService locationService, 
        IMapper mapper,
        ILogger<ReviewService> logger)
    {
        _reviewRepository = reviewRepository;
        _locationService = locationService;
        _mapper = mapper;
        _logger = logger;
    }

    public async Task<IEnumerable<ReviewDto>> GetAllReviewsAsync()
    {
        var reviews = await _reviewRepository.GetAllAsync();
        return _mapper.Map<IEnumerable<ReviewDto>>(reviews);
    }

    public async Task<ReviewDto> GetReviewByIdAsync(Guid id)
    {
        var review = await _reviewRepository.GetByIdAsync(id);
        if (review == null)
        {
            throw new DomainException($"Review with ID {id} not found");
        }

        return _mapper.Map<ReviewDto>(review);
    }

    public async Task<IEnumerable<ReviewDto>> GetReviewsByUserIdAsync(Guid userId)
    {
        var reviews = await _reviewRepository.FindAsync(r => r.UserId == userId);
        return _mapper.Map<IEnumerable<ReviewDto>>(reviews);
    }

    public async Task<IEnumerable<ReviewDto>> GetReviewsByLocationIdAsync(Guid locationId)
    {
        var reviews = await _reviewRepository.FindAsync(r => r.LocationId == locationId);
        return _mapper.Map<IEnumerable<ReviewDto>>(reviews);
    }
    
    public async Task<ReviewDto> CreateReviewAsync(CreateReviewDto createReviewDto, Guid userId)
    {
        bool locationExists = await _locationService.ValidateLocationExistsAsync(createReviewDto.LocationId);
        
        if (!locationExists)
        {
            throw new DomainException($"Unable to create review: Location with ID {createReviewDto.LocationId} does not exist");
        }

        var review = _mapper.Map<Review>(createReviewDto);
        review.Id = Guid.NewGuid();
        review.UserId = userId;
        review.CreatedAt = DateTime.UtcNow;

        await _reviewRepository.AddAsync(review);

        return _mapper.Map<ReviewDto>(review);
    }

    public async Task<ReviewDto> UpdateReviewAsync(UpdateReviewDto updateReviewDto, Guid userId)
    {
        var review = await _reviewRepository.GetByIdAsync(updateReviewDto.Id);
        if (review == null)
        {
            throw new DomainException($"Review with ID {updateReviewDto.Id} not found");
        }

        if (review.UserId != userId)
        {
            throw new DomainException("You can only update your own reviews");
        }

        _mapper.Map(updateReviewDto, review);
        review.UpdatedAt = DateTime.UtcNow;

        await _reviewRepository.UpdateAsync(review);

        return _mapper.Map<ReviewDto>(review);
    }

    public async Task DeleteReviewAsync(Guid id, Guid userId)
    {
        var review = await _reviewRepository.GetByIdAsync(id);
        if (review == null)
        {
            throw new DomainException($"Review with ID {id} not found");
        }

        if (review.UserId != userId)
        {
            throw new DomainException("You can only delete your own reviews");
        }

        await _reviewRepository.DeleteAsync(id);
    }

    public async Task<double> GetAverageRatingForLocationAsync(Guid locationId)
    {
        var reviews = await _reviewRepository.FindAsync(r => r.LocationId == locationId);
        var reviewsList = reviews.ToList();

        if (!reviewsList.Any())
        {
            return 0;
        }

        return reviewsList.Average(r => r.Rating);
    }
}