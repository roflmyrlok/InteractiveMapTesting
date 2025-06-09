using FluentValidation;
using UserService.Application.DTOs;

namespace UserService.Application.Validators;

public class ChangePasswordValidator : AbstractValidator<ChangePasswordDto>
{
	public ChangePasswordValidator()
	{
		RuleFor(x => x.CurrentPassword)
			.NotEmpty().WithMessage("Current password is required");

		RuleFor(x => x.NewPassword)
			.NotEmpty().WithMessage("New password is required")
			.MinimumLength(8).WithMessage("Password must be at least 8 characters")
			.Matches("[A-Z]").WithMessage("Password must contain at least one uppercase letter")
			.Matches("[a-z]").WithMessage("Password must contain at least one lowercase letter")
			.Matches("[0-9]").WithMessage("Password must contain at least one number")
			.Matches("[^a-zA-Z0-9]").WithMessage("Password must contain at least one special character");

		RuleFor(x => x.ConfirmNewPassword)
			.NotEmpty().WithMessage("Password confirmation is required")
			.Equal(x => x.NewPassword).WithMessage("Passwords do not match");
	}
}