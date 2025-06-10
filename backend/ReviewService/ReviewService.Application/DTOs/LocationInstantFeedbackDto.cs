using System;
using System.Collections.Generic;
using ReviewService.Domain.Enums;

namespace ReviewService.Application.DTOs;

public class LocationInstantFeedbackDto
{
	public Guid LocationId { get; set; }
	public InstantFeedbackType FeedbackType { get; set; }
}

public class LocationInstantStatusDto
{
	public Guid LocationId { get; set; }
	public string ColorCode { get; set; } = string.Empty;
	public int AllGoodCount { get; set; }
	public int ProblemInsideCount { get; set; }
	public int CantGetInCount { get; set; }
	public DateTime LastUpdated { get; set; }
	public InstantFeedbackType DominantStatus { get; set; }
}

public class LocationInstantStatusSummaryDto
{
	public Guid LocationId { get; set; }
	public string ColorCode { get; set; } = string.Empty;
}

public class SubmitInstantFeedbackRequest
{
	public Guid LocationId { get; set; }
	public InstantFeedbackType FeedbackType { get; set; }
}

public class GetLocationInstantStatusesRequest
{
	public List<Guid> LocationIds { get; set; } = new List<Guid>();
}