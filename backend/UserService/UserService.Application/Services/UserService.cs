using AutoMapper;
using System.Security.Cryptography;
using System.Text;
using UserService.Application.DTOs;
using UserService.Application.Interfaces;
using UserService.Domain.Entities;
using UserService.Domain.Exceptions;

namespace UserService.Application.Services;

public class UserService : IUserService
{
    private readonly IUserRepository _userRepository;
    private readonly IMapper _mapper;

    public UserService(IUserRepository userRepository, IMapper mapper)
    {
        _userRepository = userRepository;
        _mapper = mapper;
    }

    public async Task<IEnumerable<UserDto>> GetAllUsersAsync()
    {
        var users = await _userRepository.GetAllAsync();
        return _mapper.Map<IEnumerable<UserDto>>(users);
    }

    public async Task<UserDto> GetUserByIdAsync(Guid id)
    {
        var user = await _userRepository.GetByIdAsync(id);
        if (user == null)
        {
            throw new DomainException($"User with ID {id} not found");
        }
            
        return _mapper.Map<UserDto>(user);
    }

    public async Task<UserDto> GetUserByEmailAsync(string email)
    {
        var users = await _userRepository.FindAsync(u => u.Email == email);
        var user = users.FirstOrDefault();
            
        if (user == null)
        {
            throw new DomainException($"User with email {email} not found");
        }
            
        return _mapper.Map<UserDto>(user);
    }

    public async Task<UserDto> GetUserByUsernameAsync(string username)
    {
        var users = await _userRepository.FindAsync(u => u.Username == username);
        var user = users.FirstOrDefault();
            
        if (user == null)
        {
            throw new DomainException($"User with username {username} not found");
        }
            
        return _mapper.Map<UserDto>(user);
    }

    public async Task<UserDto> CreateUserAsync(CreateUserDto createUserDto)
    {

        if (await _userRepository.ExistsByUsernameAsync(createUserDto.Username))
        {
            throw new DomainException($"Username '{createUserDto.Username}' is already taken");
        }

        if (await _userRepository.ExistsByEmailAsync(createUserDto.Email))
        {
            throw new DomainException($"Email '{createUserDto.Email}' is already registered");
        }

        var user = _mapper.Map<User>(createUserDto);

        user.PasswordHash = HashPassword(createUserDto.Password);
        user.Id = Guid.NewGuid();
            
        await _userRepository.AddAsync(user);
            
        return _mapper.Map<UserDto>(user);
    }

    public async Task<UserDto> UpdateUserAsync(UpdateUserDto updateUserDto)
    {
        var user = await _userRepository.GetByIdAsync(updateUserDto.Id);
        if (user == null)
        {
            throw new DomainException($"User with ID {updateUserDto.Id} not found");
        }
            
        if (!string.IsNullOrEmpty(updateUserDto.Email) && updateUserDto.Email != user.Email)
        {
            if (await _userRepository.ExistsByEmailAsync(updateUserDto.Email))
            {
                throw new DomainException($"Email '{updateUserDto.Email}' is already registered");
            }
        }

        _mapper.Map(updateUserDto, user);

        await _userRepository.UpdateAsync(user);
            
        return _mapper.Map<UserDto>(user);
    }

    public async Task DeleteUserAsync(Guid id)
    {
        if (!await _userRepository.ExistsAsync(id))
        {
            throw new DomainException($"User with ID {id} not found");
        }
            
        await _userRepository.DeleteAsync(id);
    }

    public async Task<bool> ValidateUserCredentialsAsync(string username, string password)
    {
        var users = await _userRepository.FindAsync(u => u.Username == username);
        var user = users.FirstOrDefault();
            
        if (user == null)
        {
            return false;
        }
            
        var hashedPassword = HashPassword(password);
        return user.PasswordHash == hashedPassword;
    }

    private string HashPassword(string password)
    {
        using (var sha256 = SHA256.Create())
        {
            var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(hashedBytes);
        }
    }
}