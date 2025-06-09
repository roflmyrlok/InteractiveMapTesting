using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using ReviewService.API.Middleware;
using ReviewService.Application.Extensions;
using ReviewService.Infrastructure.Data;
using ReviewService.Infrastructure.Extensions;

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
                // Load environment variables first
                config.AddEnvironmentVariables();
                
                // Then process configuration to expand environment variable references
                var builtConfig = config.Build();
                config.Sources.Clear();
                
                // Re-add configuration sources with environment variable expansion
                config.AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
                      .AddJsonFile($"appsettings.{hostingContext.HostingEnvironment.EnvironmentName}.json", optional: true, reloadOnChange: true);
                
                config.AddEnvironmentVariables();
                
                // Custom configuration provider to expand ${VAR} syntax
                config.Add(new EnvironmentVariableExpansionConfigurationSource());
            });
}

// Custom configuration source to expand ${VAR} syntax in appsettings.json
public class EnvironmentVariableExpansionConfigurationSource : IConfigurationSource
{
    public IConfigurationProvider Build(IConfigurationBuilder builder)
    {
        return new EnvironmentVariableExpansionConfigurationProvider();
    }
}

public class EnvironmentVariableExpansionConfigurationProvider : ConfigurationProvider
{
    public override void Load()
    {
        var builder = new ConfigurationBuilder();
        builder.AddJsonFile("appsettings.json", optional: true);
        builder.AddJsonFile($"appsettings.{Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production"}.json", optional: true);
        
        var config = builder.Build();
        
        foreach (var kvp in config.AsEnumerable())
        {
            if (kvp.Value != null)
            {
                Data[kvp.Key] = ExpandEnvironmentVariables(kvp.Value);
            }
        }
    }
    
    private string ExpandEnvironmentVariables(string value)
    {
        if (string.IsNullOrEmpty(value)) return value;
        
        // Replace ${VAR_NAME} with environment variable values
        var result = value;
        var start = 0;
        
        while ((start = result.IndexOf("${", start)) >= 0)
        {
            var end = result.IndexOf("}", start + 2);
            if (end > start)
            {
                var varName = result.Substring(start + 2, end - start - 2);
                var varValue = Environment.GetEnvironmentVariable(varName) ?? "";
                result = result.Substring(0, start) + varValue + result.Substring(end + 1);
                start = start + varValue.Length;
            }
            else
            {
                break;
            }
        }
        
        return result;
    }
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
        
        ConfigureJwtAuthentication(services);
        
        services.AddEndpointsApiExplorer();
        ConfigureSwagger(services);
        
        services.AddApplicationServices();
        services.AddInfrastructureServices(_configuration);

        // Configure AWS credentials for S3
        var awsAccessKey = _configuration["S3:AccessKey"];
        var awsSecretKey = _configuration["S3:SecretKey"];
        var awsRegion = _configuration["S3:Region"] ?? "us-east-1";

        if (!string.IsNullOrEmpty(awsAccessKey) && !string.IsNullOrEmpty(awsSecretKey))
        {
            Environment.SetEnvironmentVariable("AWS_ACCESS_KEY_ID", awsAccessKey);
            Environment.SetEnvironmentVariable("AWS_SECRET_ACCESS_KEY", awsSecretKey);
            Environment.SetEnvironmentVariable("AWS_DEFAULT_REGION", awsRegion);
        }
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