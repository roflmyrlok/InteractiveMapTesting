using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ReviewService.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddInstantFeedbackSystem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "LocationInstantFeedbacks",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    LocationId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    FeedbackType = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LocationInstantFeedbacks", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "LocationInstantStatuses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    LocationId = table.Column<Guid>(type: "uuid", nullable: false),
                    AllGoodCount = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    ProblemInsideCount = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    CantGetInCount = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    DominantStatus = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    ColorCode = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false, defaultValue: "teal"),
                    LastUpdated = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LocationInstantStatuses", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_LocationInstantFeedbacks_LocationId",
                table: "LocationInstantFeedbacks",
                column: "LocationId");

            migrationBuilder.CreateIndex(
                name: "IX_LocationInstantFeedbacks_LocationId_UserId_Unique",
                table: "LocationInstantFeedbacks",
                columns: new[] { "LocationId", "UserId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_LocationInstantFeedbacks_UserId",
                table: "LocationInstantFeedbacks",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_LocationInstantStatuses_LocationId_Unique",
                table: "LocationInstantStatuses",
                column: "LocationId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "LocationInstantFeedbacks");

            migrationBuilder.DropTable(
                name: "LocationInstantStatuses");
        }
    }
}
