using System.Text;
using System.Text.Json;
using LocationService.Application.Interfaces;
using LocationService.Domain.Messages;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace LocationService.Infrastructure.Messaging;

public class LocationValidationConsumer : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<LocationValidationConsumer> _logger;
    private readonly RabbitMqSettings _settings;
    private IConnection _connection;
    private IModel _channel;
    private bool _isRabbitMqAvailable = false;

    public LocationValidationConsumer(
        IServiceProvider serviceProvider,
        IOptions<RabbitMqSettings> settings,
        ILogger<LocationValidationConsumer> logger)
    {
        _serviceProvider = serviceProvider;
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

            _logger.LogInformation($"Attempting to connect to RabbitMQ: {_settings.HostName}:{_settings.Port}");
            
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

                _channel.QueueDeclare(
                    queue: _settings.LocationValidationResponseQueue,
                    durable: true,
                    exclusive: false,
                    autoDelete: false);
                
                _channel.QueueBind(
                    queue: _settings.LocationValidationRequestQueue,
                    exchange: _settings.ExchangeName,
                    routingKey: _settings.LocationValidationRequestRoutingKey);

                _channel.QueueBind(
                    queue: _settings.LocationValidationResponseQueue,
                    exchange: _settings.ExchangeName,
                    routingKey: _settings.LocationValidationResponseRoutingKey);

                _isRabbitMqAvailable = true;
                _logger.LogInformation("RabbitMQ configuration completed successfully");
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "RabbitMQ is not available. The service will continue to run without messaging capabilities.");
                _isRabbitMqAvailable = false;
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Error setting up RabbitMQ connection for Location Validation Consumer. The service will continue to run without messaging capabilities.");
            _isRabbitMqAvailable = false;
        }
    }

    protected override Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!_isRabbitMqAvailable)
        {
            _logger.LogWarning("RabbitMQ is not available. Location validation through messaging will not be available.");
            return Task.CompletedTask;
        }

        _logger.LogInformation("Starting Location Validation Consumer");

        var consumer = new AsyncEventingBasicConsumer(_channel);

        consumer.Received += async (sender, args) =>
        {
            _logger.LogInformation($"Received message from queue. Delivery Tag: {args.DeliveryTag}");

            try 
            {
                var messageBody = Encoding.UTF8.GetString(args.Body.ToArray());
                _logger.LogInformation($"Raw message body: {messageBody}");

                var request = JsonSerializer.Deserialize<LocationValidationRequest>(messageBody);
                
                if (request == null)
                {
                    _logger.LogError("Failed to deserialize location validation request");
                    _channel.BasicNack(args.DeliveryTag, false, false);
                    return;
                }

                _logger.LogInformation($"Processing Location Validation Request. MessageId: {request.MessageId}, LocationId: {request.LocationId}");

                using var scope = _serviceProvider.CreateScope();
                var locationRepository = scope.ServiceProvider.GetRequiredService<ILocationRepository>();
                var publisher = scope.ServiceProvider.GetRequiredService<RabbitMqPublisher>();

                var response = new LocationValidationResponse
                {
                    RequestMessageId = request.MessageId,
                    LocationId = request.LocationId
                };

                try 
                {
                    response.Exists = await locationRepository.ExistsAsync(request.LocationId);
                    _logger.LogInformation($"Location Validation Result - LocationId: {request.LocationId}, Exists: {response.Exists}");
                }
                catch (Exception repoEx)
                {
                    _logger.LogError(repoEx, $"Error checking location existence for ID {request.LocationId}");
                    response.Exists = false;
                    response.ErrorMessage = repoEx.Message;
                }
                
                var responseJson = JsonSerializer.Serialize(response);
                var responseBody = Encoding.UTF8.GetBytes(responseJson);

                _channel.BasicPublish(
                    exchange: _settings.ExchangeName,
                    routingKey: _settings.LocationValidationResponseRoutingKey,
                    basicProperties: null,
                    body: responseBody);

                _logger.LogInformation($"Published Location Validation Response. MessageId: {request.MessageId}, LocationId: {request.LocationId}");
                
                _channel.BasicAck(args.DeliveryTag, false);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error processing location validation request");
                
                _channel.BasicNack(args.DeliveryTag, false, true);
            }
        };

        // Only set up the consumer if RabbitMQ is available
        if (_isRabbitMqAvailable)
        {
            try
            {
                // Use Basic Consume with explicit consumer
                _channel.BasicConsume(
                    queue: _settings.LocationValidationRequestQueue,
                    autoAck: false,
                    consumer: consumer);

                _logger.LogInformation("Location Validation Consumer is running and waiting for messages");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error configuring RabbitMQ consumer. Location validation through messaging will not be available.");
                _isRabbitMqAvailable = false;
            }
        }

        return Task.CompletedTask;
    }

    public override void Dispose()
    {
        _channel?.Close();
        _connection?.Close();
        base.Dispose();
    }
}