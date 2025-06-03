using Amazon;
using Amazon.S3;
using Amazon.S3.Model;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ReviewService.Application.Interfaces;
using ReviewService.Domain.Exceptions;
using ReviewService.Infrastructure.Configuration;

namespace ReviewService.Infrastructure.Services;

public class S3ImageUploadService : IImageUploadService
{
    private readonly IAmazonS3 _s3Client;
    private readonly S3Configuration _s3Config;
    private readonly ILogger<S3ImageUploadService> _logger;

    public S3ImageUploadService(
        IAmazonS3 s3Client,
        IOptions<S3Configuration> s3Config,
        ILogger<S3ImageUploadService> logger)
    {
        _s3Client = s3Client;
        _s3Config = s3Config.Value;
        _logger = logger;
    }

    public async Task<string> UploadImageAsync(IFormFile file, Guid reviewId)
    {
        if (!IsValidImageFile(file))
        {
            throw new DomainException("Invalid image file. Please upload a valid image file (JPEG, PNG, GIF, WebP).");
        }

        if (file.Length > _s3Config.MaxFileSizeInMB * 1024 * 1024)
        {
            throw new DomainException($"File size exceeds the maximum limit of {_s3Config.MaxFileSizeInMB}MB.");
        }

        try
        {
            var fileName = GenerateFileName(file.FileName, reviewId);
            var key = $"reviews/{reviewId}/{fileName}";

            using var stream = file.OpenReadStream();
            
            var request = new PutObjectRequest
            {
                BucketName = _s3Config.BucketName,
                Key = key,
                InputStream = stream,
                ContentType = file.ContentType,
                // Store privately - no public access needed
                ServerSideEncryptionMethod = ServerSideEncryptionMethod.AES256,
                Metadata =
                {
                    ["uploaded-by"] = "review-service",
                    ["review-id"] = reviewId.ToString(),
                    ["original-filename"] = file.FileName
                }
            };

            _logger.LogInformation("Attempting to upload image {FileName} for review {ReviewId} to S3 bucket {BucketName} with key {Key}", 
                file.FileName, reviewId, _s3Config.BucketName, key);

            var response = await _s3Client.PutObjectAsync(request);

            if (response.HttpStatusCode == System.Net.HttpStatusCode.OK)
            {
                // Return internal reference that will be served through our API
                var imageUrl = $"/api/reviews/images/{reviewId}/{fileName}";

                _logger.LogInformation("Successfully uploaded image {FileName} for review {ReviewId}. Internal URL: {ImageUrl}", 
                    file.FileName, reviewId, imageUrl);

                return imageUrl;
            }
            else
            {
                _logger.LogError("S3 upload failed with status code: {StatusCode}", response.HttpStatusCode);
                throw new DomainException("Failed to upload image to S3.");
            }
        }
        catch (AmazonS3Exception ex)
        {
            _logger.LogError(ex, "S3 error occurred while uploading image for review {ReviewId}. Error Code: {ErrorCode}, Status Code: {StatusCode}", 
                reviewId, ex.ErrorCode, ex.StatusCode);
            throw new DomainException($"Failed to upload image: {ex.Message}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error occurred while uploading image for review {ReviewId}", reviewId);
            throw new DomainException("An unexpected error occurred while uploading the image.");
        }
    }

    public async Task<List<string>> UploadImagesAsync(IFormFileCollection files, Guid reviewId)
    {
        if (files == null || files.Count == 0)
        {
            return new List<string>();
        }

        if (files.Count > 5) // Limit to 5 images per review
        {
            throw new DomainException("Maximum 5 images allowed per review.");
        }

        var uploadTasks = files.Select(file => UploadImageAsync(file, reviewId)).ToArray();
        
        try
        {
            var imageUrls = await Task.WhenAll(uploadTasks);
            return imageUrls.ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error occurred while uploading multiple images for review {ReviewId}", reviewId);
            throw;
        }
    }

    public async Task<bool> DeleteImageAsync(string imageUrl)
    {
        try
        {
            var key = ExtractKeyFromInternalUrl(imageUrl);
            if (string.IsNullOrEmpty(key))
            {
                _logger.LogWarning("Could not extract S3 key from internal URL: {ImageUrl}", imageUrl);
                return false;
            }

            var request = new DeleteObjectRequest
            {
                BucketName = _s3Config.BucketName,
                Key = key
            };

            _logger.LogInformation("Attempting to delete image with key: {Key} from bucket: {BucketName}", key, _s3Config.BucketName);

            var response = await _s3Client.DeleteObjectAsync(request);
            
            _logger.LogInformation("Successfully deleted image with key: {Key}", key);
            return response.HttpStatusCode == System.Net.HttpStatusCode.NoContent;
        }
        catch (AmazonS3Exception ex)
        {
            _logger.LogError(ex, "S3 error occurred while deleting image: {ImageUrl}. Error Code: {ErrorCode}", imageUrl, ex.ErrorCode);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error occurred while deleting image: {ImageUrl}", imageUrl);
            return false;
        }
    }

    public async Task<bool> DeleteImagesAsync(List<string> imageUrls)
    {
        if (imageUrls == null || imageUrls.Count == 0)
        {
            return true;
        }

        var deleteTasks = imageUrls.Select(DeleteImageAsync).ToArray();
        var results = await Task.WhenAll(deleteTasks);
        
        return results.All(result => result);
    }

    public bool IsValidImageFile(IFormFile file)
    {
        if (file == null || file.Length == 0)
        {
            return false;
        }

        // Check file extension
        var extension = Path.GetExtension(file.FileName)?.ToLowerInvariant();
        var validExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
        
        if (!validExtensions.Contains(extension))
        {
            return false;
        }

        // Check MIME type
        return _s3Config.AllowedFileTypes.Contains(file.ContentType?.ToLowerInvariant());
    }

    public async Task<ImageStreamResult> GetImageStreamAsync(string imageKey)
    {
        try
        {
            var request = new GetObjectRequest
            {
                BucketName = _s3Config.BucketName,
                Key = imageKey
            };

            var response = await _s3Client.GetObjectAsync(request);

            return new ImageStreamResult
            {
                Stream = response.ResponseStream,
                ContentType = response.Headers.ContentType,
                ContentLength = response.Headers.ContentLength
            };
        }
        catch (AmazonS3Exception ex)
        {
            _logger.LogError(ex, "S3 error occurred while retrieving image with key: {Key}. Error Code: {ErrorCode}", imageKey, ex.ErrorCode);
            throw;
        }
    }

    private string GenerateFileName(string originalFileName, Guid reviewId)
    {
        var extension = Path.GetExtension(originalFileName);
        var timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        var uniqueId = Guid.NewGuid().ToString("N")[..8];
        
        return $"{timestamp}_{uniqueId}{extension}";
    }

    private string ExtractKeyFromInternalUrl(string imageUrl)
    {
        try
        {
            if (string.IsNullOrEmpty(imageUrl))
                return string.Empty;

            // Extract from internal URL format: /api/reviews/images/{reviewId}/{fileName}
            if (imageUrl.StartsWith("/api/reviews/images/"))
            {
                var pathParts = imageUrl.Split('/');
                if (pathParts.Length >= 5)
                {
                    var reviewId = pathParts[4];
                    var fileName = pathParts[5];
                    return $"reviews/{reviewId}/{fileName}";
                }
            }

            return string.Empty;
        }
        catch
        {
            return string.Empty;
        }
    }
}
