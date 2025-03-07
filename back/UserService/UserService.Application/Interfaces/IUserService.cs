using UserService.Application.DTOs;

namespace UserService.Application.Interfaces;
public interface IUserService
{
	Task<IEnumerable<UserDto>> GetAllUsersAsync();
	Task<UserDto> GetUserByIdAsync(Guid id);
	Task<UserDto> GetUserByEmailAsync(string email);
	Task<UserDto> GetUserByUsernameAsync(string username);
	Task<UserDto> CreateUserAsync(CreateUserDto createUserDto);
	Task<UserDto> UpdateUserAsync(UpdateUserDto updateUserDto);
	Task DeleteUserAsync(Guid id);
	Task<bool> ValidateUserCredentialsAsync(string username, string password);
}