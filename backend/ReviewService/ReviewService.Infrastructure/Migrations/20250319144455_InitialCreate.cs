using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReviewService.Infrastructure.Migrations
{
	/// <inheritdoc />
	public partial class InitialCreate : Migration
	{
		/// <inheritdoc />
		protected override void Up(MigrationBuilder migrationBuilder)
		{
			migrationBuilder.CreateTable(
				name: "Reviews",
				columns: table => new
				{
					Id = table.Column<Guid>(type: "uuid", nullable: false),
					UserId = table.Column<Guid>(type: "uuid", nullable: false),
					LocationId = table.Column<Guid>(type: "uuid", nullable: false),
					Rating = table.Column<int>(type: "integer", nullable: false),
					Content = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
					CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
					UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
				},
				constraints: table =>
				{
					table.PrimaryKey("PK_Reviews", x => x.Id);
				});

			migrationBuilder.CreateIndex(
				name: "IX_Reviews_LocationId",
				table: "Reviews",
				column: "LocationId");

			migrationBuilder.CreateIndex(
				name: "IX_Reviews_UserId",
				table: "Reviews",
				column: "UserId");
		}

		/// <inheritdoc />
		protected override void Down(MigrationBuilder migrationBuilder)
		{
			migrationBuilder.DropTable(
				name: "Reviews");
		}
	}
}