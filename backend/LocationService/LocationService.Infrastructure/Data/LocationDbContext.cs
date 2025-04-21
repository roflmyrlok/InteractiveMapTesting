using Microsoft.EntityFrameworkCore;
using Location = LocationService.Domain.Entities.Location;
using LocationDetail = LocationService.Domain.Entities.LocationDetail;
using Google.Protobuf.WellKnownTypes;

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
                
                entity.Property(l => l.Id)
                    .HasConversion(
                        v => Guid.Parse(v),   // Convert string to Guid for DB
                        v => v.ToString()     // Convert Guid to string from DB
                    );

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
                        v => v == null ? (DateTime?)null : v.ToDateTime(),
                        v => v.HasValue ? Timestamp.FromDateTime(DateTime.SpecifyKind(v.Value, DateTimeKind.Utc)) : null
                    );
                
                entity.HasMany(l => l.Details)
                    .WithOne()
                    .HasForeignKey(d => d.LocationId)
                    .OnDelete(DeleteBehavior.Cascade);
            });
            
            modelBuilder.Entity<LocationDetail>(entity =>
            {
                entity.HasKey(d => d.Id);
                
                entity.Property(d => d.Id)
                    .HasConversion(
                        v => Guid.Parse(v),
                        v => v.ToString()
                    );

                entity.Property(d => d.LocationId)
                    .HasConversion(
                        v => Guid.Parse(v),
                        v => v.ToString()
                    )
                    .IsRequired();

                entity.Property(d => d.PropertyName)
                    .IsRequired()
                    .HasMaxLength(50);

                entity.Property(d => d.PropertyValue)
                    .IsRequired()
                    .HasMaxLength(500);
                
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
                        entry.Entity.CreatedAt = Timestamp.FromDateTime(DateTime.UtcNow);
                        break;
                    case EntityState.Modified:
                        entry.Entity.UpdatedAt = Timestamp.FromDateTime(DateTime.UtcNow);
                        break;
                }
            }

            return base.SaveChangesAsync(cancellationToken);
        }
    }
}