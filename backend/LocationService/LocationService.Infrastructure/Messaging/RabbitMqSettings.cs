public class RabbitMqSettings
{
	public string HostName { get; set; } = "rabbitmq";
	public string UserName { get; set; } = "guest";
	public string Password { get; set; } = "guest";
	public int Port { get; set; } = 5672;
	public string ExchangeName { get; set; } = "microservices";

	public string LocationValidationRequestQueue { get; set; } = "location-validation-requests";
	public string LocationValidationRequestRoutingKey { get; set; } = "location.validation.request";

	public string LocationValidationResponseQueue { get; set; } = "location-validation-responses";
	public string LocationValidationResponseRoutingKey { get; set; } = "location.validation.response";
	
	public bool QueueDurable { get; set; } = true;
	public bool QueueExclusive { get; set; } = false;
	public bool QueueAutoDelete { get; set; } = false;
	public string DeadLetterExchange { get; set; } = "";
	public string DeadLetterSuffix { get; set; } = ".dlq";
}