using AutoMapper;
using LocationService.Application.DTOs;
using LocationService.Domain.Entities;

namespace LocationService.Application.Mapping
{
	public class MappingProfile : Profile
	{
		public MappingProfile()
		{
			// Location Mappings
			CreateMap<Location, LocationDto>()
				.ForMember(dest => dest.Details, 
					opt => opt.MapFrom(src => src.Details));

			CreateMap<CreateLocationDto, Location>()
				.ForMember(dest => dest.Id, opt => opt.Ignore())
				.ForMember(dest => dest.CreatedAt, opt => opt.Ignore())
				.ForMember(dest => dest.UpdatedAt, opt => opt.Ignore())
				.ForMember(dest => dest.Details, opt => opt.MapFrom(src => 
					src.Details.Select(d => new LocationDetail 
					{ 
						Id = Guid.NewGuid(), 
						PropertyName = d.PropertyName, 
						PropertyValue = d.PropertyValue 
					})));

			CreateMap<UpdateLocationDto, Location>()
				.ForAllMembers(opts => opts.Condition((src, dest, srcMember) => srcMember != null));

			// Location Detail Mappings
			CreateMap<LocationDetail, LocationDetailDto>()
				.ForMember(dest => dest.PropertyName, opt => opt.MapFrom(src => src.PropertyName))
				.ForMember(dest => dest.PropertyValue, opt => opt.MapFrom(src => src.PropertyValue));

			CreateMap<CreateLocationDetailDto, LocationDetail>()
				.ForMember(dest => dest.Id, opt => opt.Ignore())
				.ForMember(dest => dest.LocationId, opt => opt.Ignore())
				.ForMember(dest => dest.Location, opt => opt.Ignore())
				.ForMember(dest => dest.PropertyName, opt => opt.MapFrom(src => src.PropertyName))
				.ForMember(dest => dest.PropertyValue, opt => opt.MapFrom(src => src.PropertyValue));
		}
	}
}