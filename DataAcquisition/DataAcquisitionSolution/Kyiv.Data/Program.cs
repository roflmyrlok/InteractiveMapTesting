// using System.Net.Http;
// using System.IO;
// using System.Threading.Tasks;
//
// class Program
// {
// 	static async Task Main()
// 	{
// 		var url = "https://gisserver.kyivcity.gov.ua/mayno/rest/services/KYIV_API/Київ_Цифровий/MapServer/0/query?where=1%3D1&text=&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&distance=&units=esriSRUnit_Foot&relationParam=&outFields=*&returnGeometry=true&returnTrueCurves=false&maxAllowableOffset=&geometryPrecision=&outSR=4326&havingClause=&returnIdsOnly=false&returnCountOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&gdbVersion=&historicMoment=&returnDistinctValues=false&resultOffset=&resultRecordCount=&returnExtentOnly=false&datumTransformation=&parameterValues=&rangeValues=&quantizationParameters=&featureEncoding=esriDefault&f=pjson";
// 		var filePath = Path.Combine(Directory.GetCurrentDirectory(), "shelters.json");
//
// 		using var client = new HttpClient();
// 		var json = await client.GetStringAsync(url);
//
// 		await File.WriteAllTextAsync(filePath, json);
// 	}
// }
//
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.IO;
using System.Threading.Tasks;
using System.Collections.Generic;

class Program
{
    static async Task Main()
    {
        var token = "";      
        using var client = new HttpClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var filePath = Path.Combine(AppContext.BaseDirectory, "shelters.json");

        var json = await File.ReadAllTextAsync(filePath);
        
        var root = JsonDocument.Parse(json);
        var features = root.RootElement.GetProperty("features");

        foreach (var feature in features.EnumerateArray())
        {
            var attributes = feature.GetProperty("attributes");
            var geometry = feature.GetProperty("geometry");

            var latitude = geometry.GetProperty("y").GetDouble();
            var longitude = geometry.GetProperty("x").GetDouble();
            var name = attributes.TryGetProperty("NAME", out var nameProp) ? nameProp.GetString() ?? "Unknown" : "Unknown";
            var address = attributes.TryGetProperty("ADDRESS", out var addressProp) ? addressProp.GetString() ?? "" : "";

            
            var payload = new
            {
                name,
                latitude,
                longitude,
                address,
                city = "Kyiv",
                state = "",
                country = "Ukraine",
                postalCode = "",
                details = new List<object>()
            };

            var knownProps = new[] { "NAME", "ADDRESS" };

            foreach (var attr in attributes.EnumerateObject())
            {
                if (!knownProps.Contains(attr.Name) && attr.Value.ValueKind != JsonValueKind.Null)
                {
                    payload.details.Add(new
                    {
                        propertyName = attr.Name,
                        propertyValue = attr.Value.ToString()
                    });
                }
            }

            var content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

            var response = await client.PostAsync("http://ec2-3-122-118-9.eu-central-1.compute.amazonaws.com:5282/api/Locations", content);
            if (response.IsSuccessStatusCode)
                Console.WriteLine($"Success: {name}");
            else
                Console.WriteLine($"Failed: {name} - {response.StatusCode}");
        }
    }
}
