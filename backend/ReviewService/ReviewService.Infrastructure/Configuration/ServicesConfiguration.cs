namespace ReviewService.Infrastructure.Configuration;

public class ServicesConfiguration
{
	public LocationServiceConfiguration LocationService { get; set; } = new();
}

public class LocationServiceConfiguration
{
	public string BaseUrl { get; set; } = string.Empty;
}