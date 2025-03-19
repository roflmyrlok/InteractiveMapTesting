namespace LocationService.Domain.Entities
{
    public class LocationDetail
    {
        public Guid Id { get; set; }
        public Guid LocationId { get; set; }
        public string PropertyName { get; set; }
        public string PropertyValue { get; set; }
        public Location Location { get; set; }
    }
}
