namespace LocationService.Domain.Entities
{
    public class Location
    {
        public Guid Id { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public string Address { get; set; }
        public ICollection<LocationDetail> Details { get; set; } = new List<LocationDetail>();
    }
}
