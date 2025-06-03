using AutoMapper;
using ReviewService.Application.DTOs;
using ReviewService.Domain.Entities;

namespace ReviewService.Application.Mapping;

public class MappingProfile : Profile
{
	public MappingProfile()
	{
		CreateMap<Review, ReviewDto>();
		CreateMap<CreateReviewDto, Review>()
			.ForMember(dest => dest.ImageUrls, opt => opt.MapFrom(src => src.ImageUrls ?? new List<string>()));
		CreateMap<UpdateReviewDto, Review>()
			.ForAllMembers(opts => opts.Condition((src, dest, srcMember) => srcMember != null));
	}
}