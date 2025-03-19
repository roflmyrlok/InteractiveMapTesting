using System.Text;
using System.Text.Json;
using LocationService.Domain.Messages;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using RabbitMQ.Client;

namespace LocationService.Infrastructure.Messaging;

public class RabbitMqPublisher : IDisposable
{
    private readonly ILogger<RabbitMqPublisher> _logger;
    private readonly RabbitMqSettings _settings;
    private IConnection _connection;
    private IModel _channel;
    private bool _isRabbitMqAvailable = false;

    public RabbitMqPublisher(IOptions<RabbitMqSettings> settings, ILogger<RabbitMqPublisher> logger)
    {
        _settings = settings.Value;
        _logger = logger;

        var factory = new ConnectionFactory
        {
            HostName = _settings.HostName,
            UserName = _settings.UserName,
            Password = _settings.Password,
            Port = _settings.Port
        };

        try
        {
            _connection = factory.CreateConnection();
            _channel = _connection.CreateModel();
            
            _channel.ExchangeDeclare(
                exchange: _settings.ExchangeName,
                type: ExchangeType.Direct,
                durable: true,
                autoDelete: false);
            
            _channel.QueueDeclare(
                queue: _settings.LocationValidationRequestQueue,
                durable: _settings.QueueDurable,
                exclusive: _settings.QueueExclusive,
                autoDelete: _settings.QueueAutoDelete,
                arguments: new Dictionary<string, object>
                {
                    { "x-dead-letter-exchange", _settings.DeadLetterExchange },
                    { "x-dead-letter-routing-key", _settings.LocationValidationRequestQueue + _settings.DeadLetterSuffix }
                });
            
            _channel.QueueBind(
                queue: _settings.LocationValidationResponseQueue,
                exchange: _settings.ExchangeName,
                routingKey: _settings.LocationValidationResponseRoutingKey);

            _isRabbitMqAvailable = true;
            _logger.LogInformation("RabbitMQ connection established and channels configured for publisher");
        }
        catch (Exception ex)
        {
            _isRabbitMqAvailable = false;
            _logger.LogWarning(ex, "RabbitMQ is not available. Publishing messages will be disabled.");
        }
    }

    public void PublishLocationValidationResponse(LocationValidationResponse response)
    {
        if (!_isRabbitMqAvailable)
        {
            _logger.LogWarning("RabbitMQ is not available. Cannot publish location validation response.");
            return;
        }

        try
        {
            var messageJson = JsonSerializer.Serialize(response);
            var body = Encoding.UTF8.GetBytes(messageJson);

            _channel.BasicPublish(
                exchange: _settings.ExchangeName,
                routingKey: _settings.LocationValidationResponseRoutingKey,
                basicProperties: null,
                body: body);

            _logger.LogInformation($"Location validation response published for LocationId: {response.LocationId}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error publishing location validation response for LocationId: {response.LocationId}");
            _isRabbitMqAvailable = false;
        }
    }

    public void Dispose()
    {
        _channel?.Close();
        _connection?.Close();
    }
}