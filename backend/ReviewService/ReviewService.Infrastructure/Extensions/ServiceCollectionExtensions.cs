using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ReviewService.Application.Interfaces;
using ReviewService.Infrastructure.Data;
using ReviewService.Infrastructure.Data.Repositories;
using ReviewService.Infrastructure.Messaging;
using ReviewService.Infrastructure.Services;

namespace ReviewService.Infrastructure.Extensions;

public static class ServiceCollectionExtensions
{
	public static IServiceCollection AddInfrastructureServices(this IServiceCollection services, IConfiguration configuration)
	{
		services.AddDbContext<ReviewDbContext>(options =>
			options.UseNpgsql(
				configuration.GetConnectionString("DefaultConnection"),
				b => b.MigrationsAssembly(typeof(ReviewDbContext).Assembly.FullName)));
            
		services.AddScoped<IReviewRepository, ReviewRepository>();
    
		services.Configure<RabbitMqSettings>(configuration.GetSection("RabbitMq"));
        
		services.AddSingleton<RabbitMqPublisher>();

		services.AddScoped<ILocationService, RabbitMqLocationService>();
    
		return services;
	}
}