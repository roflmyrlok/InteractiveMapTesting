namespace LocationService.Domain.Messages;

public class LocationValidationResponse
{
	public Guid MessageId { get; set; } = Guid.NewGuid();
	public Guid RequestMessageId { get; set; }
	public Guid LocationId { get; set; }
	public bool Exists { get; set; }
	public string ErrorMessage { get; set; }
	public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}