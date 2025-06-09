using System;
using System.Collections.Generic;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using UserService.Application.DTOs;
using UserService.Application.Interfaces;

namespace UserService.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IUserService _userService;
        private readonly IConfiguration _configuration;

        public AuthController(IUserService userService, IConfiguration configuration)
        {
            _userService = userService;
            _configuration = configuration;
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequestDto loginRequest)
        {
            try
            {
                var logger = HttpContext.RequestServices.GetRequiredService<ILogger<AuthController>>();
                logger.LogInformation("Login attempt for username: {Username}", loginRequest.Username);

                var isValid = await _userService.ValidateUserCredentialsAsync(
                    loginRequest.Username, loginRequest.Password);

                if (!isValid)
                {
                    logger.LogWarning("Invalid credentials for username: {Username}", loginRequest.Username);
                    return Unauthorized("Invalid username or password");
                }

                var user = await _userService.GetUserByUsernameAsync(loginRequest.Username);
                
                if (user == null)
                {
                    logger.LogError("User not found after successful credential validation: {Username}", loginRequest.Username);
                    return Unauthorized("User not found");
                }

                logger.LogInformation("User found: ID={UserId}, Email={Email}", user.Id, user.Email);
                
                var token = GenerateJwtToken(user);
                logger.LogInformation("JWT token generated successfully for user: {UserId}", user.Id);

                return Ok(new { token });
            }
            catch (Exception ex)
            {
                var logger = HttpContext.RequestServices.GetRequiredService<ILogger<AuthController>>();
                logger.LogError(ex, "Error during login for username: {Username}", loginRequest.Username);
                return StatusCode(500, "An error occurred during login");
            }
        }

        private string GenerateJwtToken(UserDto user)
        {
            var logger = HttpContext.RequestServices.GetRequiredService<ILogger<AuthController>>();
            
            if (user == null)
            {
                logger.LogError("Cannot generate token: user is null");
                throw new ArgumentNullException(nameof(user));
            }

            if (user.Id == Guid.Empty)
            {
                logger.LogError("Cannot generate token: user ID is empty");
                throw new ArgumentException("User ID cannot be empty", nameof(user));
            }

            var securityKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var userIdString = user.Id.ToString();
            
            logger.LogInformation("Generating JWT token for User ID: '{UserId}', Email: '{Email}'", 
                userIdString, user.Email);

            var claims = new List<Claim>
            {
                new Claim(JwtRegisteredClaimNames.Sub, userIdString),
                new Claim(JwtRegisteredClaimNames.Email, user.Email ?? ""),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                new Claim("username", user.Username ?? ""),
                new Claim(ClaimTypes.NameIdentifier, userIdString),
            };

            try
            {
                var roleValue = "";
                
                var roleProperty = user.GetType().GetProperty("Role");
                if (roleProperty != null)
                {
                    var roleObj = roleProperty.GetValue(user);
                    if (roleObj != null)
                    {
                        roleValue = roleObj.ToString();
                    }
                }
                
                if (!string.IsNullOrEmpty(roleValue))
                {
                    claims.Add(new Claim(ClaimTypes.Role, roleValue));
                    logger.LogInformation("Added role claim: {Role}", roleValue);
                }
                else
                {
                    logger.LogInformation("No role found for user, using default 'User' role");
                    claims.Add(new Claim(ClaimTypes.Role, "User"));
                }
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Could not add role claim, continuing without it");
                claims.Add(new Claim(ClaimTypes.Role, "User"));
            }

            logger.LogInformation("Adding {ClaimCount} claims to JWT token:", claims.Count);
            foreach (var claim in claims)
            {
                logger.LogDebug("Claim: {Type} = '{Value}'", claim.Type, claim.Value);
            }

            // FIX: Use UTC time consistently
            var token = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"],
                audience: _configuration["Jwt:Audience"],
                claims: claims,
                expires: DateTime.UtcNow.AddHours(1), // Consistent UTC time
                signingCredentials: credentials);

            var tokenString = new JwtSecurityTokenHandler().WriteToken(token);
            
            try
            {
                var handler = new JwtSecurityTokenHandler();
                var decodedToken = handler.ReadJwtToken(tokenString);
                var subClaim = decodedToken.Claims.FirstOrDefault(c => c.Type == JwtRegisteredClaimNames.Sub);
                
                logger.LogInformation("Token verification - Sub claim: '{SubClaim}'", subClaim?.Value);
                logger.LogInformation("Token expires at: {ExpiryTime} UTC", token.ValidTo);
                
                if (string.IsNullOrEmpty(subClaim?.Value))
                {
                    logger.LogError("CRITICAL: Generated token has empty sub claim!");
                }
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Error verifying generated token");
            }

            return tokenString;
        }
    }

    public class LoginRequestDto
    {
        public string Username { get; set; }
        public string Password { get; set; }
    }
}