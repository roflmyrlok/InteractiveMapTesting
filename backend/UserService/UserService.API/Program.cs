using System;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using UserService.API.Middleware;
using UserService.API.Services;
using UserService.Application.Extensions;
using UserService.Infrastructure.Data;
using UserService.Infrastructure.Extensions;

public partial class Program
{
	public static void Main(string[] args)
	{
		CreateHostBuilder(args).Build().Run();
	}

	public static IHostBuilder CreateHostBuilder(string[] args) =>
		Host.CreateDefaultBuilder(args)
			.ConfigureWebHostDefaults(webBuilder =>
			{
				webBuilder.UseStartup<Startup>();
			})
			.ConfigureAppConfiguration((hostingContext, config) =>
			{
				config.AddEnvironmentVariables();
			});
}

public class Startup
{
	private readonly IConfiguration _configuration;

	public Startup(IConfiguration configuration)
	{
		_configuration = configuration;
	}

	public void ConfigureServices(IServiceCollection services)
	{
		services.AddControllers();
		var connectionString = _configuration.GetConnectionString("DefaultConnection") 
		                       ?? throw new InvalidOperationException("Connection string not configured");
		services.AddDbContext<UserDbContext>(options =>
			options.UseNpgsql(connectionString));
        
		ConfigureJwtAuthentication(services);
        
		services.AddEndpointsApiExplorer();
		ConfigureSwagger(services);
        
		services.AddApplicationServices();
		services.AddInfrastructureServices(_configuration);
		services.AddScoped<JwtAuthenticationService>();
	}

	private void ConfigureJwtAuthentication(IServiceCollection services)
	{
		var jwtKey = _configuration["Jwt:Key"] 
		             ?? throw new InvalidOperationException("JWT Key is not configured");
		var jwtIssuer = _configuration["Jwt:Issuer"] 
		                ?? throw new InvalidOperationException("JWT Issuer is not configured");
		var jwtAudience = _configuration["Jwt:Audience"] 
		                  ?? throw new InvalidOperationException("JWT Audience is not configured");

		services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
			.AddJwtBearer(options =>
			{
				options.TokenValidationParameters = new TokenValidationParameters
				{
					ValidateIssuer = true,
					ValidateAudience = true,
					ValidateLifetime = true,
					ValidateIssuerSigningKey = true,
					ValidIssuer = jwtIssuer,
					ValidAudience = jwtAudience,
					IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
					ClockSkew = TimeSpan.Zero,
					// FIX: Add claim mapping to ensure standard claims are mapped correctly
					RoleClaimType = ClaimTypes.Role,
					NameClaimType = ClaimTypes.Name
				};

				options.Events = new JwtBearerEvents
				{
					OnAuthenticationFailed = context =>
					{
						var logger = context.HttpContext.RequestServices.GetRequiredService<ILogger<Program>>();
						logger.LogError("Authentication failed: {Exception}", context.Exception.Message);
                    
						if (context.Exception is SecurityTokenExpiredException)
						{
							logger.LogWarning("Token expired for request to {Path}", context.Request.Path);
						}
						else if (context.Exception is SecurityTokenInvalidIssuerException)
						{
							logger.LogWarning("Invalid issuer for token. Expected: {Expected}, Actual: {Actual}", 
								jwtIssuer, context.Exception.Message);
						}
						else if (context.Exception is SecurityTokenInvalidAudienceException)
						{
							logger.LogWarning("Invalid audience for token. Expected: {Expected}, Actual: {Actual}", 
								jwtAudience, context.Exception.Message);
						}
                    
						return Task.CompletedTask;
					},
					OnTokenValidated = context =>
					{
						var logger = context.HttpContext.RequestServices.GetRequiredService<ILogger<Program>>();
						
						// FIX: Enhanced token validation logging with multiple claim lookups
						var subClaim = context.Principal?.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
						var nameIdClaim = context.Principal?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
						var userIdClaim = context.Principal?.FindFirst("user_id")?.Value;
						
						var userId = subClaim ?? nameIdClaim ?? userIdClaim ?? "UNKNOWN";
						
						logger.LogInformation("Token validated successfully for user: {UserId}", userId);
						
						// Log all claims for debugging if user ID is null
						if (string.IsNullOrEmpty(subClaim))
						{
							logger.LogWarning("Sub claim is null/empty. All claims:");
							foreach (var claim in context.Principal?.Claims ?? Enumerable.Empty<Claim>())
							{
								logger.LogWarning("  {Type} = {Value}", claim.Type, claim.Value);
							}
						}
						
						return Task.CompletedTask;
					},
					OnMessageReceived = context =>
					{
						var logger = context.HttpContext.RequestServices.GetRequiredService<ILogger<Program>>();
						var hasAuthHeader = context.Request.Headers.ContainsKey("Authorization");
						logger.LogDebug("JWT message received. Has Authorization header: {HasAuth}", hasAuthHeader);
                    
						if (hasAuthHeader)
						{
							var authHeader = context.Request.Headers["Authorization"].FirstOrDefault();
							var hasBearerPrefix = authHeader?.StartsWith("Bearer ") == true;
							logger.LogDebug("Authorization header format correct: {HasBearer}", hasBearerPrefix);
							
							// FIX: Log partial token for debugging (first 20 chars only for security)
							if (hasBearerPrefix && authHeader.Length > 7)
							{
								var tokenStart = authHeader.Substring(7, Math.Min(20, authHeader.Length - 7));
								logger.LogDebug("Token starts with: {TokenStart}...", tokenStart);
							}
						}
                    
						return Task.CompletedTask;
					},
					OnChallenge = context =>
					{
						var logger = context.HttpContext.RequestServices.GetRequiredService<ILogger<Program>>();
						logger.LogWarning("Authentication challenge triggered for {Path}. Error: {Error}", 
							context.Request.Path, context.Error);
						
						// FIX: Log more details about why authentication failed
						if (!string.IsNullOrEmpty(context.ErrorDescription))
						{
							logger.LogWarning("Error description: {ErrorDescription}", context.ErrorDescription);
						}
						
						return Task.CompletedTask;
					}
				};
			});
	}

	private void ConfigureSwagger(IServiceCollection services)
	{
		services.AddSwaggerGen(c =>
		{
			c.SwaggerDoc("v1", new OpenApiInfo { Title = "User Service API", Version = "v1" });
            
			c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
			{
				Description = "JWT Authorization header using the Bearer scheme",
				Name = "Authorization",
				In = ParameterLocation.Header,
				Type = SecuritySchemeType.Http,
				Scheme = "bearer",
				BearerFormat = "JWT"
			});

			c.AddSecurityRequirement(new OpenApiSecurityRequirement
			{
				{
					new OpenApiSecurityScheme
					{
						Reference = new OpenApiReference
						{
							Type = ReferenceType.SecurityScheme,
							Id = "Bearer"
						}
					},
					Array.Empty<string>()
				}
			});
		});
	}

	public void Configure(IApplicationBuilder app, IWebHostEnvironment env, UserDbContext context)
	{
		context.Database.Migrate();

		if (env.IsDevelopment())
		{
			app.UseSwagger();
			app.UseSwaggerUI();
		}

		app.UseHttpsRedirection();
		app.UseMiddleware<ErrorHandlingMiddleware>();
		app.UseRouting();
		
		// FIX: Ensure proper order of middleware
		app.UseAuthentication();
		app.UseAuthorization();
		
		app.UseEndpoints(endpoints =>
		{
			endpoints.MapControllers();
		});
	}
}