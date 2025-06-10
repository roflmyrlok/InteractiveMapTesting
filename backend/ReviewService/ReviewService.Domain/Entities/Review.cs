using System;
using System.Collections.Generic;

namespace ReviewService.Domain.Entities;

public class Review
{
	public Guid Id { get; set; }
	public Guid UserId { get; set; }
	public Guid LocationId { get; set; }
	public int Rating { get; set; }
	public required string Content { get; set; }
	public DateTime CreatedAt { get; set; }
	public DateTime? UpdatedAt { get; set; }
	public List<string> ImageUrls { get; set; } = new List<string>();
}
