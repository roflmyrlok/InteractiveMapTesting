using System;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Configuration;
using UserService.Application.DTOs;

namespace UserService.API.Services
{
	public class JwtAuthenticationService
	{
		private readonly IConfiguration _configuration;

		public JwtAuthenticationService(IConfiguration configuration)
		{
			_configuration = configuration;
		}

		public string GenerateJwtToken(UserDto user)
		{
			var securityKey = new SymmetricSecurityKey(
				Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]));
			var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

			var claims = new[]
			{
				new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
				new Claim(JwtRegisteredClaimNames.Email, user.Email),
				new Claim("username", user.Username),
				new Claim(ClaimTypes.Role, user.Role.ToString()),
				new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
			};

			var token = new JwtSecurityToken(
				issuer: _configuration["Jwt:Issuer"],
				audience: _configuration["Jwt:Audience"],
				claims: claims,
				expires: DateTime.Now.AddHours(1),
				signingCredentials: credentials);

			return new JwtSecurityTokenHandler().WriteToken(token);
		}
	}
}