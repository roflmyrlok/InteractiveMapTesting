using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using ReviewService.Application.Interfaces;
using ReviewService.Domain.Entities;

namespace ReviewService.Infrastructure.Data.Repositories;

public class ReviewRepository : IReviewRepository
{
    private readonly ReviewDbContext _context;

    public ReviewRepository(ReviewDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<Review>> GetAllAsync()
    {
        return await _context.Reviews.ToListAsync();
    }

    public async Task<IEnumerable<Review>> FindAsync(Expression<Func<Review, bool>> predicate)
    {
        return await _context.Reviews.Where(predicate).ToListAsync();
    }

    public async Task<Review> GetByIdAsync(Guid id)
    {
        return await _context.Reviews.FindAsync(id);
    }

    public async Task<Review> AddAsync(Review review)
    {
        _context.Reviews.Add(review);
        await _context.SaveChangesAsync();
        return review;
    }

    public async Task UpdateAsync(Review review)
    {
        _context.Entry(review).State = EntityState.Modified;
        await _context.SaveChangesAsync();
    }

    public async Task DeleteAsync(Guid id)
    {
        var review = await _context.Reviews.FindAsync(id);
        if (review != null)
        {
            _context.Reviews.Remove(review);
            await _context.SaveChangesAsync();
        }
    }

    public async Task<bool> ExistsAsync(Guid id)
    {
        return await _context.Reviews.AnyAsync(e => e.Id == id);
    }
}
