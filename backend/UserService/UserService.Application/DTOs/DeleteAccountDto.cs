using System.ComponentModel.DataAnnotations;

namespace UserService.Application.DTOs
{
	public class DeleteAccountDto
	{
		[Required]
		public string CurrentPassword { get; set; }
	}
}