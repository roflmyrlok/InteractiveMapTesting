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

		RuleFor(x => x.ImageUrls)
			.Must(urls => urls == null || urls.Count <= 5)
			.WithMessage("Maximum 5 images allowed per review");

		RuleForEach(x => x.ImageUrls)
			.Must(BeValidUrl)
			.WithMessage("Invalid image URL format")
			.When(x => x.ImageUrls != null);
	}

	private bool BeValidUrl(string url)
	{
		return Uri.TryCreate(url, UriKind.Absolute, out var result) && 
		       (result.Scheme == Uri.UriSchemeHttp || result.Scheme == Uri.UriSchemeHttps);
	}
}