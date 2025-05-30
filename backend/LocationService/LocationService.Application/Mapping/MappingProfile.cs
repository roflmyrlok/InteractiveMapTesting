using AutoMapper;
using LocationService.Application.Commands;
using LocationService.Application.DTOs;
using LocationService.Domain.Entities;

namespace LocationService.Application.Mapping
{
	public class MappingProfile : Profile
	{
		public MappingProfile()
		{
			CreateMap<Location, LocationDto>()
				.ForMember(dest => dest.Details, opt => opt.MapFrom(src => src.Details));
            
			CreateMap<LocationDetail, LocationDetailDto>();
		}
	}
}