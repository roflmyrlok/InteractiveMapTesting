using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using ReviewService.Domain.Messages;

namespace ReviewService.Infrastructure.Messaging;

public class RabbitMqPublisher : IDisposable
{
    private readonly ILogger<RabbitMqPublisher> _logger;
    private readonly RabbitMqSettings _settings;
    private IConnection _connection;
    private IModel _channel;
    private Func<string, Task> _responseHandler;
    private bool _isRabbitMqAvailable = false;

    public bool IsRabbitMqAvailable => _isRabbitMqAvailable;

    public RabbitMqPublisher(IOptions<RabbitMqSettings> settings, ILogger<RabbitMqPublisher> logger)
    {
        _settings = settings.Value;
        _logger = logger;

        try
        {
            var factory = new ConnectionFactory
            {
                HostName = _settings.HostName,
                UserName = _settings.UserName,
                Password = _settings.Password,
                Port = _settings.Port,
                DispatchConsumersAsync = true
            };

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
                queue: _settings.LocationValidationRequestQueue,
                exchange: _settings.ExchangeName,
                routingKey: _settings.LocationValidationRequestRoutingKey);

            _channel.QueueBind(
                queue: _settings.LocationValidationResponseQueue,
                exchange: _settings.ExchangeName,
                routingKey: _settings.LocationValidationResponseRoutingKey);

            var consumer = new AsyncEventingBasicConsumer(_channel);
            consumer.Received += async (model, ea) =>
            {
                try
                {
                    if (_responseHandler != null)
                    {
                        var body = ea.Body.ToArray();
                        var message = Encoding.UTF8.GetString(body);
                        await _responseHandler(message);
                    }

                    _channel.BasicAck(ea.DeliveryTag, false);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error processing received message");
                    _channel.BasicNack(ea.DeliveryTag, false, true);
                }
            };

            _channel.BasicConsume(
                queue: _settings.LocationValidationResponseQueue,
                autoAck: false,
                consumer: consumer);

            _isRabbitMqAvailable = true;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to connect to RabbitMQ. Messaging capabilities will be disabled.");
            _isRabbitMqAvailable = false;
        }
    }

    public void RegisterResponseHandler(Func<string, Task> handler)
    {
        _responseHandler = handler;
    }

    public void PublishLocationValidationRequest(LocationValidationRequest request)
    {
        if (!_isRabbitMqAvailable)
        {
            _logger.LogWarning("RabbitMQ is not available. Cannot publish location validation request.");
            return;
        }

        try
        {
            var messageJson = JsonSerializer.Serialize(request);
            var body = Encoding.UTF8.GetBytes(messageJson);

            _channel.BasicPublish(
                exchange: _settings.ExchangeName,
                routingKey: _settings.LocationValidationRequestRoutingKey,
                basicProperties: null,
                body: body);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error publishing location validation request");
            _isRabbitMqAvailable = false;
        }
    }

    public void Dispose()
    {
        _channel?.Close();
        _connection?.Close();
    }
}