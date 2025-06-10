using System;
using ReviewService.Domain.Enums;

namespace ReviewService.Domain.Entities;

public class LocationInstantFeedback
{
	public Guid Id { get; set; }
	public Guid LocationId { get; set; }
	public Guid UserId { get; set; }
	public InstantFeedbackType FeedbackType { get; set; }
	public DateTime CreatedAt { get; set; }
	public DateTime? UpdatedAt { get; set; }
}