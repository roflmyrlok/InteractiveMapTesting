using System;
using System.Net;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using UserService.Domain.Exceptions;

namespace UserService.API.Middleware;

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
			await HandleExceptionAsync(context, ex, _logger);
		}
	}

	private static async Task HandleExceptionAsync(HttpContext context, Exception exception, ILogger<ErrorHandlingMiddleware> logger)
	{
		logger.LogError(exception, "An unhandled exception has occurred");

		var code = HttpStatusCode.InternalServerError;
		var result = string.Empty;

		switch (exception)
		{
			case DomainException domainException:
				code = HttpStatusCode.BadRequest;
				result = JsonSerializer.Serialize(new { error = domainException.Message });
				break;
			default:
				code = HttpStatusCode.InternalServerError;
				result = JsonSerializer.Serialize(new { error = "An error occurred. Please try again later." });
				break;
		}

		context.Response.ContentType = "application/json";
		context.Response.StatusCode = (int)code;

		await context.Response.WriteAsync(result);
	}
}