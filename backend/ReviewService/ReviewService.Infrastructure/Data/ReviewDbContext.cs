using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using ReviewService.Domain.Entities;
using ReviewService.Domain.Enums;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

namespace ReviewService.Infrastructure.Data;

public class ReviewDbContext : DbContext
{
    public ReviewDbContext(DbContextOptions<ReviewDbContext> options)
        : base(options)
    {
    }
    
    public DbSet<Review> Reviews { get; set; }
    
    public DbSet<LocationInstantFeedback> LocationInstantFeedbacks { get; set; }
    public DbSet<LocationInstantStatus> LocationInstantStatuses { get; set; }

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

        // LocationInstantFeedback configuration
        modelBuilder.Entity<LocationInstantFeedback>(entity =>
        {
            entity.HasKey(e => e.Id);
            
            entity.Property(e => e.LocationId)
                .IsRequired();
                
            entity.Property(e => e.UserId)
                .IsRequired();
                
            entity.Property(e => e.FeedbackType)
                .IsRequired()
                .HasConversion<int>();
                
            entity.Property(e => e.CreatedAt)
                .IsRequired();
            
            entity.HasIndex(e => e.LocationId);
            entity.HasIndex(e => e.UserId);
            
            // Unique constraint: one feedback per user per location
            entity.HasIndex(e => new { e.LocationId, e.UserId })
                .IsUnique()
                .HasDatabaseName("IX_LocationInstantFeedbacks_LocationId_UserId_Unique");
        });

        // LocationInstantStatus configuration  
        modelBuilder.Entity<LocationInstantStatus>(entity =>
        {
            entity.HasKey(e => e.Id);
            
            entity.Property(e => e.LocationId)
                .IsRequired();
                
            entity.Property(e => e.AllGoodCount)
                .IsRequired()
                .HasDefaultValue(0);
                
            entity.Property(e => e.ProblemInsideCount)
                .IsRequired()
                .HasDefaultValue(0);
                
            entity.Property(e => e.CantGetInCount)
                .IsRequired()
                .HasDefaultValue(0);
                
            entity.Property(e => e.DominantStatus)
                .IsRequired()
                .HasConversion<int>()
                .HasDefaultValue(InstantFeedbackType.AllGood);
                
            entity.Property(e => e.ColorCode)
                .IsRequired()
                .HasMaxLength(10)
                .HasDefaultValue("teal");
                
            entity.Property(e => e.LastUpdated)
                .IsRequired();
            
            // Unique constraint: one status per location
            entity.HasIndex(e => e.LocationId)
                .IsUnique()
                .HasDatabaseName("IX_LocationInstantStatuses_LocationId_Unique");
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

        foreach (var entry in ChangeTracker.Entries<LocationInstantFeedback>())
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

        foreach (var entry in ChangeTracker.Entries<LocationInstantStatus>())
        {
            switch (entry.State)
            {
                case EntityState.Added:
                case EntityState.Modified:
                    entry.Entity.LastUpdated = DateTime.UtcNow;
                    break;
            }
        }

        return base.SaveChangesAsync(cancellationToken);
    }
}