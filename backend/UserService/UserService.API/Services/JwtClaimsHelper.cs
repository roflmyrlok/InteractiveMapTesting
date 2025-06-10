using System;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using Microsoft.Extensions.Logging;

namespace UserService.API.Services
{
    /// <summary>
    /// Centralized service for extracting JWT claims consistently across all controllers
    /// </summary>
    public static class JwtClaimsHelper
    {
        /// <summary>
        /// Extracts user ID from JWT claims with multiple fallback mechanisms
        /// </summary>
        /// <param name="user">The ClaimsPrincipal from the current HTTP context</param>
        /// <param name="logger">Logger for debugging purposes</param>
        /// <returns>User ID as Guid, or null if not found or invalid</returns>
        public static Guid? GetUserIdFromClaims(ClaimsPrincipal user, ILogger logger = null)
        {
            if (user?.Identity?.IsAuthenticated != true)
            {
                logger?.LogWarning("User is not authenticated");
                return null;
            }

            try
            {
                // Try multiple claim types that might contain the user ID, in order of preference
                var possibleClaimTypes = new[]
                {
                    JwtRegisteredClaimNames.Sub,           // Standard JWT "sub" claim
                    ClaimTypes.NameIdentifier,             // Microsoft identity claim
                    "sub",                                 // Direct "sub" string
                    "user_id",                             // Alternative user ID claim
                    "userId",                              // CamelCase variant
                    "userid",                              // Lowercase variant
                    JwtRegisteredClaimNames.NameId         // JWT name ID claim
                };

                string userIdValue = null;
                string foundClaimType = null;

                foreach (var claimType in possibleClaimTypes)
                {
                    var claim = user.FindFirst(claimType);
                    if (claim != null && !string.IsNullOrWhiteSpace(claim.Value))
                    {
                        userIdValue = claim.Value;
                        foundClaimType = claimType;
                        break;
                    }
                }

                if (string.IsNullOrWhiteSpace(userIdValue))
                {
                    // Last resort: search for any claim that might contain a user ID
                    var potentialUserIdClaim = user.Claims.FirstOrDefault(c =>
                        c.Type.Contains("userid", StringComparison.OrdinalIgnoreCase) ||
                        c.Type.Contains("nameidentifier", StringComparison.OrdinalIgnoreCase) ||
                        c.Type.Contains("sub", StringComparison.OrdinalIgnoreCase) ||
                        c.Type.EndsWith("/nameidentifier", StringComparison.OrdinalIgnoreCase));

                    if (potentialUserIdClaim != null && !string.IsNullOrWhiteSpace(potentialUserIdClaim.Value))
                    {
                        userIdValue = potentialUserIdClaim.Value;
                        foundClaimType = potentialUserIdClaim.Type;
                    }
                }

                if (string.IsNullOrWhiteSpace(userIdValue))
                {
                    logger?.LogWarning("No user ID found in JWT claims. Available claims: {Claims}",
                        string.Join(", ", user.Claims.Select(c => $"{c.Type}='{c.Value}'")));
                    return null;
                }

                if (!Guid.TryParse(userIdValue, out var userId))
                {
                    logger?.LogWarning("User ID value '{UserIdValue}' from claim '{ClaimType}' is not a valid GUID",
                        userIdValue, foundClaimType);
                    return null;
                }

                logger?.LogDebug("Successfully extracted user ID {UserId} from claim type '{ClaimType}'",
                    userId, foundClaimType);

                return userId;
            }
            catch (Exception ex)
            {
                logger?.LogError(ex, "Error extracting user ID from JWT claims");
                return null;
            }
        }

        /// <summary>
        /// Extracts user role from JWT claims with fallback mechanisms
        /// </summary>
        /// <param name="user">The ClaimsPrincipal from the current HTTP context</param>
        /// <param name="logger">Logger for debugging purposes</param>
        /// <returns>User role as string, defaults to "Regular" if not found</returns>
        public static string GetUserRoleFromClaims(ClaimsPrincipal user, ILogger logger = null)
        {
            if (user?.Identity?.IsAuthenticated != true)
            {
                logger?.LogWarning("User is not authenticated, returning default role");
                return "Regular";
            }

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
                    var roleClaim = user.FindFirst(claimType);
                    if (roleClaim != null && !string.IsNullOrWhiteSpace(roleClaim.Value))
                    {
                        logger?.LogDebug("Found user role '{Role}' from claim type '{ClaimType}'",
                            roleClaim.Value, claimType);
                        return roleClaim.Value;
                    }
                }

                // Last resort: search for any claim that might contain a role
                var potentialRoleClaim = user.Claims.FirstOrDefault(c =>
                    c.Type.Contains("role", StringComparison.OrdinalIgnoreCase));

                if (potentialRoleClaim != null && !string.IsNullOrWhiteSpace(potentialRoleClaim.Value))
                {
                    logger?.LogDebug("Found user role '{Role}' from potential role claim '{ClaimType}'",
                        potentialRoleClaim.Value, potentialRoleClaim.Type);
                    return potentialRoleClaim.Value;
                }

                logger?.LogDebug("No role found in JWT claims, using default 'Regular'");
                return "Regular";
            }
            catch (Exception ex)
            {
                logger?.LogError(ex, "Error extracting user role from JWT claims, using default 'Regular'");
                return "Regular";
            }
        }

        /// <summary>
        /// Extracts username from JWT claims with fallback mechanisms
        /// </summary>
        /// <param name="user">The ClaimsPrincipal from the current HTTP context</param>
        /// <param name="logger">Logger for debugging purposes</param>
        /// <returns>Username as string, or null if not found</returns>
        public static string GetUsernameFromClaims(ClaimsPrincipal user, ILogger logger = null)
        {
            if (user?.Identity?.IsAuthenticated != true)
            {
                logger?.LogWarning("User is not authenticated");
                return null;
            }

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
                    var usernameClaim = user.FindFirst(claimType);
                    if (usernameClaim != null && !string.IsNullOrWhiteSpace(usernameClaim.Value))
                    {
                        logger?.LogDebug("Found username '{Username}' from claim type '{ClaimType}'",
                            usernameClaim.Value, claimType);
                        return usernameClaim.Value;
                    }
                }

                logger?.LogDebug("No username found in JWT claims");
                return null;
            }
            catch (Exception ex)
            {
                logger?.LogError(ex, "Error extracting username from JWT claims");
                return null;
            }
        }

        /// <summary>
        /// Extracts email from JWT claims with fallback mechanisms
        /// </summary>
        /// <param name="user">The ClaimsPrincipal from the current HTTP context</param>
        /// <param name="logger">Logger for debugging purposes</param>
        /// <returns>Email as string, or null if not found</returns>
        public static string GetEmailFromClaims(ClaimsPrincipal user, ILogger logger = null)
        {
            if (user?.Identity?.IsAuthenticated != true)
            {
                logger?.LogWarning("User is not authenticated");
                return null;
            }

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
                    var emailClaim = user.FindFirst(claimType);
                    if (emailClaim != null && !string.IsNullOrWhiteSpace(emailClaim.Value))
                    {
                        logger?.LogDebug("Found email '{Email}' from claim type '{ClaimType}'",
                            emailClaim.Value, claimType);
                        return emailClaim.Value;
                    }
                }

                logger?.LogDebug("No email found in JWT claims");
                return null;
            }
            catch (Exception ex)
            {
                logger?.LogError(ex, "Error extracting email from JWT claims");
                return null;
            }
        }

        /// <summary>
        /// Logs all available claims for debugging purposes
        /// </summary>
        /// <param name="user">The ClaimsPrincipal from the current HTTP context</param>
        /// <param name="logger">Logger instance</param>
        public static void LogAllClaims(ClaimsPrincipal user, ILogger logger)
        {
            if (user?.Claims == null)
            {
                logger.LogWarning("No claims available in user principal");
                return;
            }

            logger.LogInformation("=== JWT Claims Debug Information ===");
            logger.LogInformation("IsAuthenticated: {IsAuthenticated}", user.Identity?.IsAuthenticated);
            logger.LogInformation("AuthenticationType: {AuthenticationType}", user.Identity?.AuthenticationType);
            logger.LogInformation("Total Claims Count: {ClaimsCount}", user.Claims.Count());

            foreach (var claim in user.Claims)
            {
                logger.LogInformation("Claim: Type='{Type}', Value='{Value}'", claim.Type, claim.Value);
            }

            logger.LogInformation("=== End JWT Claims Debug Information ===");
        }
    }
}