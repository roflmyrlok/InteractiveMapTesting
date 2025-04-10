using FluentValidation;
using LocationService.Application.DTOs;

namespace LocationService.Application.Validators
{
    public class CreateLocationValidator : AbstractValidator<CreateLocationDto>
    {
        public CreateLocationValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Name is required")
                .MaximumLength(100).WithMessage("Name must not exceed 100 characters");

            RuleFor(x => x.Latitude)
                .InclusiveBetween(-90, 90).WithMessage("Latitude must be between -90 and 90");

            RuleFor(x => x.Longitude)
                .InclusiveBetween(-180, 180).WithMessage("Longitude must be between -180 and 180");

            RuleFor(x => x.Address)
                .MaximumLength(200).WithMessage("Address must not exceed 200 characters");

            RuleFor(x => x.City)
                .MaximumLength(100).WithMessage("City must not exceed 100 characters");

            RuleFor(x => x.State)
                .MaximumLength(100).WithMessage("State must not exceed 100 characters");

            RuleFor(x => x.Country)
                .MaximumLength(100).WithMessage("Country must not exceed 100 characters");

            RuleFor(x => x.PostalCode)
                .MaximumLength(20).WithMessage("Postal code must not exceed 20 characters");

            RuleForEach(x => x.Details)
                .SetValidator(new CreateLocationDetailValidator());
        }
    }

    public class CreateLocationDetailValidator : AbstractValidator<CreateLocationDetailDto>
    {
        public CreateLocationDetailValidator()
        {
            RuleFor(x => x.PropertyName)
                .NotEmpty().WithMessage("Detail key is required")
                .MaximumLength(50).WithMessage("Detail key must not exceed 50 characters");

            RuleFor(x => x.PropertyValue)
                .NotEmpty().WithMessage("Detail value is required")
                .MaximumLength(500).WithMessage("Detail value must not exceed 500 characters");
        }
    }

    public class UpdateLocationValidator : AbstractValidator<UpdateLocationDto>
    {
        public UpdateLocationValidator()
        {
            RuleFor(x => x.Id)
                .NotEmpty().WithMessage("Location ID is required");

            RuleFor(x => x.Name)
                .MaximumLength(100).WithMessage("Name must not exceed 100 characters")
                .When(x => !string.IsNullOrEmpty(x.Name));

            RuleFor(x => x.Latitude)
                .InclusiveBetween(-90, 90).WithMessage("Latitude must be between -90 and 90")
                .When(x => x.Latitude.HasValue);

            RuleFor(x => x.Longitude)
                .InclusiveBetween(-180, 180).WithMessage("Longitude must be between -180 and 180")
                .When(x => x.Longitude.HasValue);

            RuleFor(x => x.Address)
                .MaximumLength(200).WithMessage("Address must not exceed 200 characters")
                .When(x => !string.IsNullOrEmpty(x.Address));

            RuleFor(x => x.City)
                .MaximumLength(100).WithMessage("City must not exceed 100 characters")
                .When(x => !string.IsNullOrEmpty(x.City));

            RuleFor(x => x.State)
                .MaximumLength(100).WithMessage("State must not exceed 100 characters")
                .When(x => !string.IsNullOrEmpty(x.State));

            RuleFor(x => x.Country)
                .MaximumLength(100).WithMessage("Country must not exceed 100 characters")
                .When(x => !string.IsNullOrEmpty(x.Country));

            RuleFor(x => x.PostalCode)
                .MaximumLength(20).WithMessage("Postal code must not exceed 20 characters")
                .When(x => !string.IsNullOrEmpty(x.PostalCode));
        }
    }
}