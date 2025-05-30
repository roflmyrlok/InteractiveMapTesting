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
            
            builder.Property(l => l.Latitude)
                .IsRequired();

            builder.Property(l => l.Longitude)
                .IsRequired();

            builder.Property(l => l.Address)
                .HasMaxLength(200);
            
            builder.HasMany(l => l.Details)
                .WithOne(d => d.Location)
                .HasForeignKey(d => d.LocationId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
