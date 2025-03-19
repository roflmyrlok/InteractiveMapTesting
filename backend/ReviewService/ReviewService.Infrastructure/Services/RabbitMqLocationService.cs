using System.Text.Json;
using Microsoft.Extensions.Logging;
using ReviewService.Application.Interfaces;
using ReviewService.Domain.Messages;
using ReviewService.Domain.Exceptions;
using ReviewService.Infrastructure.Messaging;

namespace ReviewService.Infrastructure.Services;

public class RabbitMqLocationService : ILocationService
{
    private readonly RabbitMqPublisher _publisher;
    private readonly ILogger<RabbitMqLocationService> _logger;
    private readonly Dictionary<Guid, TaskCompletionSource<bool>> _pendingRequests = new();
    private readonly SemaphoreSlim _semaphore = new(1, 1);
    private bool _isRabbitMqAvailable = false;

    public RabbitMqLocationService(
        RabbitMqPublisher publisher,
        ILogger<RabbitMqLocationService> logger)
    {
        _publisher = publisher;
        _logger = logger;

        try
        {
            _publisher.RegisterResponseHandler(HandleLocationValidationResponse);
            _isRabbitMqAvailable = _publisher.IsRabbitMqAvailable;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to initialize RabbitMQ location service. Location validation will not be available.");
            _isRabbitMqAvailable = false;
        }
    }

    public async Task<bool> ValidateLocationExistsAsync(Guid locationId)
    {
        if (!_isRabbitMqAvailable)
        {
            _logger.LogError("RabbitMQ is not available. Cannot validate location existence.");
            throw new DomainException("Location validation service is currently unavailable. Please try again later.");
        }

        var request = new LocationValidationRequest
        {
            MessageId = Guid.NewGuid(),
            LocationId = locationId,
            CorrelationId = Guid.NewGuid().ToString(),
            Timestamp = DateTime.UtcNow
        };

        var completionSource = new TaskCompletionSource<bool>();
        
        await _semaphore.WaitAsync();
        try
        {
            _pendingRequests[request.MessageId] = completionSource;
        }
        finally
        {
            _semaphore.Release();
        }

        _publisher.PublishLocationValidationRequest(request);
        
        var timeoutTask = Task.Delay(TimeSpan.FromSeconds(5));
        var completedTask = await Task.WhenAny(completionSource.Task, timeoutTask);
        
        if (completedTask == timeoutTask)
        {
            _logger.LogWarning($"Location validation request timed out for location ID: {locationId}");
            await CleanupRequest(request.MessageId);
            throw new DomainException("Location validation service timed out. Please try again later.");
        }

        return await completionSource.Task;
    }

    private async Task CleanupRequest(Guid requestId)
    {
        await _semaphore.WaitAsync();
        try
        {
            _pendingRequests.Remove(requestId);
        }
        finally
        {
            _semaphore.Release();
        }
    }

    private async Task HandleLocationValidationResponse(string message)
    {
        var response = JsonSerializer.Deserialize<LocationValidationResponse>(message);
        if (response == null)
        {
            _logger.LogError("Failed to deserialize location validation response");
            return;
        }
        
        await _semaphore.WaitAsync();
        try
        {
            if (_pendingRequests.TryGetValue(response.RequestMessageId, out var completionSource))
            {
                _pendingRequests.Remove(response.RequestMessageId);
                completionSource.SetResult(response.Exists);
            }
        }
        finally
        {
            _semaphore.Release();
        }
    }
}