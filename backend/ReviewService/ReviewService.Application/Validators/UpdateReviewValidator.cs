using FluentValidation;
using ReviewService.Application.DTOs;

namespace ReviewService.Application.Validators;

public class UpdateReviewValidator : AbstractValidator<UpdateReviewDto>
{
    public UpdateReviewValidator()
    {
        RuleFor(x => x.Id)
            .NotEmpty().WithMessage("Review ID is required");

        RuleFor(x => x.Rating)
            .NotEmpty().WithMessage("Rating is required")
            .InclusiveBetween(1, 5).WithMessage("Rating must be between 1 and 5");

        RuleFor(x => x.Content)
            .NotEmpty().WithMessage("Content is required")
            .MaximumLength(1000).WithMessage("Content must not exceed 1000 characters");
    }
}
