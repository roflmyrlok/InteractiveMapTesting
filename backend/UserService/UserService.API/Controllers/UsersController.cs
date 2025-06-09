using System;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using UserService.Application.DTOs;
using UserService.Application.Interfaces;
using UserService.Domain.Exceptions;

namespace UserService.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UsersController : ControllerBase
    {
        private readonly IUserService _userService;

        public UsersController(IUserService userService)
        {
            _userService = userService;
        }

        [HttpGet]
        [Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> GetAll()
        {
            var users = await _userService.GetAllUsersAsync();
            return Ok(users);
        }

        [HttpGet("me")]
        [Authorize]
        public async Task<IActionResult> GetCurrentUser()
        {
            var logger = HttpContext.RequestServices.GetRequiredService<ILogger<UsersController>>();
            
            try
            {
                logger.LogInformation("=== GetCurrentUser Called ===");
                logger.LogInformation("IsAuthenticated: {IsAuth}", User.Identity?.IsAuthenticated);
                logger.LogInformation("User.Identity.Name: {Name}", User.Identity?.Name);
                logger.LogInformation("Claims count: {Count}", User.Claims.Count());

                foreach (var claim in User.Claims)
                {
                    logger.LogInformation("Available claim: Type='{Type}', Value='{Value}'", claim.Type, claim.Value);
                }

                string userIdString = null;
                
                var subClaim = User.FindFirst(JwtRegisteredClaimNames.Sub);
                if (subClaim != null && !string.IsNullOrEmpty(subClaim.Value))
                {
                    userIdString = subClaim.Value;
                    logger.LogInformation("Found user ID via Sub claim: {UserId}", userIdString);
                }
                
                if (string.IsNullOrEmpty(userIdString))
                {
                    var nameIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
                    if (nameIdClaim != null && !string.IsNullOrEmpty(nameIdClaim.Value))
                    {
                        userIdString = nameIdClaim.Value;
                        logger.LogInformation("Found user ID via NameIdentifier claim: {UserId}", userIdString);
                    }
                }
                
                if (string.IsNullOrEmpty(userIdString))
                {
                    var rawSubClaim = User.FindFirst("sub");
                    if (rawSubClaim != null && !string.IsNullOrEmpty(rawSubClaim.Value))
                    {
                        userIdString = rawSubClaim.Value;
                        logger.LogInformation("Found user ID via raw 'sub' claim: {UserId}", userIdString);
                    }
                }

                if (string.IsNullOrEmpty(userIdString))
                {
                    logger.LogError("CRITICAL: No user ID found in any claim!");
                    logger.LogError("Available claim types: {ClaimTypes}", 
                        string.Join(", ", User.Claims.Select(c => $"{c.Type}={c.Value}")));
                    return Unauthorized("User ID not found in token");
                }

                if (!Guid.TryParse(userIdString, out var userId))
                {
                    logger.LogError("User ID is not a valid GUID: '{UserIdString}'", userIdString);
                    return Unauthorized("Invalid user token format");
                }

                logger.LogInformation("Successfully parsed user ID: {UserId}", userId);

                logger.LogInformation("Fetching user from database...");
                var user = await _userService.GetUserByIdAsync(userId);
                
                if (user == null)
                {
                    logger.LogWarning("User not found in database: {UserId}", userId);
                    return NotFound("User not found");
                }

                logger.LogInformation("User retrieved successfully: Email={Email}, Username={Username}", 
                    user.Email, user.Username);

                return Ok(user);
            }
            catch (DomainException ex)
            {
                logger.LogWarning("Domain exception in GetCurrentUser: {Message}", ex.Message);
                return NotFound(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Unexpected error in GetCurrentUser");
                return StatusCode(500, new { message = "An error occurred while retrieving user information" });
            }
        }

        [HttpGet("{id}")]
        [Authorize]
        public async Task<IActionResult> GetById(Guid id)
        {
            var user = await _userService.GetUserByIdAsync(id);
            return Ok(user);
        }

        [HttpGet("by-email/{email}")]
        [Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> GetByEmail(string email)
        {
            var user = await _userService.GetUserByEmailAsync(email);
            return Ok(user);
        }

        [HttpGet("by-username/{username}")]
        [Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> GetByUsername(string username)
        {
            var user = await _userService.GetUserByUsernameAsync(username);
            return Ok(user);
        }

        [HttpPost]
        [AllowAnonymous]
        public async Task<IActionResult> Create(CreateUserDto createUserDto)
        {
            var createdUser = await _userService.CreateUserAsync(createUserDto);
            return CreatedAtAction(nameof(GetById), new { id = createdUser.Id }, createdUser);
        }

        [HttpPut]
        [Authorize]
        public async Task<IActionResult> Update(UpdateUserDto updateUserDto)
        {
            var updatedUser = await _userService.UpdateUserAsync(updateUserDto);
            return Ok(updatedUser);
        }

        [HttpPut("change-password")]
        [Authorize]
        public async Task<IActionResult> ChangePassword(ChangePasswordDto changePasswordDto)
        {
            try
            {
                var logger = HttpContext.RequestServices.GetRequiredService<ILogger<UsersController>>();
                
                logger.LogInformation("ChangePassword called. User.Identity.IsAuthenticated: {IsAuth}", 
                    User.Identity?.IsAuthenticated);
                
                logger.LogInformation("Authorization header present: {HasAuth}", 
                    Request.Headers.ContainsKey("Authorization"));

                var userIdClaim = User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
                logger.LogInformation("User ID claim found: {UserIdClaim}", userIdClaim);
                
                if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
                {
                    logger.LogWarning("Invalid user token in ChangePassword");
                    return Unauthorized("Invalid user token");
                }

                logger.LogInformation("Attempting to change password for user: {UserId}", userId);
                var result = await _userService.ChangePasswordAsync(userId, changePasswordDto);
                
                if (result)
                {
                    logger.LogInformation("Password changed successfully for user: {UserId}", userId);
                    return Ok(new { message = "Password changed successfully" });
                }
                
                logger.LogWarning("Failed to change password for user: {UserId}", userId);
                return BadRequest("Failed to change password");
            }
            catch (DomainException ex)
            {
                var logger = HttpContext.RequestServices.GetRequiredService<ILogger<UsersController>>();
                logger.LogWarning("Domain exception in ChangePassword: {Message}", ex.Message);
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                var logger = HttpContext.RequestServices.GetRequiredService<ILogger<UsersController>>();
                logger.LogError(ex, "Unexpected error in ChangePassword");
                return StatusCode(500, new { message = "An error occurred while changing password" });
            }
        }

        [HttpDelete("delete-account")]
        [Authorize]
        public async Task<IActionResult> DeleteAccount([FromBody] DeleteAccountDto deleteAccountDto)
        {
            try
            {
                var userIdClaim = User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
                if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
                {
                    return Unauthorized("Invalid user token");
                }

                await _userService.DeleteUserAccountAsync(userId, deleteAccountDto.CurrentPassword);
                return NoContent();
            }
            catch (DomainException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception)
            {
                return StatusCode(500, new { message = "An error occurred while deleting account" });
            }
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> Delete(Guid id)
        {
            await _userService.DeleteUserAsync(id);
            return NoContent();
        }
    }
}