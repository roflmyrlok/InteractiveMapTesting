using FluentValidation;
using UserService.Application.DTOs;

namespace UserService.Application.Validators;

public class UpdateUserValidator : AbstractValidator<UpdateUserDto>
{
	public UpdateUserValidator()
	{
		RuleFor(x => x.Id)
			.NotEmpty().WithMessage("User ID is required");

		RuleFor(x => x.Email)
			.EmailAddress().WithMessage("A valid email is required")
			.When(x => !string.IsNullOrEmpty(x.Email));

		RuleFor(x => x.FirstName)
			.MaximumLength(50).WithMessage("First name must not exceed 50 characters")
			.When(x => !string.IsNullOrEmpty(x.FirstName));

		RuleFor(x => x.LastName)
			.MaximumLength(50).WithMessage("Last name must not exceed 50 characters")
			.When(x => !string.IsNullOrEmpty(x.LastName));
	}
}