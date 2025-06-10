using Amazon.S3;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ReviewService.Application.Interfaces;
using ReviewService.Infrastructure.Configuration;
using ReviewService.Infrastructure.Data;
using ReviewService.Infrastructure.Data.Repositories;
using ReviewService.Infrastructure.Services;
using ReviewService.Infrastructure.Repositories;

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
        
        services.AddScoped<ILocationInstantFeedbackRepository, LocationInstantFeedbackRepository>();
        services.AddScoped<ILocationInstantStatusRepository, LocationInstantStatusRepository>();
        
        services.Configure<ServicesConfiguration>(configuration.GetSection("Services"));
        services.Configure<S3Configuration>(configuration.GetSection("S3"));
        
        services.AddHttpClient<ILocationService, HttpLocationService>((serviceProvider, client) => 
        {
            var servicesConfig = serviceProvider.GetRequiredService<Microsoft.Extensions.Options.IOptions<ServicesConfiguration>>().Value;
            client.BaseAddress = new Uri(servicesConfig.LocationService.BaseUrl);
            client.Timeout = TimeSpan.FromSeconds(5);
        });
        
        services.AddAWSService<IAmazonS3>();
        services.AddScoped<IImageUploadService, S3ImageUploadService>();
    
        return services;
    }
}