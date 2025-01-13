// import 'dart:convert';

// List<Properties> propertiesFromJson(String str) => List<Properties>.from(json.decode(str).map((x) => Properties.fromJson(x)));

// String propertiesToJson(List<Properties> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

// class Properties {
//   final String id;
//   final String listingType; // Enum: 'rent', 'sublease'
//   final String title;
//   final String description;
//   final String address;
//   final double latitude;
//   final double longitude;
//   final double rent; // Decimal
//   final String rentFrequency; // Enum: 'Daily', 'Monthly'
//   final String propertyType; // Enum: 'apartment', 'studio'
//   final bool furnished;
//   final int bedrooms;
//   final int bathrooms;
//   final int squareFootage;
//   final List<String> images; // JSON Array of URLs
//   final DateTime createdAt;
//   final DateTime updatedAt;
//   final bool isActive;

//   Properties({
//     required this.id,
//     required this.listingType,
//     required this.title,
//     required this.description,
//     required this.address,
//     required this.latitude,
//     required this.longitude,
//     required this.rent,
//     required this.rentFrequency,
//     required this.propertyType,
//     required this.furnished,
//     required this.bedrooms,
//     required this.bathrooms,
//     required this.squareFootage,
//     required this.images,
//     required this.createdAt,
//     required this.updatedAt,
//     required this.isActive,
//   });

//   // Factory method to create a Property object from JSON
//   factory Properties.fromJson(Map<String, dynamic> json) {
//     print("json: $json");
//     return Properties(
//       id: json['id'],
//       listingType: json['listing_type'],
//       title: json['title'],
//       description: json['description'],
//       address: json['address'],
//       latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
//       longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
//       rent: double.tryParse(json['rent'].toString()) ?? 0.0,
//       rentFrequency: json['rent_frequency'],
//       propertyType: json['property_type'],
//       furnished: json['furnished'],
//       bedrooms: json['bedrooms'],
//       bathrooms: json['bathrooms'],
//       squareFootage: json['square_footage'],
//       images: List<String>.from(json["images"].map((x) => x)),
//       createdAt: DateTime.parse(json['created_at']),
//       updatedAt: DateTime.parse(json['updated_at']),
//       isActive: json['is_active'],
//     );
//   }

//   // Method to convert a Property object to JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'listing_type': listingType,
//       'title': title,
//       'description': description,
//       'address': address,
//       'latitude': latitude,
//       'longitude': longitude,
//       'rent': rent,
//       'rent_frequency': rentFrequency,
//       'property_type': propertyType,
//       'furnished': furnished,
//       'bedrooms': bedrooms,
//       'bathrooms': bathrooms,
//       'square_footage': squareFootage,
//       'images': List<dynamic>.from(images.map((x) => x)),
//       'created_at': createdAt.toIso8601String(),
//       'updated_at': updatedAt.toIso8601String(),
//       'is_active': isActive,
//     };
//   }
// }

// // void main() {
// //   // Example JSON
// //   String jsonString = '''
//   // {
//   //   "id": "1",
//   //   "user_id": "user123",
//   //   "listing_type": "rent",
//   //   "title": "2BHK in Boston",
//   //   "description": "A spacious 2BHK apartment in the heart of Boston.",
//   //   "address": "123 Main St, Boston, MA",
//   //   "latitude": 42.3601,
//   //   "longitude": -71.0589,
//   //   "rent": 1200.50,
//   //   "rent_frequency": "Monthly",
//   //   "property_type": "apartment",
//   //   "furnished": true,
//   //   "bedrooms": 2,
//   //   "bathrooms": 2,
//   //   "square_footage": 1000,
//   //   "images": ["url1", "url2"],
//   //   "created_at": "2024-01-01T12:00:00Z",
//   //   "updated_at": "2024-01-02T12:00:00Z",
//   //   "is_active": true
//   // }
// //   ''';

// //   // Parsing JSON to Property object
// //   Property property = Property.fromJson(jsonDecode(jsonString));
// //   print('Property Title: ${property.title}');

// //   // Converting Property object to JSON
// //   print('Property as JSON: ${jsonEncode(property.toJson())}');
// // }



import 'dart:convert';

import 'package:marketplace_app/src/properties/models/property_list_model.dart';

PropertyDetailModel propertyDetailModelFromJson(String str) => PropertyDetailModel.fromJson(json.decode(str));

String propertyDetailModelToJson(PropertyDetailModel data) => json.encode(data.toJson());

class PropertyDetailModel {
    String id;
    int user;
    String? username;
    String listingType;
    String title;
    String description;
    String address;
    double latitude;
    double longitude;
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
    bool isActive;
    List<PropertyListModel>? userProperties;

    PropertyDetailModel({
        required this.id,
        required this.user,
        this.username,
        required this.listingType,
        required this.title,
        required this.description,
        required this.address,
        required this.latitude,
        required this.longitude,
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
        required this.isActive,
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
        isActive: json["is_active"],
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
        "is_active": isActive,
        "user_properties": userProperties == null ? [] : List<dynamic>.from(userProperties!.map((x) => x.toJson())),
    };
}