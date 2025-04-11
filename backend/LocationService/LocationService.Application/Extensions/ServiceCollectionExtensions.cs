// backend/LocationService/LocationService.Application/Extensions/ServiceCollectionExtensions.cs
using System.Reflection;
using FluentValidation;
using FluentValidation.AspNetCore;
using LocationService.Application.Handlers;
using MediatR;
using Microsoft.Extensions.DependencyInjection;

namespace LocationService.Application.Extensions
{
	public static class ServiceCollectionExtensions
	{
		public static IServiceCollection AddApplicationServices(this IServiceCollection services)
		{
			services.AddMediatR(cfg => 
				cfg.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly()));
			services.AddMediatR(cfg => {
				cfg.RegisterServicesFromAssembly(typeof(GetNearbyLocationsQueryHandler).Assembly);
			});
			
			services.AddFluentValidationAutoValidation();
			services.AddValidatorsFromAssembly(Assembly.GetExecutingAssembly());
            
			return services;
		}
	}
}