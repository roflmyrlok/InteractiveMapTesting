using FluentValidation;
using LocationService.Application.DTOs;

namespace LocationService.Application.Validators
{
    public class CreateLocationValidator : AbstractValidator<LocationDto>
    {
        public CreateLocationValidator()
        {
            RuleFor(x => x.Latitude)
                .InclusiveBetween(-90, 90).WithMessage("Latitude must be between -90 and 90");

            RuleFor(x => x.Longitude)
                .InclusiveBetween(-180, 180).WithMessage("Longitude must be between -180 and 180");

            RuleFor(x => x.Address)
                .MaximumLength(200).WithMessage("Address must not exceed 200 characters");


            RuleForEach(x => x.Details)
                .SetValidator(new CreateLocationDetailValidator());
        }
    }

    public class CreateLocationDetailValidator : AbstractValidator<LocationDetailDto>
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

}