using System;
using System.Collections.Generic;
using System.Linq.Expressions;
using System.Threading.Tasks;
using UserService.Domain.Entities;

namespace UserService.Application.Interfaces;

public interface IUserRepository
{
	Task<IEnumerable<User>> GetAllAsync();
	Task<IEnumerable<User>> FindAsync(Expression<Func<User, bool>> predicate);
	Task<User> GetByIdAsync(Guid id);
	Task<User> AddAsync(User user);
	Task UpdateAsync(User user);
	Task DeleteAsync(Guid id);
	Task<bool> ExistsAsync(Guid id);
	Task<bool> ExistsByUsernameAsync(string username);
	Task<bool> ExistsByEmailAsync(string email);
}