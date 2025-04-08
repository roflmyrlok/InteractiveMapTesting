using System;
using System.Collections.Generic;
using System.Linq;
using DataAcquisition.Core.Interfaces;
using DataAcquisition.Core.Models;
using DataAcquisition.Core.Utils;
using DataAcquisition.Kyiv.Models;

namespace DataAcquisition.Kyiv.Services
{
    public class KyivShelterDataTransformer : IDataTransformer<KyivShelterResponse, Location>
    {
        private readonly string _defaultCity;
        private readonly string _defaultState;
        private readonly string _defaultCountry;

        public KyivShelterDataTransformer(string defaultCity = "Kyiv", 
                                         string defaultState = "Kyiv", 
                                         string defaultCountry = "Ukraine")
        {
            _defaultCity = defaultCity;
            _defaultState = defaultState;
            _defaultCountry = defaultCountry;
        }

        public IEnumerable<Location> Transform(KyivShelterResponse source)
        {
            if (source == null || source.Features == null)
                yield break;

            foreach (var feature in source.Features)
            {
                if (feature?.Attributes == null || feature.Geometry == null)
                    continue;

                var attr = feature.Attributes;
                
                if (attr.Actual != 1)
                    continue;
                
                var location = new Location
                {
                    Id = attr.Guid,
                    Name = string.IsNullOrEmpty(attr.TypeBuilding) ? 
                           attr.Title : 
                           attr.TypeBuilding,
                    
                    Latitude = attr.Latitude != 0 ? attr.Latitude : feature.Geometry.Y,
                    Longitude = attr.Longitude != 0 ? attr.Longitude : feature.Geometry.X,
                    
                    Address = attr.Address,
                    City = _defaultCity,
                    State = _defaultState,
                    Country = _defaultCountry,
                    PostalCode = string.Empty
                };

                var details = new List<LocationDetail>
                {
                    new LocationDetail
                    {
                        Id = Guid.NewGuid().ToString(),
                        PropertyName = "district",
                        PropertyValue = attr.District
                    },
                    new LocationDetail
                    {
                        Id = Guid.NewGuid().ToString(),
                        PropertyName = "type",
                        PropertyValue = attr.Type
                    },
                    new LocationDetail
                    {
                        Id = Guid.NewGuid().ToString(),
                        PropertyName = "kind",
                        PropertyValue = attr.Kind
                    }
                };

                if (!string.IsNullOrEmpty(attr.Owner))
                {
                    details.Add(new LocationDetail
                    {
                        Id = Guid.NewGuid().ToString(),
                        PropertyName = "owner",
                        PropertyValue = attr.Owner
                    });
                }

                if (!string.IsNullOrEmpty(attr.TypeOwnership))
                {
                    details.Add(new LocationDetail
                    {
                        Id = Guid.NewGuid().ToString(),
                        PropertyName = "ownership_type",
                        PropertyValue = attr.TypeOwnership
                    });
                }

                if (!string.IsNullOrEmpty(attr.PhoneNumber))
                {
                    var cleanPhone = HtmlStripper.ExtractPhoneNumber(attr.PhoneNumber);
                    if (!string.IsNullOrEmpty(cleanPhone))
                    {
                        details.Add(new LocationDetail
                        {
                            Id = Guid.NewGuid().ToString(),
                            PropertyName = "phone",
                            PropertyValue = cleanPhone
                        });
                    }
                }

                if (!string.IsNullOrEmpty(attr.Invalid))
                {
                    details.Add(new LocationDetail
                    {
                        Id = Guid.NewGuid().ToString(),
                        PropertyName = "accessibility",
                        PropertyValue = attr.Invalid
                    });
                }

                if (!string.IsNullOrEmpty(attr.WorkingTime))
                {
                    details.Add(new LocationDetail
                    {
                        Id = Guid.NewGuid().ToString(),
                        PropertyName = "working_hours",
                        PropertyValue = attr.WorkingTime
                    });
                }

                if (!string.IsNullOrEmpty(attr.Description) && attr.Description != "-")
                {
                    details.Add(new LocationDetail
                    {
                        Id = Guid.NewGuid().ToString(),
                        PropertyName = "description",
                        PropertyValue = attr.Description
                    });
                }

                location.Details = details;
                yield return location;
            }
        }
    }
}