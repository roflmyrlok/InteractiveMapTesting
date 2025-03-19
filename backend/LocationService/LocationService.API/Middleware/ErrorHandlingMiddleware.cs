using System.Net;
using System.Text.Json;
using LocationService.Domain.Exceptions;

namespace LocationService.API.Middleware
{
    public class ErrorHandlingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ErrorHandlingMiddleware> _logger;

        public ErrorHandlingMiddleware(RequestDelegate next, ILogger<ErrorHandlingMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (Exception ex)
            {
                await HandleExceptionAsync(context, ex);
            }
        }

        private async Task HandleExceptionAsync(HttpContext context, Exception exception)
        {
            _logger.LogError(exception, "An unhandled exception has occurred");

            var response = context.Response;
            response.ContentType = "application/json";

            var (status, errorMessage) = GetErrorDetails(exception);
            response.StatusCode = (int)status;

            var errorResponse = new ErrorResponse
            {
                StatusCode = response.StatusCode,
                Message = errorMessage
            };

            var result = JsonSerializer.Serialize(errorResponse);
            await response.WriteAsync(result);
        }

        private (HttpStatusCode, string) GetErrorDetails(Exception exception)
        {
            return exception switch
            {
                DomainException domainEx => 
                    (HttpStatusCode.BadRequest, domainEx.Message),
                UnauthorizedAccessException unAuthEx => 
                    (HttpStatusCode.Unauthorized, unAuthEx.Message),
                KeyNotFoundException notFoundEx => 
                    (HttpStatusCode.NotFound, notFoundEx.Message),
                _ => (HttpStatusCode.InternalServerError, "An unexpected error occurred.")
            };
        }
    }

    public class ErrorResponse
    {
        public int StatusCode { get; set; }
        public string Message { get; set; }
    }
    public static class ErrorHandlingMiddlewareExtensions
    {
        public static IApplicationBuilder UseCustomErrorHandling(this IApplicationBuilder builder)
        {
            return builder.UseMiddleware<ErrorHandlingMiddleware>();
        }
    }
}