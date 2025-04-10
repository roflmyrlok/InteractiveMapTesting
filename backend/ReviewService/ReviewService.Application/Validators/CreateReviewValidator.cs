using FluentValidation;
using ReviewService.Application.DTOs;

namespace ReviewService.Application.Validators;

public class CreateReviewValidator : AbstractValidator<CreateReviewDto>
{
    public CreateReviewValidator()
    {
        RuleFor(x => x.LocationId)
            .NotEmpty().WithMessage("Location ID is required");

        RuleFor(x => x.Rating)
            .NotEmpty().WithMessage("Rating is required")
            .InclusiveBetween(1, 5).WithMessage("Rating must be between 1 and 5");

        RuleFor(x => x.Content)
            .NotEmpty().WithMessage("Content is required")
            .MaximumLength(1000).WithMessage("Content must not exceed 1000 characters");
    }
}
