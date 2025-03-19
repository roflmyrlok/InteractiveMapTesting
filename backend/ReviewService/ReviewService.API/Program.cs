using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using ReviewService.API.Middleware;
using ReviewService.Application.Extensions;
using ReviewService.Infrastructure.Data;
using ReviewService.Infrastructure.Extensions;
using ReviewService.Infrastructure.Messaging;

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
        services.AddLogging(configure => 
        {
            configure.AddConsole();
            configure.AddDebug();
        });
        
        var connectionString = _configuration.GetConnectionString("DefaultConnection") 
            ?? throw new InvalidOperationException("Connection string not configured");
        services.AddDbContext<ReviewDbContext>(options =>
            options.UseNpgsql(connectionString));
        
        ConfigureRabbitMq(services);
        
        ConfigureJwtAuthentication(services);
        
        services.AddEndpointsApiExplorer();
        ConfigureSwagger(services);
        
        services.AddApplicationServices();
        services.AddInfrastructureServices(_configuration);
    }

    private void ConfigureRabbitMq(IServiceCollection services)
    {
        services.Configure<RabbitMqSettings>(options =>
        {
            options.HostName = _configuration["RabbitMq:HostName"] ?? "rabbitmq";
            options.UserName = _configuration["RabbitMq:UserName"] ?? "guest";
            options.Password = _configuration["RabbitMq:Password"] ?? "guest";
            options.Port = int.Parse(_configuration["RabbitMq:Port"] ?? "5672");
            options.ExchangeName = _configuration["RabbitMq:ExchangeName"] ?? "microservices";
        });
        
        services.AddSingleton<RabbitMqPublisher>();
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
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
                };
            });
    }

    private void ConfigureSwagger(IServiceCollection services)
    {
        services.AddSwaggerGen(c =>
        {
            c.SwaggerDoc("v1", new OpenApiInfo { Title = "Review Service API", Version = "v1" });
            
            c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
            {
                Description = "JWT Authorization header using the Bearer scheme",
                Name = "Authorization",
                In = ParameterLocation.Header,
                Type= SecuritySchemeType.Http,
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

    public void Configure(IApplicationBuilder app, IWebHostEnvironment env, ReviewDbContext context, ILogger<Startup> logger)
    {
        try 
        {
            context.Database.Migrate();
            logger.LogInformation("Database migration completed successfully.");
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "An error occurred while migrating the database.");
            throw;
        }

        if (env.IsDevelopment())
        {
            app.UseSwagger();
            app.UseSwaggerUI();
        }

        app.UseHttpsRedirection();
        
        app.UseCustomErrorHandling();
        
        app.UseRouting();
        app.UseAuthentication();
        app.UseAuthorization();
        
        app.UseEndpoints(endpoints =>
        {
            endpoints.MapControllers();
        });
    }
}