using Microsoft.AspNetCore.Http;

namespace ReviewService.Application.Interfaces;

public interface IImageUploadService
{
	Task<string> UploadImageAsync(IFormFile file, Guid reviewId);
	Task<List<string>> UploadImagesAsync(IFormFileCollection files, Guid reviewId);
	Task<bool> DeleteImageAsync(string imageUrl);
	Task<bool> DeleteImagesAsync(List<string> imageUrls);
	bool IsValidImageFile(IFormFile file);
	Task<ImageStreamResult> GetImageStreamAsync(string imageKey);
}

public class ImageStreamResult
{
	public Stream Stream { get; set; }
	public string ContentType { get; set; }
	public long ContentLength { get; set; }
}
