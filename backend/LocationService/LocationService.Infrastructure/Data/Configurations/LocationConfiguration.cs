// LocationConfiguration.cs

using LocationService.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

public class LocationConfiguration : IEntityTypeConfiguration<Location>
{
    public void Configure(EntityTypeBuilder<Location> builder)
    {
        builder.HasKey(l => l.Id);
        
        // Convert string ID to/from Guid in database
        builder.Property(l => l.Id)
            .HasConversion(
                v => Guid.Parse(v), // Convert string to Guid when saving to DB
                v => v.ToString()   // Convert Guid to string when loading from DB
            );

        builder.Property(l => l.Latitude)
            .IsRequired();

        builder.Property(l => l.Longitude)
            .IsRequired();

        builder.Property(l => l.Address)
            .HasMaxLength(200);
        
        builder.HasMany(l => l.Details)
            .WithOne()
            .HasForeignKey(d => d.LocationId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

