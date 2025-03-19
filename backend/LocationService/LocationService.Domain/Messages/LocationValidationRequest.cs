namespace LocationService.Domain.Messages;

public class LocationValidationRequest
{
	public Guid MessageId { get; set; }
	public Guid LocationId { get; set; }
	public string CorrelationId { get; set; }
	public DateTime Timestamp { get; set; }
}