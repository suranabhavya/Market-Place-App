import 'package:marketplace_app/src/properties/models/property_detail_model.dart';

class PropertyEditModel {
  final String listingType;
  final String title;
  final String description;
  final String address;
  final String? unit;
  final double? latitude;
  final double? longitude;
  final String? pincode;
  final String? city;
  final String? state;
  final String? country;
  final double rent;
  final String rentFrequency;
  final String propertyType;
  final bool furnished;
  final int? bedrooms;
  final int? bathrooms;
  final int? squareFootage;
  final List<PropertyImage>? images;
  final List<String>? deletedImages;
  final SubleaseDetails subleaseDetails;
  final bool isActive;
  final List<String>? amenities;
  final bool hideAddress;
  final Lifestyle? lifestyle;
  final Preference? preference;

  PropertyEditModel({
    required this.listingType,
    required this.title,
    required this.description,
    required this.address,
    this.unit,
    this.latitude,
    this.longitude,
    this.pincode,
    this.city,
    this.state,
    this.country,
    required this.rent,
    required this.rentFrequency,
    required this.propertyType,
    required this.furnished,
    this.bedrooms,
    this.bathrooms,
    this.squareFootage,
    this.images,
    this.deletedImages,
    required this.subleaseDetails,
    required this.isActive,
    this.amenities,
    required this.hideAddress,
    this.lifestyle,
    this.preference,
  });

  factory PropertyEditModel.fromJson(Map<String, dynamic> json) => PropertyEditModel(
        listingType: json["listing_type"],
        title: json["title"],
        description: json["description"],
        address: json["address"],
        unit: json["unit"] ?? "",
        latitude: json["latitude"]?.toDouble() ?? 0.0,
        longitude: json["longitude"]?.toDouble() ?? 0.0,
        pincode: json["pincode"] ?? "",
        city: json["city"] ?? "",
        state: json["state"] ?? "",
        country: json["country"] ?? "",
        rent: json["rent"]?.toDouble() ?? 0.0,
        rentFrequency: json["rent_frequency"] ?? "",
        propertyType: json["property_type"] ?? "",
        furnished: json["furnished"] ?? false,
        bedrooms: json["bedrooms"],
        bathrooms: json["bathrooms"],
        squareFootage: json["square_footage"],
        images: json["images"] != null
            ? List<PropertyImage>.from(json["images"].map((x) => x is PropertyImage ? x : PropertyImage.fromJson(x)))
            : [],
        deletedImages: json["deleted_images"]?.cast<String>(),
        subleaseDetails: json["sublease_details"] != null
            ? SubleaseDetails.fromJson(json["sublease_details"])
            : SubleaseDetails(
                availableFrom: DateTime.now(),
                availableTo: DateTime.now(),
                schoolsNearby: [],
                sharedRoom: false,
              ),
        isActive: json["is_active"] ?? false,
        amenities: json["amenities"] != null
            ? List<String>.from(json["amenities"].map((x) => x.toString()))
            : [],
        hideAddress: json["hide_address"] ?? false,
        lifestyle: json["lifestyle"] != null
            ? Lifestyle.fromJson(json["lifestyle"])
            : null,
        preference: json["preference"] != null
            ? Preference.fromJson(json["preference"])
            : null,
      );

  Map<String, dynamic> toJson() => {
        "listing_type": listingType,
        "title": title,
        "description": description,
        "address": address,
        "unit": unit,
        "latitude": latitude,
        "longitude": longitude,
        "pincode": pincode,
        "city": city,
        "state": state,
        "country": country,
        "rent": rent,
        "rent_frequency": rentFrequency,
        "property_type": propertyType,
        "furnished": furnished,
        "bedrooms": bedrooms,
        "bathrooms": bathrooms,
        "square_footage": squareFootage,
        "images": images?.map((x) => x.toJson()).toList(),
        if (deletedImages != null) "deleted_images": deletedImages,
        "sublease_details": subleaseDetails.toJson(),
        "is_active": isActive,
        "amenities": amenities,
        "hide_address": hideAddress,
        if (lifestyle != null) "lifestyle": lifestyle!.toJson(),
        if (preference != null) "preference": preference!.toJson(),
      };
} 