using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using UserService.Domain.Entities;

namespace UserService.Infrastructure.Data.Configurations
{
	public class UserConfiguration : IEntityTypeConfiguration<User>
	{
		public void Configure(EntityTypeBuilder<User> builder)
		{
			builder.HasKey(u => u.Id);

			builder.Property(u => u.Username)
				.IsRequired()
				.HasMaxLength(50);

			builder.Property(u => u.Email)
				.IsRequired()
				.HasMaxLength(100);

			builder.Property(u => u.PasswordHash)
				.IsRequired();

			builder.Property(u => u.FirstName)
				.HasMaxLength(50);

			builder.Property(u => u.LastName)
				.HasMaxLength(50);
			
			builder.HasIndex(u => u.Email).IsUnique();
		}
	}
}