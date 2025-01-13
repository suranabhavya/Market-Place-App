import 'dart:convert';

List<PropertyListModel> propertyListModelFromJson(String str) => List<PropertyListModel>.from(json.decode(str).map((x) => PropertyListModel.fromJson(x)));

String propertyListModelToJson(List<PropertyListModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class PropertyListModel {
    String id;
    String title;
    double rent;
    String rentFrequency;
    int bedrooms;
    int bathrooms;
    String address;
    double latitude;
    double longitude;
    List<dynamic> images;
    DateTime createdAt;
    DateTime updatedAt;
    bool isActive;

    PropertyListModel({
        required this.id,
        required this.title,
        required this.rent,
        required this.rentFrequency,
        required this.bedrooms,
        required this.bathrooms,
        required this.address,
        required this.latitude,
        required this.longitude,
        required this.images,
        required this.createdAt,
        required this.updatedAt,
        required this.isActive,
    });

    factory PropertyListModel.fromJson(Map<String, dynamic> json) => PropertyListModel(
        id: json["id"],
        title: json["title"],
        rent: json["rent"]?.toDouble(),
        rentFrequency: json["rent_frequency"],
        bedrooms: json["bedrooms"],
        bathrooms: json["bathrooms"],
        address: json["address"],
        latitude: json["latitude"]?.toDouble(),
        longitude: json["longitude"]?.toDouble(),
        images: List<dynamic>.from(json["images"].map((x) => x)),
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        isActive: json["is_active"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "rent": rent,
        "rent_frequency": rentFrequency,
        "bedrooms": bedrooms,
        "bathrooms": bathrooms,
        "address": address,
        "latitude": latitude,
        "longitude": longitude,
        "images": List<dynamic>.from(images.map((x) => x)),
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "is_active": isActive,
    };
}