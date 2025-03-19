namespace ReviewService.Domain.Messages;

public class LocationValidationRequest
{
	public Guid MessageId { get; set; } = Guid.NewGuid();
	public Guid LocationId { get; set; }
	public string CorrelationId { get; set; }
	public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}