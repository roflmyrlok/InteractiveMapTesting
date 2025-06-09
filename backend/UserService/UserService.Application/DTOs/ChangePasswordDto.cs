using System.ComponentModel.DataAnnotations;

namespace UserService.Application.DTOs
{
	public class ChangePasswordDto
	{
		[Required]
		public string CurrentPassword { get; set; }
        
		[Required]
		[MinLength(8)]
		public string NewPassword { get; set; }
        
		[Required]
		[Compare("NewPassword")]
		public string ConfirmNewPassword { get; set; }
	}
}