using Microsoft.AspNetCore.Mvc;

namespace ReviewService.API.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class HealthController : ControllerBase
	{
		[HttpGet]
		public IActionResult Check()
		{
			return Ok(new { status = "healthy", timestamp = DateTime.UtcNow });
		}
	}
}