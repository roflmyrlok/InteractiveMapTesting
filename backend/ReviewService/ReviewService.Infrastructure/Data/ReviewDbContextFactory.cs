using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;

namespace ReviewService.Infrastructure.Data;

public class ReviewDbContextFactory : IDesignTimeDbContextFactory<ReviewDbContext>
{
    public ReviewDbContext CreateDbContext(string[] args)
    {
        var basePath = Directory.GetCurrentDirectory();
        
        if (!File.Exists(Path.Combine(basePath, "appsettings.json")))
        {
            basePath = Path.GetFullPath(Path.Combine(basePath, "../ReviewService.API"));
        }

        var configuration = new ConfigurationBuilder()
            .SetBasePath(basePath)
            .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
            .Build();

        var optionsBuilder = new DbContextOptionsBuilder<ReviewDbContext>();
        var connectionString = configuration.GetConnectionString("DefaultConnection");

        optionsBuilder.UseNpgsql(connectionString);

        return new ReviewDbContext(optionsBuilder.Options);
    }
}
