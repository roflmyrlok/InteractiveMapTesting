using ReviewService.Domain.Enums;

namespace ReviewService.Domain.Entities;

public class LocationInstantStatus
{
	public Guid Id { get; set; }
	public Guid LocationId { get; set; }
	public int AllGoodCount { get; set; }
	public int ProblemInsideCount { get; set; }
	public int CantGetInCount { get; set; }
	public InstantFeedbackType DominantStatus { get; private set; }
	public string ColorCode { get; private set; } = "teal";
	public DateTime LastUpdated { get; set; }

	public void RecalculateStatus()
	{
		var totalFeedback = AllGoodCount + ProblemInsideCount + CantGetInCount;
        
		if (totalFeedback == 0)
		{
			ColorCode = "teal";
			DominantStatus = InstantFeedbackType.AllGood;
			LastUpdated = DateTime.UtcNow;
			return;
		}

		var maxCount = Math.Max(AllGoodCount, Math.Max(ProblemInsideCount, CantGetInCount));
		var sumOfOthers = totalFeedback - maxCount;

		if (maxCount > sumOfOthers)
		{
			if (maxCount == AllGoodCount)
			{
				DominantStatus = InstantFeedbackType.AllGood;
				ColorCode = "green";
			}
			else if (maxCount == ProblemInsideCount)
			{
				DominantStatus = InstantFeedbackType.ProblemInside;
				ColorCode = "yellow";
			}
			else if (maxCount == CantGetInCount)
			{
				DominantStatus = InstantFeedbackType.CantGetIn;
				ColorCode = "red";
			}
		}
		else
		{
			ColorCode = "purple";
			// Keep the current dominant status when tied
		}

		LastUpdated = DateTime.UtcNow;
	}
}