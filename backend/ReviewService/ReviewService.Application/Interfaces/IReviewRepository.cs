using System.Linq.Expressions;
using ReviewService.Domain.Entities;

namespace ReviewService.Application.Interfaces;

public interface IReviewRepository
{
    Task<IEnumerable<Review>> GetAllAsync();
    Task<IEnumerable<Review>> FindAsync(Expression<Func<Review, bool>> predicate);
    Task<Review> GetByIdAsync(Guid id);
    Task<Review> AddAsync(Review review);
    Task UpdateAsync(Review review);
    Task DeleteAsync(Guid id);
    Task<bool> ExistsAsync(Guid id);
}
