using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using UserService.Application.Interfaces;
using UserService.Infrastructure.Data;
using UserService.Infrastructure.Data.Repositories;



namespace UserService.Infrastructure.Extensions
{
	public static class ServiceCollectionExtensions
	{
		public static IServiceCollection AddInfrastructureServices(this IServiceCollection services, IConfiguration configuration)
		{
			services.AddDbContext<UserDbContext>(options =>
				options.UseNpgsql(
					configuration.GetConnectionString("DefaultConnection"),
					b => b.MigrationsAssembly(typeof(UserDbContext).Assembly.FullName)));
			services.AddScoped<IUserRepository, UserRepository>();

			return services;
		}
	}
}