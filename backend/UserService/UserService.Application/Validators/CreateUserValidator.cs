using FluentValidation;
using UserService.Application.DTOs;

namespace UserService.Application.Validators
{
	public class CreateUserValidator : AbstractValidator<CreateUserDto>
	{
		public CreateUserValidator()
		{
			RuleFor(x => x.Username)
				.NotEmpty().WithMessage("Username is required")
				.MinimumLength(3).WithMessage("Username must be at least 3 characters")
				.MaximumLength(50).WithMessage("Username must not exceed 50 characters");

			RuleFor(x => x.Email)
				.NotEmpty().WithMessage("Email is required")
				.EmailAddress().WithMessage("A valid email is required");

			RuleFor(x => x.Password)
				.NotEmpty().WithMessage("Password is required")
				.MinimumLength(8).WithMessage("Password must be at least 8 characters")
				.Matches("[A-Z]").WithMessage("Password must contain at least one uppercase letter")
				.Matches("[a-z]").WithMessage("Password must contain at least one lowercase letter")
				.Matches("[0-9]").WithMessage("Password must contain at least one number")
				.Matches("[^a-zA-Z0-9]").WithMessage("Password must contain at least one special character");

			RuleFor(x => x.FirstName)
				.MaximumLength(50).WithMessage("First name must not exceed 50 characters");

			RuleFor(x => x.LastName)
				.MaximumLength(50).WithMessage("Last name must not exceed 50 characters");
		}
	}
}