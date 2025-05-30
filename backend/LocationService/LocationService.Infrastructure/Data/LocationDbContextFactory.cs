using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;

namespace LocationService.Infrastructure.Data
{
	public class LocationDbContextFactory : IDesignTimeDbContextFactory<LocationDbContext>
	{
		public LocationDbContext CreateDbContext(string[] args)
		{
			var basePath = Directory.GetCurrentDirectory();
			
			if (!File.Exists(Path.Combine(basePath, "appsettings.json")))
			{
				basePath = Path.GetFullPath(Path.Combine(basePath, "../LocationService.API"));
			}

			var configuration = new ConfigurationBuilder()
				.SetBasePath(basePath)
				.AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
				.AddJsonFile("appsettings.Development.json", optional: true)
				.AddEnvironmentVariables()
				.Build();

			var optionsBuilder = new DbContextOptionsBuilder<LocationDbContext>();
			var connectionString = configuration.GetConnectionString("DefaultConnection");

			optionsBuilder.UseNpgsql(connectionString);

			return new LocationDbContext(optionsBuilder.Options);
		}
	}
}