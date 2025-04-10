using FluentValidation;
using FluentValidation.AspNetCore;
using Microsoft.Extensions.DependencyInjection;
using LocationService.Application.Interfaces;
using LocationService.Application.Services;
using LocationService.Application.Mapping;
using LocationService.Application.Validators;

namespace LocationService.Application.Extensions
{
	public static class ServiceCollectionExtensions
	{
		public static IServiceCollection AddApplicationServices(this IServiceCollection services)
		{
			services.AddAutoMapper(typeof(MappingProfile));
			
			services.AddScoped<ILocationService, Services.LocationService>();
			
			services.AddFluentValidationAutoValidation();
			services.AddValidatorsFromAssemblyContaining<CreateLocationValidator>();
            
			return services;
		}
	}
}