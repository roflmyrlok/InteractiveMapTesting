using Google.Protobuf.WellKnownTypes;
using LocationService.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace LocationService.Infrastructure.Data;

public class LocationDbContext : DbContext
{
    public LocationDbContext(DbContextOptions<LocationDbContext> options)
        : base(options)
    {
    }

    public DbSet<Location> Locations { get; set; } = null!;
    public DbSet<LocationDetail> LocationDetails { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Location>(entity =>
        {
            entity.HasKey(l => l.Id);
            
            entity.Property(l => l.Id)
                .IsRequired();

            entity.Property(l => l.Latitude)
                .IsRequired();

            entity.Property(l => l.Longitude)
                .IsRequired();

            entity.Property(l => l.Address)
                .HasMaxLength(200);
            
            entity.Property(l => l.CreatedAt)
                .HasConversion(
                    v => v.ToDateTime(),
                    v => Timestamp.FromDateTime(DateTime.SpecifyKind(v, DateTimeKind.Utc))
                );
            
            entity.Property(l => l.UpdatedAt)
                .HasConversion(
                    v => v != null ? v.ToDateTime() : (DateTime?)null,
                    v => v.HasValue 
                        ? Timestamp.FromDateTime(DateTime.SpecifyKind(v.Value, DateTimeKind.Utc)) 
                        : null
                )
                .IsRequired(false);

            entity.HasMany<LocationDetail>()
                .WithOne()
                .HasForeignKey(d => d.LocationId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<LocationDetail>(entity =>
        {
            entity.HasKey(d => d.Id);
            
            entity.Property(d => d.Id)
                .IsRequired();

            entity.Property(d => d.LocationId)
                .IsRequired();

            entity.Property(d => d.PropertyName)
                .IsRequired()
                .HasMaxLength(50);

            entity.Property(d => d.PropertyValue)
                .IsRequired()
                .HasMaxLength(500);
        });

        base.OnModelCreating(modelBuilder);
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        foreach (var entry in ChangeTracker.Entries<Location>())
        {
            switch (entry.State)
            {
                case EntityState.Added:
                    entry.Entity.CreatedAt ??= Timestamp.FromDateTime(DateTime.UtcNow);
                    break;
                case EntityState.Modified:
                    entry.Entity.UpdatedAt = Timestamp.FromDateTime(DateTime.UtcNow);
                    break;
            }
        }

        return base.SaveChangesAsync(cancellationToken);
    }
}