using System;
using UserService.Domain.Entities;

namespace UserService.Application.DTOs
{
	public class UserDto
	{
		public Guid Id { get; set; }
		public string Username { get; set; }
		public string Email { get; set; }
		public string FirstName { get; set; }
		public string LastName { get; set; }
		public UserRole Role { get; set; }
		public DateTime CreatedAt { get; set; }
		public DateTime? LastLoginDate { get; set; }
	}
}