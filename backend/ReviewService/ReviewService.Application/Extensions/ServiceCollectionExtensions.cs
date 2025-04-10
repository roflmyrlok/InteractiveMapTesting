using FluentValidation;
using FluentValidation.AspNetCore;
using Microsoft.Extensions.DependencyInjection;
using ReviewService.Application.Interfaces;
using ReviewService.Application.Mapping;
using ReviewService.Application.Validators;

namespace ReviewService.Application.Extensions;

public static class ServiceCollectionExtensions
{
	public static IServiceCollection AddApplicationServices(this IServiceCollection services)
	{
		services.AddAutoMapper(typeof(MappingProfile));
        
		services.AddScoped<IReviewService, Services.ReviewService>();
        
		services.AddFluentValidationAutoValidation();
		services.AddValidatorsFromAssemblyContaining<CreateReviewValidator>();
        
		return services;
	}
}