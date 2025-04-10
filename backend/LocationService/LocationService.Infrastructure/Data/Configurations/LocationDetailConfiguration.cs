using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using LocationService.Domain.Entities;

namespace LocationService.Infrastructure.Data.Configurations
{
    public class LocationDetailConfiguration : IEntityTypeConfiguration<LocationDetail>
    {
        public void Configure(EntityTypeBuilder<LocationDetail> builder)
        {
            builder.HasKey(ld => ld.Id);

            builder.Property(ld => ld.PropertyName)
                .IsRequired()
                .HasMaxLength(100);

            builder.Property(ld => ld.PropertyValue)
                .IsRequired();
        }
    }
}
