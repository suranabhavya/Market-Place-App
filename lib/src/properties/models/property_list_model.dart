import 'dart:convert';

// New class to handle paginated response
class PaginatedPropertiesResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<PropertyListModel> results;

  PaginatedPropertiesResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedPropertiesResponse.fromJson(Map<String, dynamic> json) =>
      PaginatedPropertiesResponse(
        count: json["count"],
        next: json["next"],
        previous: json["previous"],
        results: List<PropertyListModel>.from(
            json["results"].map((x) => PropertyListModel.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "count": count,
        "next": next,
        "previous": previous,
        "results": List<dynamic>.from(results.map((x) => x.toJson())),
      };
}

// Parse the paginated response from JSON
PaginatedPropertiesResponse paginatedPropertiesFromJson(String str) =>
    PaginatedPropertiesResponse.fromJson(json.decode(str));

String paginatedPropertiesToJson(PaginatedPropertiesResponse data) =>
    json.encode(data.toJson());

// Maintain the old functions for compatibility with existing code
List<PropertyListModel> propertyListModelFromJson(String str) =>
    List<PropertyListModel>.from(
        json.decode(str).map((x) => PropertyListModel.fromJson(x)));

String propertyListModelToJson(List<PropertyListModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class PropertyListModel {
  String id;
  String title;
  double rent;
  String rentFrequency;
  int? bedrooms;
  int? bathrooms;
  String address;
  String? city;
  String? state;
  String? pincode;
  bool hideAddress;
  double? latitude;
  double? longitude;
  List<String>? images;
  DateTime createdAt;
  DateTime updatedAt;
  bool isActive;

  PropertyListModel({
    required this.id,
    required this.title,
    required this.rent,
    required this.rentFrequency,
    this.bedrooms,
    this.bathrooms,
    required this.address,
    this.city,
    this.state,
    this.pincode,
    required this.hideAddress,
    this.latitude,
    this.longitude,
    this.images,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory PropertyListModel.fromJson(Map<String, dynamic> json) => PropertyListModel(
        id: json["id"],
        title: json["title"],
        rent: json["rent"]?.toDouble() ?? 0.0,
        rentFrequency: json["rent_frequency"],
        bedrooms: json["bedrooms"],
        bathrooms: json["bathrooms"],
        address: json["address"],
        city: json["city"],
        state: json["state"],
        pincode: json["pincode"],
        hideAddress: json["hide_address"] ?? false,
        latitude: json["latitude"]?.toDouble(),
        longitude: json["longitude"]?.toDouble(),
        images: json["images"] != null
            ? List<String>.from(json["images"].map((x) => x.toString()))
            : [],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        isActive: json["is_active"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "rent": rent,
        "rent_frequency": rentFrequency,
        if (bedrooms != null) "bedrooms": bedrooms,
        if (bathrooms != null) "bathrooms": bathrooms,
        "address": address,
        if (city != null) "city": city,
        if (state != null) "state": state,
        if (pincode != null) "pincode": pincode,
        "hide_address": hideAddress,
        if (latitude != null) "latitude": latitude,
        if (longitude != null) "longitude": longitude,
        if (images != null) "images": List<String>.from(images!),
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "is_active": isActive,
      };
}
