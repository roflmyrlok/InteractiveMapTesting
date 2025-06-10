using System;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
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
        /// Extracts user ID from JWT claims with comprehensive fallback mechanisms
        /// </summary>
        private Guid GetCurrentUserIdFromClaims()
        {
            try
            {
                _logger.LogInformation("=== Starting User ID Extraction ===");
                _logger.LogInformation("IsAuthenticated: {IsAuth}", User.Identity?.IsAuthenticated);
                _logger.LogInformation("Identity Name: {Name}", User.Identity?.Name);
                _logger.LogInformation("Total Claims: {Count}", User.Claims.Count());

                // Log ALL claims for debugging
                foreach (var claim in User.Claims)
                {
                    _logger.LogInformation("Claim: Type='{Type}' | Value='{Value}'", claim.Type, claim.Value);
                }

                // Try multiple claim types in order of preference
                var claimTypes = new[]
                {
                    JwtRegisteredClaimNames.Sub,                    // "sub"
                    ClaimTypes.NameIdentifier,                      // "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier"  
                    "sub",                                          // Direct "sub" string
                    "user_id",                                      // Alternative
                    "userId",                                       // CamelCase
                    "userid",                                       // Lowercase
                    JwtRegisteredClaimNames.NameId,                 // "nameid"
                    "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier"  // Full URL
                };

                string userIdValue = null;
                string foundClaimType = null;

                // Try each claim type
                foreach (var claimType in claimTypes)
                {
                    _logger.LogDebug("Trying claim type: '{ClaimType}'", claimType);
                    var claim = User.FindFirst(claimType);
                    
                    if (claim != null)
                    {
                        _logger.LogInformation("Found claim '{ClaimType}' with value '{Value}'", claimType, claim.Value);
                        if (!string.IsNullOrWhiteSpace(claim.Value))
                        {
                            userIdValue = claim.Value;
                            foundClaimType = claimType;
                            break;
                        }
                    }
                    else
                    {
                        _logger.LogDebug("Claim type '{ClaimType}' not found", claimType);
                    }
                }

                // Fallback: Search for any claim containing user identifier keywords
                if (string.IsNullOrWhiteSpace(userIdValue))
                {
                    _logger.LogWarning("Standard claims not found, trying fallback search...");
                    
                    var fallbackClaim = User.Claims.FirstOrDefault(c =>
                        c.Type.Contains("nameidentifier", StringComparison.OrdinalIgnoreCase) ||
                        c.Type.Contains("userid", StringComparison.OrdinalIgnoreCase) ||
                        c.Type.Contains("sub", StringComparison.OrdinalIgnoreCase) ||
                        c.Type.EndsWith("sub", StringComparison.OrdinalIgnoreCase));

                    if (fallbackClaim != null && !string.IsNullOrWhiteSpace(fallbackClaim.Value))
                    {
                        userIdValue = fallbackClaim.Value;
                        foundClaimType = fallbackClaim.Type;
                        _logger.LogInformation("Found user ID via fallback: '{ClaimType}' = '{Value}'", foundClaimType, userIdValue);
                    }
                }

                // Final check
                if (string.IsNullOrWhiteSpace(userIdValue))
                {
                    var allClaims = string.Join(" | ", User.Claims.Select(c => $"{c.Type}={c.Value}"));
                    _logger.LogError("CRITICAL: No user ID found in any claim! All claims: {AllClaims}", allClaims);
                    throw new UnauthorizedAccessException("User ID not found in authentication token");
                }

                // Parse as GUID
                if (!Guid.TryParse(userIdValue, out var userId))
                {
                    _logger.LogError("User ID '{UserIdValue}' from claim '{ClaimType}' is not a valid GUID", userIdValue, foundClaimType);
                    throw new UnauthorizedAccessException($"Invalid user ID format: {userIdValue}");
                }

                _logger.LogInformation("Successfully extracted user ID: {UserId} from claim: {ClaimType}", userId, foundClaimType);
                return userId;
            }
            catch (Exception ex) when (!(ex is UnauthorizedAccessException))
            {
                _logger.LogError(ex, "Unexpected error extracting user ID from claims");
                throw new UnauthorizedAccessException("Failed to extract user ID from authentication token", ex);
            }
        }

        [HttpGet]
        [Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> GetAll()
        {
            try
            {
                _logger.LogInformation("GetAll users called");
                var users = await _userService.GetAllUsersAsync();
                return Ok(users);
            }
            catch (DomainException ex)
            {
                _logger.LogWarning("Domain exception in GetAll: {Message}", ex.Message);
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error in GetAll");
                return StatusCode(500, new { message = "An error occurred while retrieving users" });
            }
        }

        // FIX: Added both routes for current user
        [HttpGet("current")]
        [HttpGet("me")]  // iOS app calls this route
        [Authorize]
        public async Task<IActionResult> GetCurrentUser()
        {
            try
            {
                _logger.LogInformation("GetCurrentUser called via route: {Path}", Request.Path);

                var userId = GetCurrentUserIdFromClaims();
                _logger.LogInformation("Fetching user information for ID: {UserId}", userId);
                
                var user = await _userService.GetUserByIdAsync(userId);
                if (user == null)
                {
                    _logger.LogWarning("User not found for ID: {UserId}", userId);
                    return NotFound(new { message = "User not found" });
                }

                _logger.LogInformation("Successfully retrieved user: {Username} ({Email})", user.Username, user.Email);
                return Ok(user);
            }
            catch (UnauthorizedAccessException ex)
            {
                _logger.LogWarning("Authentication error in GetCurrentUser: {Message}", ex.Message);
                return Unauthorized(new { message = ex.Message });
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
                
                var currentUserId = GetCurrentUserIdFromClaims();

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
            catch (UnauthorizedAccessException ex)
            {
                _logger.LogWarning("Authentication error in GetById: {Message}", ex.Message);
                return Unauthorized(new { message = ex.Message });
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
                
                var currentUserId = GetCurrentUserIdFromClaims();

                // Ensure user can only update their own information
                if (updateUserDto.Id != currentUserId && !User.IsInRole("Admin") && !User.IsInRole("SuperAdmin"))
                {
                    _logger.LogWarning("User {CurrentUserId} attempted to update user {RequestedUserId} without permission", currentUserId, updateUserDto.Id);
                    return Forbid("You can only update your own user information");
                }

                _logger.LogInformation("Updating user: {UserId}", updateUserDto.Id);
                var updatedUser = await _userService.UpdateUserAsync(updateUserDto);
                _logger.LogInformation("User updated successfully: {UserId}", updatedUser.Id);
                
                return Ok(updatedUser);
            }
            catch (UnauthorizedAccessException ex)
            {
                _logger.LogWarning("Authentication error in Update: {Message}", ex.Message);
                return Unauthorized(new { message = ex.Message });
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

        // FIX: Support both PUT and POST for iOS compatibility
        [HttpPut("change-password")]
        [HttpPost("change-password")]
        [Authorize]
        public async Task<IActionResult> ChangePassword(ChangePasswordDto changePasswordDto)
        {
            try
            {
                _logger.LogInformation("ChangePassword called via {Method} method", Request.Method);

                var userId = GetCurrentUserIdFromClaims();
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
            catch (UnauthorizedAccessException ex)
            {
                _logger.LogWarning("Authentication error in ChangePassword: {Message}", ex.Message);
                return Unauthorized(new { message = ex.Message });
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

        // FIX: Support both DELETE and POST for iOS compatibility
        [HttpDelete("delete-account")]
        [HttpPost("delete-account")]
        [Authorize]
        public async Task<IActionResult> DeleteAccount([FromBody] DeleteAccountDto deleteAccountDto)
        {
            try
            {
                _logger.LogInformation("DeleteAccount called via {Method} method", Request.Method);

                var userId = GetCurrentUserIdFromClaims();
                _logger.LogInformation("Attempting to delete account for user: {UserId}", userId);
                
                await _userService.DeleteUserAccountAsync(userId, deleteAccountDto.CurrentPassword);
                
                _logger.LogInformation("Account deleted successfully for user: {UserId}", userId);
                return NoContent();
            }
            catch (UnauthorizedAccessException ex)
            {
                _logger.LogWarning("Authentication error in DeleteAccount: {Message}", ex.Message);
                return Unauthorized(new { message = ex.Message });
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
                
                var currentUserId = GetCurrentUserIdFromClaims();

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
            catch (UnauthorizedAccessException ex)
            {
                _logger.LogWarning("Authentication error in Delete: {Message}", ex.Message);
                return Unauthorized(new { message = ex.Message });
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