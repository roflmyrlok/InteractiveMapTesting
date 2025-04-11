using Microsoft.EntityFrameworkCore;
using LocationService.Domain.Entities;

namespace LocationService.Infrastructure.Data
{
    public class LocationDbContext : DbContext
    {
        public LocationDbContext(DbContextOptions<LocationDbContext> options)
            : base(options)
        {
        }

        public DbSet<Location> Locations { get; set; }
        public DbSet<LocationDetail> LocationDetails { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Location>(entity =>
            {
                entity.HasKey(l => l.Id);

                entity.Property(l => l.Latitude)
                    .IsRequired();

                entity.Property(l => l.Longitude)
                    .IsRequired();

                entity.Property(l => l.Address)
                    .HasMaxLength(200);
                
                entity.HasMany(l => l.Details)
                    .WithOne(d => d.Location)
                    .HasForeignKey(d => d.LocationId)
                    .OnDelete(DeleteBehavior.Cascade);
            });
            
            modelBuilder.Entity<LocationDetail>(entity =>
            {
                entity.HasKey(d => d.Id);

                entity.Property(d => d.LocationId)
                    .IsRequired();

                entity.Property(d => d.PropertyName)
                    .IsRequired()
                    .HasMaxLength(50);

                entity.Property(d => d.PropertyValue)
                    .IsRequired()
                    .HasMaxLength(500);
                
                entity.HasOne(d => d.Location)
                    .WithMany(l => l.Details)
                    .HasForeignKey(d => d.LocationId)
                    .OnDelete(DeleteBehavior.Cascade);
                
                entity.HasIndex(d => new { d.LocationId, d.PropertyName })
                    .IsUnique();
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
}