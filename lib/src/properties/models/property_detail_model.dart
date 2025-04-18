import 'dart:convert';

import 'package:marketplace_app/src/properties/models/property_list_model.dart';

PropertyDetailModel propertyDetailModelFromJson(String str) =>
    PropertyDetailModel.fromJson(json.decode(str));

String propertyDetailModelToJson(PropertyDetailModel data) =>
    json.encode(data.toJson());

class PropertyImage {
  final String id;
  final String url;

  PropertyImage({required this.id, required this.url});

  factory PropertyImage.fromJson(Map<String, dynamic> json) => PropertyImage(
    id: json['id'].toString(),
    url: json['url'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
  };
}

class PropertyDetailModel {
  String id;
  int userId;
  String name;
  String? profilePhoto;
  String listingType;
  String title;
  String description;
  String address;
  String? unit;
  double? latitude;
  double? longitude;
  String? pincode;
  String? city;
  String? state;
  String? country;
  double rent;
  String rentFrequency;
  String propertyType;
  bool furnished;
  int? bedrooms;
  int? bathrooms;
  int? squareFootage;
  List<PropertyImage>? images;
  List<String>? deletedImages;
  DateTime createdAt;
  DateTime updatedAt;
  SubleaseDetails subleaseDetails;
  bool isActive;
  List<String>? amenities;
  bool hideAddress;
  Lifestyle? lifestyle;
  Preference? preference;
  List<PropertyListModel>? userProperties;

  PropertyDetailModel({
    required this.id,
    required this.userId,
    required this.name,
    this.profilePhoto,
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
    required this.createdAt,
    required this.updatedAt,
    required this.subleaseDetails,
    required this.isActive,
    this.amenities,
    required this.hideAddress,
    this.lifestyle,
    this.preference,
    this.userProperties,
  });

  factory PropertyDetailModel.fromJson(Map<String, dynamic> json) =>
      PropertyDetailModel(
        id: json["id"],
        userId: json["user_id"],
        name: json["name"],
        profilePhoto: json["profile_photo"],
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
            ? List<PropertyImage>.from(json["images"].map((x) => PropertyImage.fromJson(x)))
            : [],
        deletedImages: json["deleted_images"]?.cast<String>(),
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
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
        userProperties: json["user_properties"] == null
            ? []
            : List<PropertyListModel>.from(
                json["user_properties"]!.map(
                    (x) => PropertyListModel.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "name": name,
        "profile_photo": profilePhoto,
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
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "sublease_details": subleaseDetails.toJson(),
        "is_active": isActive,
        "amenities": amenities,
        "hide_address": hideAddress,
        if (lifestyle != null) "lifestyle": lifestyle!.toJson(),
        if (preference != null) "preference": preference!.toJson(),
        "user_properties":
            userProperties?.map((x) => x.toJson()).toList() ?? [],
      };
}

class SubleaseDetails {
  DateTime availableFrom;
  DateTime? availableTo;
  List<String>? schoolIds;
  List<School>? schoolsNearby;
  bool? sharedRoom;

  SubleaseDetails({
    required this.availableFrom,
    this.availableTo,
    this.schoolIds,
    this.schoolsNearby,
    this.sharedRoom,
  });

  factory SubleaseDetails.fromJson(Map<String, dynamic> json) =>
      SubleaseDetails(
        availableFrom: DateTime.parse(json["available_from"]),
        availableTo: json["available_to"] != null ? DateTime.parse(json["available_to"]) : null,
        // Parse schools_nearby as a list of School objects
        schoolsNearby: json["schools_nearby"] != null
            ? List<School>.from(json["schools_nearby"].map((x) => School.fromJson(x)))
            : [],
        // No need to extract school IDs from API response (only for creation)
        schoolIds: null,
        sharedRoom: json["shared_room"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "available_from":
            "${availableFrom.year.toString().padLeft(4, '0')}-${availableFrom.month.toString().padLeft(2, '0')}-${availableFrom.day.toString().padLeft(2, '0')}",
        "available_to": availableTo != null
            ? "${availableTo!.year.toString().padLeft(4, '0')}-${availableTo!.month.toString().padLeft(2, '0')}-${availableTo!.day.toString().padLeft(2, '0')}"
            : null,
        if (schoolIds != null && schoolIds!.isNotEmpty) "school_ids": schoolIds,
        "shared_room": sharedRoom ?? false,
      };

  List<String> getSchoolNames() {
    return schoolsNearby?.map((school) => school.name).toList() ?? [];
  }
}

class Lifestyle {
  String? smoking;
  String? partying;
  String? dietary;
  String? nationality;

  Lifestyle({
    this.smoking,
    this.partying,
    this.dietary,
    this.nationality,
  });

  factory Lifestyle.fromJson(Map<String, dynamic> json) => Lifestyle(
        smoking: json["smoking"],
        partying: json["partying"],
        dietary: json["dietary"],
        nationality: json["nationality"],
      );

  Map<String, dynamic> toJson() => {
        if (smoking != null) "smoking": smoking,
        if (partying != null) "partying": partying,
        if (dietary != null) "dietary": dietary,
        if (nationality != null) "nationality": nationality,
      };
}

class Preference {
  String? genderPreference;
  String? smokingPreference;
  String? partyingPreference;
  String? dietaryPreference;
  String? nationalityPreference;

  Preference({
    this.genderPreference,
    this.smokingPreference,
    this.partyingPreference,
    this.dietaryPreference,
    this.nationalityPreference,
  });

  factory Preference.fromJson(Map<String, dynamic> json) => Preference(
        genderPreference: json["gender_preference"],
        smokingPreference: json["smoking_preference"],
        partyingPreference: json["partying_preference"],
        dietaryPreference: json["dietary_preference"],
        nationalityPreference: json["nationality_preference"],
      );

  Map<String, dynamic> toJson() => {
        if (genderPreference != null) "gender_preference": genderPreference,
        if (smokingPreference != null) "smoking_preference": smokingPreference,
        if (partyingPreference != null) "partying_preference": partyingPreference,
        if (dietaryPreference != null) "dietary_preference": dietaryPreference,
        if (nationalityPreference != null)
          "nationality_preference": nationalityPreference,
      };
}

class School {
  String id;
  String name;

  School({required this.id, required this.name});

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json["id"],
      name: json["name"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}