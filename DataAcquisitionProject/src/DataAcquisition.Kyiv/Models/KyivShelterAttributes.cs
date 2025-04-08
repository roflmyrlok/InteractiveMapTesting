using System;
using System.Text.Json.Serialization;

namespace DataAcquisition.Kyiv.Models
{
    public class KyivShelterAttributes
    {
        [JsonPropertyName("objectid")]
        public int ObjectId { get; set; }
        
        [JsonPropertyName("district")]
        public string District { get; set; }
        
        [JsonPropertyName("address")]
        public string Address { get; set; }
        
        [JsonPropertyName("coord")]
        public string Coord { get; set; }
        
        [JsonPropertyName("type")]
        public string Type { get; set; }
        
        [JsonPropertyName("kind")]
        public string Kind { get; set; }
        
        [JsonPropertyName("type_building")]
        public string TypeBuilding { get; set; }
        
        [JsonPropertyName("owner")]
        public string Owner { get; set; }
        
        [JsonPropertyName("type_ownership")]
        public string TypeOwnership { get; set; }
        
        [JsonPropertyName("tel")]
        public string Tel { get; set; }
        
        [JsonPropertyName("invalid")]
        public string Invalid { get; set; }
        
        [JsonPropertyName("description")]
        public string Description { get; set; }
        
        [JsonPropertyName("lat")]
        public double Latitude { get; set; }
        
        [JsonPropertyName("long")]
        public double Longitude { get; set; }
        
        [JsonPropertyName("phonenumb")]
        public string PhoneNumber { get; set; }
        
        [JsonPropertyName("rgb")]
        public string Rgb { get; set; }
        
        [JsonPropertyName("globalid")]
        public string GlobalId { get; set; }
        
        [JsonPropertyName("title")]
        public string Title { get; set; }
        
        [JsonPropertyName("link_full")]
        public string LinkFull { get; set; }
        
        [JsonPropertyName("address_old")]
        public string AddressOld { get; set; }
        
        [JsonPropertyName("guid")]
        public string Guid { get; set; }
        
        [JsonPropertyName("actual")]
        public int Actual { get; set; }
        
        [JsonPropertyName("working_time")]
        public string WorkingTime { get; set; }
        
        [JsonPropertyName("created_user")]
        public string CreatedUser { get; set; }
        
        [JsonPropertyName("created_date")]
        public long? CreatedDate { get; set; }
        
        [JsonPropertyName("last_edited_user")]
        public string LastEditedUser { get; set; }
        
        [JsonPropertyName("last_edited_date")]
        public long? LastEditedDate { get; set; }
    }
}