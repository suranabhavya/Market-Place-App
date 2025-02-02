import 'dart:convert';

import 'package:marketplace_app/src/properties/models/property_list_model.dart';

PropertyDetailModel propertyDetailModelFromJson(String str) => PropertyDetailModel.fromJson(json.decode(str));

String propertyDetailModelToJson(PropertyDetailModel data) => json.encode(data.toJson());

class PropertyDetailModel {
    String id;
    int user;
    String username;
    String listingType;
    String title;
    String description;
    String address;
    double latitude;
    double longitude;
    String pincode;
    String city;
    String state;
    String country;
    double rent;
    String rentFrequency;
    String propertyType;
    bool furnished;
    int bedrooms;
    int bathrooms;
    int squareFootage;
    List<dynamic> images;
    DateTime createdAt;
    DateTime updatedAt;
    SubleaseDetails subleaseDetails;
    bool isActive;
    List<dynamic> amenities;
    bool hideAddress;
    Lifestyle? lifestyle;
    Preference? preference;
    List<PropertyListModel>? userProperties;

    PropertyDetailModel({
        required this.id,
        required this.user,
        required this.username,
        required this.listingType,
        required this.title,
        required this.description,
        required this.address,
        required this.latitude,
        required this.longitude,
        required this.pincode,
        required this.city,
        required this.state,
        required this.country,
        required this.rent,
        required this.rentFrequency,
        required this.propertyType,
        required this.furnished,
        required this.bedrooms,
        required this.bathrooms,
        required this.squareFootage,
        required this.images,
        required this.createdAt,
        required this.updatedAt,
        required this.subleaseDetails,
        required this.isActive,
        required this.amenities,
        required this.hideAddress,
        this.lifestyle,
        this.preference,
        this.userProperties,
    });

    factory PropertyDetailModel.fromJson(Map<String, dynamic> json) => PropertyDetailModel(
        id: json["id"],
        user: json["user"],
        username: json["username"],
        listingType: json["listing_type"],
        title: json["title"],
        description: json["description"],
        address: json["address"],
        latitude: json["latitude"]?.toDouble(),
        longitude: json["longitude"]?.toDouble(),
        pincode: json["pincode"],
        city: json["city"],
        state: json["state"],
        country: json["country"],
        rent:json["rent"]?.toDouble(),
        rentFrequency: json["rent_frequency"],
        propertyType: json["property_type"],
        furnished: json["furnished"],
        bedrooms: json["bedrooms"],
        bathrooms: json["bathrooms"],
        squareFootage: json["square_footage"],
        images: List<dynamic>.from(json["images"].map((x) => x)),
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        subleaseDetails: SubleaseDetails.fromJson(json["sublease_details"]),
        isActive: json["is_active"],
        amenities: List<dynamic>.from(json["amenities"].map((x) => x)),
        hideAddress: json["hide_address"] ?? false,
        lifestyle: json["lifestyle"] != null ? Lifestyle.fromJson(json["lifestyle"]) : null,
        preference: json["preference"] != null ? Preference.fromJson(json["preference"]) : null,
        userProperties: json["user_properties"] == null ? [] : List<PropertyListModel>.from(json["user_properties"]!.map((x) => PropertyListModel.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "user": user,
        "username": username,
        "listing_type": listingType,
        "title": title,
        "description": description,
        "address": address,
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
        "images": List<dynamic>.from(images.map((x) => x)),
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "sublease_details": subleaseDetails.toJson(),
        "is_active": isActive,
        "amenities": List<dynamic>.from(amenities.map((x) => x)),
        "hide_address": hideAddress,
        if (lifestyle != null) "lifestyle": lifestyle!.toJson(),
        if (preference != null) "preferences": preference!.toJson(),
        "user_properties": userProperties == null ? [] : List<dynamic>.from(userProperties!.map((x) => x.toJson())),
    };
}


class SubleaseDetails {
    DateTime availableFrom;
    DateTime availableTo;
    List<String> schoolsNearby;
    bool sharedRoom;

    SubleaseDetails({
        required this.availableFrom,
        required this.availableTo,
        required this.schoolsNearby,
        required this.sharedRoom,
    });

    factory SubleaseDetails.fromJson(Map<String, dynamic> json) => SubleaseDetails(
        availableFrom: DateTime.parse(json["available_from"]),
        availableTo: DateTime.parse(json["available_to"]),
        schoolsNearby: List<String>.from(json["schools_nearby"].map((x) => x)),
        sharedRoom: json["shared_room"],
    );

    Map<String, dynamic> toJson() => {
        "available_from": "${availableFrom.year.toString().padLeft(4, '0')}-${availableFrom.month.toString().padLeft(2, '0')}-${availableFrom.day.toString().padLeft(2, '0')}",
        "available_to": "${availableTo.year.toString().padLeft(4, '0')}-${availableTo.month.toString().padLeft(2, '0')}-${availableTo.day.toString().padLeft(2, '0')}",
        "schools_nearby": List<dynamic>.from(schoolsNearby.map((x) => x)),
        "shared_room": sharedRoom,
    };
}


class Lifestyle {
  String? smoking;
  String? partying;
  String? dietary;

  Lifestyle({
    this.smoking,
    this.partying,
    this.dietary,
  });

  factory Lifestyle.fromJson(Map<String, dynamic> json) => Lifestyle(
        smoking: json["smoking"],
        partying: json["partying"],
        dietary: json["dietary"],
      );

  Map<String, dynamic> toJson() => {
        if (smoking != null) "smoking": smoking,
        if (partying != null) "partying": partying,
        if (dietary != null) "dietary": dietary,
      };
}


class Preference {
  String? genderPreference;
  String? smokingPreference;
  String? partyingPreference;
  String? dietaryPreference;

  Preference({
    this.genderPreference,
    this.smokingPreference,
    this.partyingPreference,
    this.dietaryPreference,
  });

  factory Preference.fromJson(Map<String, dynamic> json) => Preference(
    genderPreference: json["gender_preference"],
    smokingPreference: json["smoking_preference"],
    partyingPreference: json["partying_preference"],
    dietaryPreference: json["dietary_preference"],
  );

  Map<String, dynamic> toJson() => {
    if (genderPreference != null) "gender_preference": genderPreference,
    if (smokingPreference != null) "smoking_preference": smokingPreference,
    if (partyingPreference != null) "partying_preference": partyingPreference,
    if (dietaryPreference != null) "dietary_preference": dietaryPreference,
  };
}
