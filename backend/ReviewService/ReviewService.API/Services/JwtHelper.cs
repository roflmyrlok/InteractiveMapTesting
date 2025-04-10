using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.Extensions.Logging;

namespace ReviewService.API.Services;

public static class JwtHelper
{
	public static Guid GetUserIdFromToken(ClaimsPrincipal user)
	{
		// Try standard JWT claim types first
		var userIdClaim = user.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
		
		// If not found, try alternative claim types
		if (string.IsNullOrEmpty(userIdClaim))
		{
			userIdClaim = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
		}
		
		if (string.IsNullOrEmpty(userIdClaim))
		{
			userIdClaim = user.FindFirst(JwtRegisteredClaimNames.NameId)?.Value;
		}
		
		if (string.IsNullOrEmpty(userIdClaim))
		{
			// Try to find any claim that might contain a user ID
			userIdClaim = user.Claims.FirstOrDefault(c => 
				c.Type.Contains("userid", StringComparison.OrdinalIgnoreCase) ||
				c.Type.Contains("nameidentifier", StringComparison.OrdinalIgnoreCase) ||
				c.Type.Contains("sub", StringComparison.OrdinalIgnoreCase))?.Value;
		}
		
		// Last resort - dump all claims to help debug
		if (string.IsNullOrEmpty(userIdClaim))
		{
			var allClaims = string.Join(", ", user.Claims.Select(c => $"{c.Type}: {c.Value}"));
			throw new UnauthorizedAccessException($"Invalid or missing user identifier in the token. Available claims: {allClaims}");
		}
		
		if (!Guid.TryParse(userIdClaim, out var userId))
		{
			throw new UnauthorizedAccessException($"User identifier '{userIdClaim}' is not a valid GUID");
		}
		
		return userId;
	}
	
	public static string GetUserRoleFromToken(ClaimsPrincipal user)
	{
		var roleClaim = user.FindFirst(ClaimTypes.Role)?.Value;
		
		if (string.IsNullOrEmpty(roleClaim))
		{
			roleClaim = user.Claims.FirstOrDefault(c => 
				c.Type.Contains("role", StringComparison.OrdinalIgnoreCase))?.Value;
		}
		
		return roleClaim ?? "Regular";
	}
}