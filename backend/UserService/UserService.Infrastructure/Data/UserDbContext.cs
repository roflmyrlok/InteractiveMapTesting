using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using UserService.Domain.Entities;
using UserService.Infrastructure.Data.Configurations;

namespace UserService.Infrastructure.Data;

public class UserDbContext : DbContext
{
	public UserDbContext(DbContextOptions<UserDbContext> options)
		: base(options)
	{
	}

	public DbSet<User> Users { get; set; }

	protected override void OnModelCreating(ModelBuilder modelBuilder)
	{
		modelBuilder.ApplyConfiguration(new UserConfiguration());
            
		base.OnModelCreating(modelBuilder);
	}

	public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
	{
		foreach (var entry in ChangeTracker.Entries<User>())
		{
			switch (entry.State)
			{
				case EntityState.Added:
					entry.Entity.CreatedAt = DateTime.UtcNow;
					break;
				case EntityState.Modified:
					entry.Entity.UpdatedAt = DateTime.UtcNow;
					break;
			}
		}

		return base.SaveChangesAsync(cancellationToken);
	}
}