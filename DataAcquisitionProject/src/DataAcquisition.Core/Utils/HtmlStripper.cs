using System.Text.RegularExpressions;

namespace DataAcquisition.Core.Utils
{
	public static class HtmlStripper
	{
		public static string StripHtml(string html)
		{
			if (string.IsNullOrEmpty(html))
				return string.Empty;

			var htmlTagPattern = new Regex("<.*?>");
			var plainText = htmlTagPattern.Replace(html, string.Empty);
			plainText = System.Net.WebUtility.HtmlDecode(plainText);
			plainText = Regex.Replace(plainText, @"\s+", " ").Trim();
            
			return plainText;
		}

		public static string ExtractPhoneNumber(string html)
		{
			if (string.IsNullOrEmpty(html))
				return string.Empty;

			var phonePattern = new Regex(@"<a\s+href\s*=\s*[""']tel:(\d+)[""'][^>]*>(\d+)</a>");
			var match = phonePattern.Match(html);
            
			if (match.Success && match.Groups.Count >= 3)
			{
				return match.Groups[2].Value;
			}
            
			return StripHtml(html);
		}
	}
}