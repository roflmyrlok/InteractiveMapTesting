using Microsoft.EntityFrameworkCore;
using ReviewService.Domain.Entities;
using System.Text.Json;

namespace ReviewService.Infrastructure.Data;

public class ReviewDbContext : DbContext
{
	public ReviewDbContext(DbContextOptions<ReviewDbContext> options)
		: base(options)
	{
	}

	public DbSet<Review> Reviews { get; set; }

	protected override void OnModelCreating(ModelBuilder modelBuilder)
	{
		modelBuilder.Entity<Review>(entity =>
		{
			entity.HasKey(e => e.Id);

			entity.Property(e => e.UserId)
				.IsRequired();

			entity.Property(e => e.LocationId)
				.IsRequired();

			entity.Property(e => e.Rating)
				.IsRequired();

			entity.Property(e => e.Content)
				.IsRequired()
				.HasMaxLength(1000);

			entity.Property(e => e.CreatedAt)
				.IsRequired();

			entity.Property(e => e.ImageUrls)
				.HasConversion(
					v => JsonSerializer.Serialize(v, (JsonSerializerOptions)null),
					v => JsonSerializer.Deserialize<List<string>>(v, (JsonSerializerOptions)null) ?? new List<string>())
				.HasColumnType("text");
			
			entity.HasIndex(e => e.UserId);
			entity.HasIndex(e => e.LocationId);
		});

		base.OnModelCreating(modelBuilder);
	}

	public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
	{
		foreach (var entry in ChangeTracker.Entries<Review>())
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