using System;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace UserService.API.Controllers
{
    /// <summary>
    /// Base controller that provides common authentication and authorization functionality
    /// All controllers requiring authentication should inherit from this class
    /// </summary>
    [Authorize]
    [ApiController]
    public abstract class BaseAuthenticatedController : ControllerBase
    {
        protected readonly ILogger _logger;

        protected BaseAuthenticatedController(ILogger logger)
        {
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        /// <summary>
        /// Extracts user ID from JWT claims with comprehensive fallback mechanisms
        /// </summary>
        /// <returns>User ID as Guid</returns>
        /// <exception cref="UnauthorizedAccessException">Thrown when user ID cannot be extracted from claims</exception>
        protected Guid GetCurrentUserId()
        {
            try
            {
                _logger.LogDebug("=== Starting User ID Extraction ===");
                _logger.LogDebug("IsAuthenticated: {IsAuth}", User.Identity?.IsAuthenticated);
                _logger.LogDebug("Identity Name: {Name}", User.Identity?.Name);
                _logger.LogDebug("Total Claims: {Count}", User.Claims.Count());

                // Log all claims for debugging in development
                if (IsDebugEnvironment())
                {
                    foreach (var claim in User.Claims)
                    {
                        _logger.LogDebug("Claim: Type='{Type}' | Value='{Value}'", claim.Type, claim.Value);
                    }
                }

                // Try multiple claim types in order of preference
                var claimTypes = new[]
                {
                    JwtRegisteredClaimNames.Sub,                    // "sub" - Standard JWT subject claim
                    ClaimTypes.NameIdentifier,                      // Microsoft identity claim
                    "sub",                                          // Direct "sub" string
                    "user_id",                                      // Alternative user ID claim
                    "userId",                                       // CamelCase variant
                    "userid",                                       // Lowercase variant
                    JwtRegisteredClaimNames.NameId,                 // JWT name ID claim
                    "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier"  // Full Microsoft claim URL
                };

                string userIdValue = null;
                string foundClaimType = null;

                // Try each claim type
                foreach (var claimType in claimTypes)
                {
                    var claim = User.FindFirst(claimType);
                    if (claim != null && !string.IsNullOrWhiteSpace(claim.Value))
                    {
                        userIdValue = claim.Value;
                        foundClaimType = claimType;
                        _logger.LogDebug("Found user ID '{UserId}' in claim type '{ClaimType}'", userIdValue, claimType);
                        break;
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
                        c.Type.EndsWith("sub", StringComparison.OrdinalIgnoreCase) ||
                        c.Type.EndsWith("/nameidentifier", StringComparison.OrdinalIgnoreCase));

                    if (fallbackClaim != null && !string.IsNullOrWhiteSpace(fallbackClaim.Value))
                    {
                        userIdValue = fallbackClaim.Value;
                        foundClaimType = fallbackClaim.Type;
                        _logger.LogInformation("Found user ID via fallback: '{ClaimType}' = '{Value}'", foundClaimType, userIdValue);
                    }
                }

                // Final validation
                if (string.IsNullOrWhiteSpace(userIdValue))
                {
                    LogAllClaimsForDebugging();
                    _logger.LogError("CRITICAL: No user ID found in any claim!");
                    throw new UnauthorizedAccessException("User ID not found in authentication token");
                }

                // Parse as GUID
                if (!Guid.TryParse(userIdValue, out var userId))
                {
                    _logger.LogError("User ID '{UserIdValue}' from claim '{ClaimType}' is not a valid GUID", userIdValue, foundClaimType);
                    throw new UnauthorizedAccessException($"Invalid user ID format: {userIdValue}");
                }

                _logger.LogDebug("Successfully extracted user ID: {UserId} from claim: {ClaimType}", userId, foundClaimType);
                return userId;
            }
            catch (UnauthorizedAccessException)
            {
                // Re-throw authorization exceptions as-is
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error extracting user ID from claims");
                throw new UnauthorizedAccessException("Failed to extract user ID from authentication token", ex);
            }
        }

        /// <summary>
        /// Gets the current authenticated user's role from JWT claims
        /// </summary>
        /// <returns>User role as string, defaults to "Regular" if not found</returns>
        protected string GetCurrentUserRole()
        {
            try
            {
                // Try multiple role claim types
                var possibleRoleClaimTypes = new[]
                {
                    ClaimTypes.Role,                       // Standard .NET role claim
                    "role",                                // Simple role claim
                    "roles",                               // Plural variant
                    JwtRegisteredClaimNames.Typ,           // Sometimes used for role
                    "user_role"                            // Alternative role claim
                };

                foreach (var claimType in possibleRoleClaimTypes)
                {
                    var roleClaim = User.FindFirst(claimType);
                    if (roleClaim != null && !string.IsNullOrWhiteSpace(roleClaim.Value))
                    {
                        _logger.LogDebug("Found user role '{Role}' from claim type '{ClaimType}'", roleClaim.Value, claimType);
                        return roleClaim.Value;
                    }
                }

                // Last resort: search for any claim that might contain a role
                var potentialRoleClaim = User.Claims.FirstOrDefault(c =>
                    c.Type.Contains("role", StringComparison.OrdinalIgnoreCase));

                if (potentialRoleClaim != null && !string.IsNullOrWhiteSpace(potentialRoleClaim.Value))
                {
                    _logger.LogDebug("Found user role '{Role}' from potential role claim '{ClaimType}'", potentialRoleClaim.Value, potentialRoleClaim.Type);
                    return potentialRoleClaim.Value;
                }

                _logger.LogDebug("No role found in JWT claims, using default 'Regular'");
                return "Regular";
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error extracting user role from JWT claims, using default 'Regular'");
                return "Regular";
            }
        }

        /// <summary>
        /// Gets the current authenticated user's username from JWT claims
        /// </summary>
        /// <returns>Username as string, or null if not found</returns>
        protected string GetCurrentUsername()
        {
            try
            {
                // Try multiple username claim types
                var possibleUsernameClaimTypes = new[]
                {
                    "username",                            // Custom username claim
                    ClaimTypes.Name,                       // Standard name claim
                    JwtRegisteredClaimNames.UniqueName,    // JWT unique name
                    "user_name",                           // Alternative username claim
                    ClaimTypes.GivenName,                  // Given name fallback
                    "preferred_username"                   // OIDC preferred username
                };

                foreach (var claimType in possibleUsernameClaimTypes)
                {
                    var usernameClaim = User.FindFirst(claimType);
                    if (usernameClaim != null && !string.IsNullOrWhiteSpace(usernameClaim.Value))
                    {
                        _logger.LogDebug("Found username '{Username}' from claim type '{ClaimType}'", usernameClaim.Value, claimType);
                        return usernameClaim.Value;
                    }
                }

                _logger.LogDebug("No username found in JWT claims");
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error extracting username from JWT claims");
                return null;
            }
        }

        /// <summary>
        /// Gets the current authenticated user's email from JWT claims
        /// </summary>
        /// <returns>Email as string, or null if not found</returns>
        protected string GetCurrentUserEmail()
        {
            try
            {
                // Try multiple email claim types
                var possibleEmailClaimTypes = new[]
                {
                    JwtRegisteredClaimNames.Email,         // Standard JWT email claim
                    ClaimTypes.Email,                      // .NET email claim
                    "email",                               // Simple email claim
                    "user_email",                          // Alternative email claim
                    ClaimTypes.Upn                         // User Principal Name
                };

                foreach (var claimType in possibleEmailClaimTypes)
                {
                    var emailClaim = User.FindFirst(claimType);
                    if (emailClaim != null && !string.IsNullOrWhiteSpace(emailClaim.Value))
                    {
                        _logger.LogDebug("Found email '{Email}' from claim type '{ClaimType}'", emailClaim.Value, claimType);
                        return emailClaim.Value;
                    }
                }

                _logger.LogDebug("No email found in JWT claims");
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error extracting email from JWT claims");
                return null;
            }
        }

        /// <summary>
        /// Validates authentication and extracts user ID, returning appropriate error response if invalid
        /// </summary>
        /// <param name="userId">Output parameter for the extracted user ID</param>
        /// <returns>IActionResult with error response if validation fails, null if successful</returns>
        protected IActionResult ValidateAuthenticationAndGetUserId(out Guid userId)
        {
            userId = Guid.Empty;

            try
            {
                if (User?.Identity?.IsAuthenticated != true)
                {
                    _logger.LogWarning("User is not authenticated for request to {RequestPath}", Request.Path);
                    return Unauthorized(new { message = "Authentication required" });
                }

                userId = GetCurrentUserId();
                return null; // Success - no error response needed
            }
            catch (UnauthorizedAccessException ex)
            {
                _logger.LogWarning("Authentication validation failed: {Message}", ex.Message);
                return Unauthorized(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error during authentication validation");
                return StatusCode(500, new { message = "An error occurred during authentication validation" });
            }
        }

        /// <summary>
        /// Checks if the current user is in the specified role
        /// </summary>
        /// <param name="role">Role to check</param>
        /// <returns>True if user is in the role, false otherwise</returns>
        protected bool IsInRole(string role)
        {
            return User.IsInRole(role);
        }

        /// <summary>
        /// Checks if the current user is an admin (Admin or SuperAdmin role)
        /// </summary>
        /// <returns>True if user is admin, false otherwise</returns>
        protected bool IsAdmin()
        {
            return User.IsInRole("Admin") || User.IsInRole("SuperAdmin");
        }

        /// <summary>
        /// Checks if the current user is a super admin
        /// </summary>
        /// <returns>True if user is super admin, false otherwise</returns>
        protected bool IsSuperAdmin()
        {
            return User.IsInRole("SuperAdmin");
        }

        /// <summary>
        /// Checks if the current user can access the specified user's data
        /// Users can access their own data, admins can access any user's data
        /// </summary>
        /// <param name="targetUserId">The user ID being accessed</param>
        /// <returns>True if access is allowed, false otherwise</returns>
        protected bool CanAccessUserData(Guid targetUserId)
        {
            try
            {
                var currentUserId = GetCurrentUserId();
                return currentUserId == targetUserId || IsAdmin();
            }
            catch (UnauthorizedAccessException)
            {
                return false;
            }
        }

        /// <summary>
        /// Validates that the current user can access the specified user's data
        /// </summary>
        /// <param name="targetUserId">The user ID being accessed</param>
        /// <returns>IActionResult with error response if access denied, null if allowed</returns>
        protected IActionResult ValidateUserDataAccess(Guid targetUserId)
        {
            try
            {
                if (!CanAccessUserData(targetUserId))
                {
                    var currentUserId = GetCurrentUserId();
                    _logger.LogWarning("User {CurrentUserId} attempted to access data for user {TargetUserId} without permission", 
                        currentUserId, targetUserId);
                    return Forbid("You can only access your own data unless you are an administrator");
                }

                return null; // Access allowed
            }
            catch (UnauthorizedAccessException ex)
            {
                _logger.LogWarning("Authentication error during access validation: {Message}", ex.Message);
                return Unauthorized(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Creates a standardized error response
        /// </summary>
        /// <param name="message">Error message</param>
        /// <param name="statusCode">HTTP status code</param>
        /// <returns>IActionResult with error response</returns>
        protected IActionResult CreateErrorResponse(string message, int statusCode = 400)
        {
            return StatusCode(statusCode, new { message });
        }

        /// <summary>
        /// Creates a standardized success response with data
        /// </summary>
        /// <param name="data">Response data</param>
        /// <param name="message">Optional success message</param>
        /// <returns>IActionResult with success response</returns>
        protected IActionResult CreateSuccessResponse(object data, string message = null)
        {
            if (string.IsNullOrEmpty(message))
            {
                return Ok(data);
            }

            return Ok(new { message, data });
        }

        /// <summary>
        /// Handles domain exceptions consistently across controllers
        /// </summary>
        /// <param name="ex">Domain exception</param>
        /// <param name="operation">Name of the operation that failed</param>
        /// <returns>IActionResult with appropriate error response</returns>
        protected IActionResult HandleDomainException(Exception ex, string operation)
        {
            _logger.LogWarning("Domain exception in {Operation}: {Message}", operation, ex.Message);
            return BadRequest(new { message = ex.Message });
        }

        /// <summary>
        /// Handles unexpected exceptions consistently across controllers
        /// </summary>
        /// <param name="ex">Exception that occurred</param>
        /// <param name="operation">Name of the operation that failed</param>
        /// <returns>IActionResult with internal server error response</returns>
        protected IActionResult HandleUnexpectedException(Exception ex, string operation)
        {
            _logger.LogError(ex, "Unexpected error in {Operation}", operation);
            return StatusCode(500, new { message = $"An error occurred while {operation.ToLower()}" });
        }

        /// <summary>
        /// Logs all available claims for debugging purposes
        /// </summary>
        protected void LogAllClaimsForDebugging()
        {
            if (User?.Claims == null)
            {
                _logger.LogWarning("No claims available in user principal");
                return;
            }

            _logger.LogInformation("=== JWT Claims Debug Information ===");
            _logger.LogInformation("IsAuthenticated: {IsAuthenticated}", User.Identity?.IsAuthenticated);
            _logger.LogInformation("AuthenticationType: {AuthenticationType}", User.Identity?.AuthenticationType);
            _logger.LogInformation("Total Claims Count: {ClaimsCount}", User.Claims.Count());

            foreach (var claim in User.Claims)
            {
                _logger.LogInformation("Claim: Type='{Type}', Value='{Value}'", claim.Type, claim.Value);
            }

            _logger.LogInformation("=== End JWT Claims Debug Information ===");
        }

        /// <summary>
        /// Checks if we're in a debug environment for additional logging
        /// </summary>
        /// <returns>True if in debug environment</returns>
        private bool IsDebugEnvironment()
        {
            var environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT");
            return string.Equals(environment, "Development", StringComparison.OrdinalIgnoreCase) ||
                   string.Equals(environment, "Staging", StringComparison.OrdinalIgnoreCase);
        }

        /// <summary>
        /// Executes an operation that requires authentication and handles common errors
        /// </summary>
        /// <param name="operation">The operation to execute</param>
        /// <param name="operationName">Name of the operation for logging</param>
        /// <returns>Task containing the operation result</returns>
        protected async Task<IActionResult> ExecuteAuthenticatedOperationAsync<T>(
            Func<Guid, Task<T>> operation, 
            string operationName) where T : class
        {
            try
            {
                _logger.LogInformation("{OperationName} called", operationName);

                var userId = GetCurrentUserId();
                _logger.LogDebug("Executing {OperationName} for user: {UserId}", operationName, userId);

                var result = await operation(userId);
                
                if (result == null)
                {
                    _logger.LogWarning("{OperationName} returned null result for user: {UserId}", operationName, userId);
                    return NotFound(new { message = "Resource not found" });
                }

                _logger.LogInformation("{OperationName} completed successfully for user: {UserId}", operationName, userId);
                return Ok(result);
            }
            catch (UnauthorizedAccessException ex)
            {
                _logger.LogWarning("Authentication error in {OperationName}: {Message}", operationName, ex.Message);
                return Unauthorized(new { message = ex.Message });
            }
            catch (Exception ex) when (ex.GetType().Name.Contains("Domain"))
            {
                return HandleDomainException(ex, operationName);
            }
            catch (Exception ex)
            {
                return HandleUnexpectedException(ex, operationName);
            }
        }

        /// <summary>
        /// Executes an operation that requires authentication and returns no content on success
        /// </summary>
        /// <param name="operation">The operation to execute</param>
        /// <param name="operationName">Name of the operation for logging</param>
        /// <returns>Task containing the operation result</returns>
        protected async Task<IActionResult> ExecuteAuthenticatedVoidOperationAsync(
            Func<Guid, Task> operation, 
            string operationName)
        {
            try
            {
                _logger.LogInformation("{OperationName} called", operationName);

                var userId = GetCurrentUserId();
                _logger.LogDebug("Executing {OperationName} for user: {UserId}", operationName, userId);

                await operation(userId);

                _logger.LogInformation("{OperationName} completed successfully for user: {UserId}", operationName, userId);
                return NoContent();
            }
            catch (UnauthorizedAccessException ex)
            {
                _logger.LogWarning("Authentication error in {OperationName}: {Message}", operationName, ex.Message);
                return Unauthorized(new { message = ex.Message });
            }
            catch (Exception ex) when (ex.GetType().Name.Contains("Domain"))
            {
                return HandleDomainException(ex, operationName);
            }
            catch (Exception ex)
            {
                return HandleUnexpectedException(ex, operationName);
            }
        }
    }
}