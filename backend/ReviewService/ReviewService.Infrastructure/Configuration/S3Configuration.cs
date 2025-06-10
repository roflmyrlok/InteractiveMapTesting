using System.Collections.Generic;

namespace ReviewService.Infrastructure.Configuration;

public class S3Configuration
{
	public string AccessKey { get; set; } = string.Empty;
	public string SecretKey { get; set; } = string.Empty;
	public string BucketName { get; set; } = string.Empty;
	public string Region { get; set; } = "eu-central-1";
	public string BaseUrl { get; set; } = string.Empty;
	public int MaxFileSizeInMB { get; set; } = 5;
	public List<string> AllowedFileTypes { get; set; } = new() { "image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp" };
}