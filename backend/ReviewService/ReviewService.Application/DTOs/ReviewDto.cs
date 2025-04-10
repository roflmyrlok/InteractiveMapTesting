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
}

public class CreateReviewDto
{
    public Guid LocationId { get; set; }
    public int Rating { get; set; }
    public string Content { get; set; }
}

public class UpdateReviewDto
{
    public Guid Id { get; set; }
    public int Rating { get; set; }
    public string Content { get; set; }
}
