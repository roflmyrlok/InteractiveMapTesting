using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;

namespace ReviewService.Infrastructure.Data;

public class ReviewDbContextFactory : IDesignTimeDbContextFactory<ReviewDbContext>
{
    public ReviewDbContext CreateDbContext(string[] args)
    {
        var basePath = Directory.GetCurrentDirectory();
        
        // Try to find the API project directory
        if (!File.Exists(Path.Combine(basePath, "appsettings.json")))
        {
            basePath = Path.GetFullPath(Path.Combine(basePath, "../ReviewService.API"));
        }

        var configurationBuilder = new ConfigurationBuilder()
            .SetBasePath(basePath);

        // Add appsettings.json if it exists
        if (File.Exists(Path.Combine(basePath, "appsettings.json")))
        {
            configurationBuilder.AddJsonFile("appsettings.json", optional: false, reloadOnChange: true);
        }

        // Add environment-specific settings
        var environmentName = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Development";
        var environmentSettingsPath = $"appsettings.{environmentName}.json";
        
        if (File.Exists(Path.Combine(basePath, environmentSettingsPath)))
        {
            configurationBuilder.AddJsonFile(environmentSettingsPath, optional: true);
        }

        // Always add environment variables (this will override JSON settings)
        configurationBuilder.AddEnvironmentVariables();

        var configuration = configurationBuilder.Build();

        var optionsBuilder = new DbContextOptionsBuilder<ReviewDbContext>();
        
        // Get connection string from configuration (which will resolve environment variables)
        var connectionString = configuration.GetConnectionString("DefaultConnection");
        
        // Fallback connection strings for development
        if (string.IsNullOrEmpty(connectionString))
        {
            connectionString = Environment.GetEnvironmentVariable("REVIEWSERVICE_CONNECTION_STRING")
                              ?? Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
                              ?? "Host=localhost;Port=5432;Database=microservices;Username=postgres;Password=postgres_Secure_Pwd_123!";
        }

        Console.WriteLine($"Using connection string: {connectionString.Substring(0, Math.Min(50, connectionString.Length))}...");

        optionsBuilder.UseNpgsql(connectionString);

        return new ReviewDbContext(optionsBuilder.Options);
    }
}