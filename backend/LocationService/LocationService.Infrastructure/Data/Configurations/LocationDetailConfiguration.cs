using LocationService.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

public class LocationDetailConfiguration : IEntityTypeConfiguration<LocationDetail>
{
	public void Configure(EntityTypeBuilder<LocationDetail> builder)
	{
		builder.HasKey(d => d.Id);
        
		// Convert string ID to/from Guid in database
		builder.Property(d => d.Id)
			.HasConversion(
				v => Guid.Parse(v),
				v => v.ToString()
			);
            
		// Convert LocationId string to/from Guid
		builder.Property(d => d.LocationId)
			.HasConversion(
				v => Guid.Parse(v),
				v => v.ToString()
			)
			.IsRequired();
            
		builder.Property(d => d.PropertyName)
			.IsRequired()
			.HasMaxLength(100);

		builder.Property(d => d.PropertyValue)
			.IsRequired();
            
		// Configure the relationship using the string LocationId property
		builder.HasOne<Location>()
			.WithMany(l => l.Details)
			.HasForeignKey(d => d.LocationId)
			.OnDelete(DeleteBehavior.Cascade);
	}
}