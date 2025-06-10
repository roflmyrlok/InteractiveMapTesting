using System;

namespace UserService.Domain.Entities;

public class User
{
	public Guid Id { get; set; }
	public DateTime CreatedAt { get; set; }
	public DateTime? UpdatedAt { get; set; }
	public string Username { get; set; }
	public string Email { get; set; }
	public string PasswordHash { get; set; }
	public string FirstName { get; set; }
	public string LastName { get; set; }
	public DateTime? LastLoginDate { get; set; }
}