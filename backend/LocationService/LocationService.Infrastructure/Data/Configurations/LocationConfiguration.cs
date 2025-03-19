using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using LocationService.Domain.Entities;

namespace LocationService.Infrastructure.Data.Configurations
{
    public class LocationConfiguration : IEntityTypeConfiguration<Location>
    {
        public void Configure(EntityTypeBuilder<Location> builder)
        {
            builder.HasKey(l => l.Id);

            builder.Property(l => l.Name)
                .IsRequired()
                .HasMaxLength(100);

            builder.Property(l => l.Latitude)
                .IsRequired();

            builder.Property(l => l.Longitude)
                .IsRequired();

            builder.Property(l => l.Address)
                .HasMaxLength(200);

            builder.Property(l => l.City)
                .HasMaxLength(100);

            builder.Property(l => l.State)
                .HasMaxLength(100);

            builder.Property(l => l.Country)
                .HasMaxLength(100);

            builder.Property(l => l.PostalCode)
                .HasMaxLength(20);

            // Define relationships
            builder.HasMany(l => l.Details)
                .WithOne(d => d.Location)
                .HasForeignKey(d => d.LocationId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
