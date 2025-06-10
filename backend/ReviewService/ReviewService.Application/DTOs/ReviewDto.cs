using System;
using System.Collections.Generic;

namespace ReviewService.Application.DTOs;

public class ReviewDto
{
	public Guid Id { get; set; }
	public Guid UserId { get; set; }
	public Guid LocationId { get; set; }
	public int Rating { get; set; }
	public string Content { get; set; }
	public DateTime CreatedAt { get; set; }
	public DateTime? UpdatedAt { get; set; }
	public List<string> ImageUrls { get; set; } = new List<string>();
}

public class CreateReviewDto
{
	public Guid LocationId { get; set; }
	public int Rating { get; set; }
	public string Content { get; set; }
	public List<string> ImageUrls { get; set; } = new List<string>();
}

public class UpdateReviewDto
{
	public Guid Id { get; set; }
	public int Rating { get; set; }
	public string Content { get; set; }
	public List<string> ImageUrls { get; set; } = new List<string>();
}	