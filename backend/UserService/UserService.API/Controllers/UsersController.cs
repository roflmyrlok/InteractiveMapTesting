using System;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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
        private readonly ILogger<UsersController> _logger;

        public UsersController(IUserService userService, ILogger<UsersController> logger)
        {
            _userService = userService;
            _logger = logger;
        }

        /// <summary>
        /// Extracts the user ID from JWT claims with fallback mechanisms
        /// </summary>
        private Guid? GetCurrentUserId()
        {
            try
            {
                // Try multiple claim types that might contain the user ID
                var possibleClaims = new[]
                {
                    JwtRegisteredClaimNames.Sub,           // "sub"
                    ClaimTypes.NameIdentifier,             // "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier"
                    "sub",                                 // Direct "sub" claim
                    "user_id",                             // Alternative user ID claim
                    "userId"                               // Another alternative
                };

                foreach (var claimType in possibleClaims)
                {
                    var userIdClaim = User.FindFirst(claimType)?.Value;
                    if (!string.IsNullOrEmpty(userIdClaim))
                    {
                        if (Guid.TryParse(userIdClaim, out var userId))
                        {
                            _logger.LogDebug("Successfully extracted user ID {UserId} from claim type {ClaimType}", userId, claimType);
                            return userId;
                        }
                        else
                        {
                            _logger.LogWarning("Found user ID claim {ClaimType} with value {Value}, but could not parse as GUID", claimType, userIdClaim);
                        }
                    }
                }

                // Debug: Log all available claims
                _logger.LogWarning("Could not find user ID in any expected claim. Available claims:");
                foreach (var claim in User.Claims)
                {
                    _logger.LogWarning("Claim: Type='{Type}', Value='{Value}'", claim.Type, claim.Value);
                }

                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error extracting user ID from claims");
                return null;
            }
        }

        /// <summary>
        /// Validates authentication and extracts user ID, returning appropriate error response if invalid
        /// </summary>
        private IActionResult ValidateAuthenticationAndGetUserId(out Guid userId)
        {
            userId = Guid.Empty;

            if (!User.Identity?.IsAuthenticated == true)
            {
                _logger.LogWarning("User is not authenticated");
                return Unauthorized("Authentication required");
            }

            var extractedUserId = GetCurrentUserId();
            if (!extractedUserId.HasValue)
            {
                _logger.LogWarning("Could not extract valid user ID from authentication token");
                return Unauthorized("Invalid authentication token - user ID not found");
            }

            userId = extractedUserId.Value;
            return null; // No error
        }

        [HttpGet("current")]
        [Authorize]
        public async Task<IActionResult> GetCurrentUser()
        {
            try
            {
                _logger.LogInformation("GetCurrentUser called");

                var authResult = ValidateAuthenticationAndGetUserId(out var userId);
                if (authResult != null) return authResult;

                _logger.LogInformation("Fetching current user information for user: {UserId}", userId);
                
                var user = await _userService.GetUserByIdAsync(userId);
                if (user == null)
                {
                    _logger.LogWarning("User not found for ID: {UserId}", userId);
                    return NotFound(new { message = "User not found" });
                }

                _logger.LogInformation("Successfully retrieved user information for: {Username}", user.Username);
                return Ok(user);
            }
            catch (DomainException ex)
            {
                _logger.LogWarning("Domain exception in GetCurrentUser: {Message}", ex.Message);
                return NotFound(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error in GetCurrentUser");
                return StatusCode(500, new { message = "An error occurred while retrieving user information" });
            }
        }

        [HttpGet("{id}")]
        [Authorize]
        public async Task<IActionResult> GetById(Guid id)
        {
            try
            {
                _logger.LogInformation("GetById called for user ID: {Id}", id);
                
                var authResult = ValidateAuthenticationAndGetUserId(out var currentUserId);
                if (authResult != null) return authResult;

                // Users can only get their own information unless they have admin role
                if (id != currentUserId && !User.IsInRole("Admin") && !User.IsInRole("SuperAdmin"))
                {
                    _logger.LogWarning("User {CurrentUserId} attempted to access user {RequestedUserId} without permission", currentUserId, id);
                    return Forbid("You can only access your own user information");
                }

                var user = await _userService.GetUserByIdAsync(id);
                if (user == null)
                {
                    _logger.LogWarning("User not found for ID: {Id}", id);
                    return NotFound(new { message = "User not found" });
                }

                return Ok(user);
            }
            catch (DomainException ex)
            {
                _logger.LogWarning("Domain exception in GetById: {Message}", ex.Message);
                return NotFound(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error in GetById");
                return StatusCode(500, new { message = "An error occurred while retrieving user information" });
            }
        }

        [HttpGet("by-email/{email}")]
        [Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> GetByEmail(string email)
        {
            try
            {
                _logger.LogInformation("GetByEmail called for email: {Email}", email);
                
                var user = await _userService.GetUserByEmailAsync(email);
                if (user == null)
                {
                    _logger.LogWarning("User not found for email: {Email}", email);
                    return NotFound(new { message = "User not found" });
                }

                return Ok(user);
            }
            catch (DomainException ex)
            {
                _logger.LogWarning("Domain exception in GetByEmail: {Message}", ex.Message);
                return NotFound(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error in GetByEmail");
                return StatusCode(500, new { message = "An error occurred while retrieving user information" });
            }
        }

        [HttpGet("by-username/{username}")]
        [Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> GetByUsername(string username)
        {
            try
            {
                _logger.LogInformation("GetByUsername called for username: {Username}", username);
                
                var user = await _userService.GetUserByUsernameAsync(username);
                if (user == null)
                {
                    _logger.LogWarning("User not found for username: {Username}", username);
                    return NotFound(new { message = "User not found" });
                }

                return Ok(user);
            }
            catch (DomainException ex)
            {
                _logger.LogWarning("Domain exception in GetByUsername: {Message}", ex.Message);
                return NotFound(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error in GetByUsername");
                return StatusCode(500, new { message = "An error occurred while retrieving user information" });
            }
        }

        [HttpPost]
        [AllowAnonymous]
        public async Task<IActionResult> Create(CreateUserDto createUserDto)
        {
            try
            {
                _logger.LogInformation("Create user called for username: {Username}", createUserDto.Username);
                
                var createdUser = await _userService.CreateUserAsync(createUserDto);
                _logger.LogInformation("User created successfully with ID: {UserId}", createdUser.Id);
                
                return CreatedAtAction(nameof(GetById), new { id = createdUser.Id }, createdUser);
            }
            catch (DomainException ex)
            {
                _logger.LogWarning("Domain exception in Create: {Message}", ex.Message);
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error in Create");
                return StatusCode(500, new { message = "An error occurred while creating user" });
            }
        }

        [HttpPut]
        [Authorize]
        public async Task<IActionResult> Update(UpdateUserDto updateUserDto)
        {
            try
            {
                _logger.LogInformation("Update user called");
                
                var authResult = ValidateAuthenticationAndGetUserId(out var userId);
                if (authResult != null) return authResult;

                // Ensure user can only update their own information
                if (updateUserDto.Id != userId && !User.IsInRole("Admin") && !User.IsInRole("SuperAdmin"))
                {
                    _logger.LogWarning("User {CurrentUserId} attempted to update user {RequestedUserId} without permission", userId, updateUserDto.Id);
                    return Forbid("You can only update your own user information");
                }

                _logger.LogInformation("Updating user: {UserId}", updateUserDto.Id);
                var updatedUser = await _userService.UpdateUserAsync(updateUserDto);
                _logger.LogInformation("User updated successfully: {UserId}", updatedUser.Id);
                
                return Ok(updatedUser);
            }
            catch (DomainException ex)
            {
                _logger.LogWarning("Domain exception in Update: {Message}", ex.Message);
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error in Update");
                return StatusCode(500, new { message = "An error occurred while updating user" });
            }
        }

        [HttpPut("change-password")]
        [Authorize]
        public async Task<IActionResult> ChangePassword(ChangePasswordDto changePasswordDto)
        {
            try
            {
                _logger.LogInformation("ChangePassword called");

                var authResult = ValidateAuthenticationAndGetUserId(out var userId);
                if (authResult != null) return authResult;

                _logger.LogInformation("Attempting to change password for user: {UserId}", userId);
                
                var result = await _userService.ChangePasswordAsync(userId, changePasswordDto);
                
                if (result)
                {
                    _logger.LogInformation("Password changed successfully for user: {UserId}", userId);
                    return Ok(new { message = "Password changed successfully" });
                }
                
                _logger.LogWarning("Failed to change password for user: {UserId}", userId);
                return BadRequest(new { message = "Failed to change password" });
            }
            catch (DomainException ex)
            {
                _logger.LogWarning("Domain exception in ChangePassword: {Message}", ex.Message);
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error in ChangePassword");
                return StatusCode(500, new { message = "An error occurred while changing password" });
            }
        }

        [HttpDelete("delete-account")]
        [Authorize]
        public async Task<IActionResult> DeleteAccount([FromBody] DeleteAccountDto deleteAccountDto)
        {
            try
            {
                _logger.LogInformation("DeleteAccount called");

                var authResult = ValidateAuthenticationAndGetUserId(out var userId);
                if (authResult != null) return authResult;

                _logger.LogInformation("Attempting to delete account for user: {UserId}", userId);
                
                await _userService.DeleteUserAccountAsync(userId, deleteAccountDto.CurrentPassword);
                
                _logger.LogInformation("Account deleted successfully for user: {UserId}", userId);
                return NoContent();
            }
            catch (DomainException ex)
            {
                _logger.LogWarning("Domain exception in DeleteAccount: {Message}", ex.Message);
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error in DeleteAccount");
                return StatusCode(500, new { message = "An error occurred while deleting account" });
            }
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> Delete(Guid id)
        {
            try
            {
                _logger.LogInformation("Delete called for user ID: {Id}", id);
                
                var authResult = ValidateAuthenticationAndGetUserId(out var currentUserId);
                if (authResult != null) return authResult;

                // Prevent users from deleting themselves
                if (id == currentUserId)
                {
                    _logger.LogWarning("User {UserId} attempted to delete their own account via admin endpoint", currentUserId);
                    return BadRequest(new { message = "Cannot delete your own account using this endpoint. Use delete-account endpoint instead." });
                }

                _logger.LogInformation("Admin {AdminUserId} deleting user: {UserId}", currentUserId, id);
                await _userService.DeleteUserAsync(id);
                _logger.LogInformation("User {UserId} deleted successfully by admin {AdminUserId}", id, currentUserId);
                
                return NoContent();
            }
            catch (DomainException ex)
            {
                _logger.LogWarning("Domain exception in Delete: {Message}", ex.Message);
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error in Delete");
                return StatusCode(500, new { message = "An error occurred while deleting user" });
            }
        }
    }
}