using System;
using UserService.Domain.Entities;

namespace UserService.Application.DTOs
{
	public class UpdateUserDto
	{
		public Guid Id { get; set; }
		public string FirstName { get; set; }
		public string LastName { get; set; }
		public string Email { get; set; }
		public UserRole? Role { get; set; }
	}
}