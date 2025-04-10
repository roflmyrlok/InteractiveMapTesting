using AutoMapper;
using UserService.Application.DTOs;
using UserService.Domain.Entities;

namespace UserService.Application.Mapping
{
	public class MappingProfile : Profile
	{
		public MappingProfile()
		{
			CreateMap<User, UserDto>();
			CreateMap<CreateUserDto, User>();
			CreateMap<UpdateUserDto, User>()
				.ForAllMembers(opts => opts.Condition((src, dest, srcMember) => srcMember != null));
		}
	}
}