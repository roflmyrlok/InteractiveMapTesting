using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ReviewService.Application.DTOs;
using ReviewService.Application.Interfaces;
using ReviewService.Domain.Entities;
using ReviewService.Domain.Enums;

namespace ReviewService.Application.Services;

public class LocationInstantFeedbackService : ILocationInstantFeedbackService
{
    private readonly ILocationInstantFeedbackRepository _feedbackRepository;
    private readonly ILocationInstantStatusRepository _statusRepository;

    public LocationInstantFeedbackService(
        ILocationInstantFeedbackRepository feedbackRepository,
        ILocationInstantStatusRepository statusRepository)
    {
        _feedbackRepository = feedbackRepository;
        _statusRepository = statusRepository;
    }

    public async Task SubmitInstantFeedbackAsync(Guid userId, LocationInstantFeedbackDto feedbackDto)
    {
        // Check if user already has feedback for this location
        var existingFeedback = await _feedbackRepository.GetByLocationAndUserAsync(feedbackDto.LocationId, userId);
        
        if (existingFeedback != null)
        {
            // Update existing feedback (re-do previous)
            var oldType = existingFeedback.FeedbackType;
            existingFeedback.FeedbackType = feedbackDto.FeedbackType;
            existingFeedback.UpdatedAt = DateTime.UtcNow;
            
            await _feedbackRepository.UpdateAsync(existingFeedback);
            await UpdateLocationInstantStatusAsync(feedbackDto.LocationId, oldType, feedbackDto.FeedbackType);
        }
        else
        {
            // Create new feedback
            var feedback = new LocationInstantFeedback
            {
                Id = Guid.NewGuid(),
                LocationId = feedbackDto.LocationId,
                UserId = userId,
                FeedbackType = feedbackDto.FeedbackType,
                CreatedAt = DateTime.UtcNow
            };
            
            await _feedbackRepository.AddAsync(feedback);
            await UpdateLocationInstantStatusAsync(feedbackDto.LocationId, null, feedbackDto.FeedbackType);
        }
    }

    public async Task<LocationInstantStatusDto?> GetLocationInstantStatusAsync(Guid locationId)
    {
        var status = await _statusRepository.GetByLocationIdAsync(locationId);
        
        if (status == null)
        {
            // Return default teal status for locations with no feedback
            return new LocationInstantStatusDto
            {
                LocationId = locationId,
                ColorCode = "teal",
                AllGoodCount = 0,
                ProblemInsideCount = 0,
                CantGetInCount = 0,
                LastUpdated = DateTime.UtcNow,
                DominantStatus = InstantFeedbackType.AllGood
            };
        }

        return new LocationInstantStatusDto
        {
            LocationId = status.LocationId,
            ColorCode = status.ColorCode,
            AllGoodCount = status.AllGoodCount,
            ProblemInsideCount = status.ProblemInsideCount,
            CantGetInCount = status.CantGetInCount,
            LastUpdated = status.LastUpdated,
            DominantStatus = status.DominantStatus
        };
    }

    public async Task<List<LocationInstantStatusSummaryDto>> GetLocationInstantStatusSummariesAsync(List<Guid> locationIds)
    {
        var statuses = await _statusRepository.GetByLocationIdsAsync(locationIds);
        var statusDict = statuses.ToDictionary(s => s.LocationId);

        var result = new List<LocationInstantStatusSummaryDto>();

        foreach (var locationId in locationIds)
        {
            if (statusDict.TryGetValue(locationId, out var status))
            {
                result.Add(new LocationInstantStatusSummaryDto
                {
                    LocationId = locationId,
                    ColorCode = status.ColorCode
                });
            }
            else
            {
                // Default teal for locations with no feedback
                result.Add(new LocationInstantStatusSummaryDto
                {
                    LocationId = locationId,
                    ColorCode = "teal"
                });
            }
        }

        return result;
    }

    private async Task UpdateLocationInstantStatusAsync(Guid locationId, InstantFeedbackType? oldType, InstantFeedbackType newType)
    {
        var status = await _statusRepository.GetByLocationIdAsync(locationId);
        
        if (status == null)
        {
            status = new LocationInstantStatus
            {
                Id = Guid.NewGuid(),
                LocationId = locationId,
                AllGoodCount = 0,
                ProblemInsideCount = 0,
                CantGetInCount = 0
            };
        }

        // Decrement old type count if updating existing feedback
        if (oldType.HasValue)
        {
            DecrementCount(status, oldType.Value);
        }

        // Increment new type count
        IncrementCount(status, newType);
        
        // Recalculate the status and color
        status.RecalculateStatus();

        // Save or update the status
        if (await _statusRepository.GetByLocationIdAsync(locationId) == null)
        {
            await _statusRepository.AddAsync(status);
        }
        else
        {
            await _statusRepository.UpdateAsync(status);
        }
    }

    private static void IncrementCount(LocationInstantStatus status, InstantFeedbackType type)
    {
        switch (type)
        {
            case InstantFeedbackType.AllGood:
                status.AllGoodCount++;
                break;
            case InstantFeedbackType.ProblemInside:
                status.ProblemInsideCount++;
                break;
            case InstantFeedbackType.CantGetIn:
                status.CantGetInCount++;
                break;
        }
    }

    private static void DecrementCount(LocationInstantStatus status, InstantFeedbackType type)
    {
        switch (type)
        {
            case InstantFeedbackType.AllGood:
                status.AllGoodCount = Math.Max(0, status.AllGoodCount - 1);
                break;
            case InstantFeedbackType.ProblemInside:
                status.ProblemInsideCount = Math.Max(0, status.ProblemInsideCount - 1);
                break;
            case InstantFeedbackType.CantGetIn:
                status.CantGetInCount = Math.Max(0, status.CantGetInCount - 1);
                break;
        }
    }
}