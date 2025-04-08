using System;
using System.Globalization;

namespace DataAcquisition.Core.Utils
{
	public static class GeoCoordinateParser
	{
		public static bool TryParseCoordinates(string coordString, out double latitude, out double longitude)
		{
			latitude = 0;
			longitude = 0;

			if (string.IsNullOrWhiteSpace(coordString))
				return false;

			string[] parts = coordString.Trim().Split(',');
			if (parts.Length != 2)
				return false;

			bool latParsed = double.TryParse(parts[0].Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out latitude);
			bool longParsed = double.TryParse(parts[1].Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out longitude);

			return latParsed && longParsed;
		}

		public static bool AreCoordinatesValid(double latitude, double longitude)
		{
			return latitude >= -90 && latitude <= 90 && 
			       longitude >= -180 && longitude <= 180;
		}
	}
}