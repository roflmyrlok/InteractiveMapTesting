using LocationService.Application.Interfaces;
using LocationService.Infrastructure.Data;
using LocationService.Infrastructure.Data.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace LocationService.Infrastructure.Extensions
{
	public static class ServiceCollectionExtensions
	{
		public static IServiceCollection AddInfrastructureServices(this IServiceCollection services, IConfiguration configuration)
		{
			services.AddDbContext<LocationDbContext>(options =>
				options.UseNpgsql(configuration.GetConnectionString("DefaultConnection"),
					b => b.MigrationsAssembly(typeof(LocationDbContext).Assembly.FullName)));
			
			services.AddScoped<ILocationRepository, LocationRepository>();
			services.AddScoped<ILocationDetailRepository, LocationDetailRepository>();
			return services;
		}
	}
}