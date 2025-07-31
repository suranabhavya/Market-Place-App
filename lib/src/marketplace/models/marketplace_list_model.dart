import 'dart:convert';
import 'package:flutter/foundation.dart';

// New class to handle paginated response
class PaginatedMarketplaceResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<MarketplaceListModel> results;

  PaginatedMarketplaceResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedMarketplaceResponse.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('PaginatedMarketplaceResponse.fromJson - count: ${json["count"]}');
      debugPrint('PaginatedMarketplaceResponse.fromJson - results length: ${json["results"]?.length ?? 'null'}');
      
      final results = List<MarketplaceListModel>.from(
          json["results"].map((x) => MarketplaceListModel.fromJson(x)));
      
      debugPrint('PaginatedMarketplaceResponse.fromJson - parsed results length: ${results.length}');
      
      return PaginatedMarketplaceResponse(
        count: json["count"],
        next: json["next"],
        previous: json["previous"],
        results: results,
      );
    } catch (e) {
      debugPrint('Error parsing PaginatedMarketplaceResponse: $e');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
        "count": count,
        "next": next,
        "previous": previous,
        "results": List<dynamic>.from(results.map((x) => x.toJson())),
      };
}

// Parse the paginated response from JSON
PaginatedMarketplaceResponse paginatedMarketplaceFromJson(String str) {
  try {
    debugPrint('paginatedMarketplaceFromJson - input string length: ${str.length}');
    final jsonData = json.decode(str);
    debugPrint('paginatedMarketplaceFromJson - decoded JSON type: ${jsonData.runtimeType}');
    return PaginatedMarketplaceResponse.fromJson(jsonData);
  } catch (e) {
    debugPrint('Error in paginatedMarketplaceFromJson: $e');
    debugPrint('Input string: $str');
    rethrow;
  }
}

String paginatedMarketplaceToJson(PaginatedMarketplaceResponse data) =>
    json.encode(data.toJson());

class MarketplaceImage {
  final String id;
  final String image;
  final DateTime uploadedAt;

  MarketplaceImage({
    required this.id,
    required this.image,
    required this.uploadedAt,
  });

  factory MarketplaceImage.fromJson(Map<String, dynamic> json) => MarketplaceImage(
    id: json["id"],
    image: json["image_url"] ?? json["url"] ?? json["image"] ?? '',
    uploadedAt: DateTime.parse(json["uploaded_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "image": image,
    "uploaded_at": uploadedAt.toIso8601String(),
  };
}

class MarketplaceListModel {
  String id;
  String title;
  double price;
  double? originalPrice;
  String itemType;
  String itemSubtype;
  String address;
  String? city;
  String? state;
  String? pincode;
  bool hideAddress;
  DateTime createdAt;
  DateTime updatedAt;
  bool isActive;
  List<MarketplaceImage> images;
  List<Map<String, dynamic>>? schoolsNearby;

  MarketplaceListModel({
    required this.id,
    required this.title,
    required this.price,
    this.originalPrice,
    required this.itemType,
    required this.itemSubtype,
    required this.address,
    this.city,
    this.state,
    this.pincode,
    required this.hideAddress,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.images,
    this.schoolsNearby,
  });

  factory MarketplaceListModel.fromJson(Map<String, dynamic> json) {
    try {
      return MarketplaceListModel(
        id: json["id"],
        title: json["title"],
        price: double.parse(json["price"]),
        originalPrice: json["original_price"] != null ? double.parse(json["original_price"]) : null,
        itemType: json["item_type"],
        itemSubtype: json["item_subtype"],
        address: json["address"],
        city: json["city"],
        state: json["state"],
        pincode: json["pincode"],
        hideAddress: json["hide_address"] ?? false,
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        isActive: json["is_active"],
        images: json["images"] != null
            ? List<MarketplaceImage>.from(json["images"].map((x) => MarketplaceImage.fromJson(x)))
            : [],
        schoolsNearby: json["schools_nearby"] != null 
            ? List<Map<String, dynamic>>.from(json["schools_nearby"])
            : null,
      );
    } catch (e) {
      debugPrint('Error parsing MarketplaceListModel: $e');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "price": price.toString(),
    "original_price": originalPrice?.toString(),
    "item_type": itemType,
    "item_subtype": itemSubtype,
    "address": address,
    if (city != null) "city": city,
    if (state != null) "state": state,
    if (pincode != null) "pincode": pincode,
    "hide_address": hideAddress,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "is_active": isActive,
    "images": List<dynamic>.from(images.map((x) => x.toJson())),
    "schools_nearby": schoolsNearby,
  };
} 