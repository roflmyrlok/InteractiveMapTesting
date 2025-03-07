using FluentValidation;
using FluentValidation.AspNetCore;
using Microsoft.Extensions.DependencyInjection;
using UserService.Application.Interfaces;
using UserService.Application.Mapping;
using UserService.Application.Validators;

namespace UserService.Application.Extensions
{
	public static class ServiceCollectionExtensions
	{
		public static IServiceCollection AddApplicationServices(this IServiceCollection services)
		{
			// Register AutoMapper
			services.AddAutoMapper(typeof(MappingProfile));
            
			// Register application services
			services.AddScoped<IUserService, UserService.Application.Services.UserService>();
            
			// Register validators
			services.AddFluentValidationAutoValidation();
			services.AddValidatorsFromAssemblyContaining<CreateUserValidator>();
            
			return services;
		}
	}
}