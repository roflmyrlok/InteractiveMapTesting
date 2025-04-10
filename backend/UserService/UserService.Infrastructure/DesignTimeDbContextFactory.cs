using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using UserService.Infrastructure.Data;

namespace UserService.Infrastructure;

public class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<UserDbContext>
{
	public UserDbContext CreateDbContext(string[] args)
	{
		// Create a configuration builder
		var configurationBuilder = new ConfigurationBuilder()
			.SetBasePath(Directory.GetCurrentDirectory())
			.AddJsonFile("appsettings.json", optional: true)
			.AddEnvironmentVariables();

		// Build configuration
		var configuration = configurationBuilder.Build();

		// Create options builder
		var optionsBuilder = new DbContextOptionsBuilder<UserDbContext>();
        
		// Get connection string, with a fallback
		var connectionString = configuration.GetConnectionString("DefaultConnection") 
		                       ?? "Host=localhost;Port=5432;Database=microservices;Username=postgres;Password=postgres";

		// Configure PostgreSQL options
		optionsBuilder.UseNpgsql(connectionString, 
			options => options.MigrationsAssembly("UserService.Infrastructure"));

		return new UserDbContext(optionsBuilder.Options);
	}
}