import 'dart:convert';

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

  factory PaginatedMarketplaceResponse.fromJson(Map<String, dynamic> json) =>
      PaginatedMarketplaceResponse(
        count: json["count"],
        next: json["next"],
        previous: json["previous"],
        results: List<MarketplaceListModel>.from(
            json["results"].map((x) => MarketplaceListModel.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "count": count,
        "next": next,
        "previous": previous,
        "results": List<dynamic>.from(results.map((x) => x.toJson())),
      };
}

// Parse the paginated response from JSON
PaginatedMarketplaceResponse paginatedMarketplaceFromJson(String str) =>
    PaginatedMarketplaceResponse.fromJson(json.decode(str));

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
    image: json["image"],
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
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.images,
    this.schoolsNearby,
  });

  factory MarketplaceListModel.fromJson(Map<String, dynamic> json) => MarketplaceListModel(
    id: json["id"],
    title: json["title"],
    price: double.parse(json["price"]),
    originalPrice: json["original_price"] != null ? double.parse(json["original_price"]) : null,
    itemType: json["item_type"],
    itemSubtype: json["item_subtype"],
    address: json["address"],
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

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "price": price.toString(),
    "original_price": originalPrice?.toString(),
    "item_type": itemType,
    "item_subtype": itemSubtype,
    "address": address,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "is_active": isActive,
    "images": List<dynamic>.from(images.map((x) => x.toJson())),
    "schools_nearby": schoolsNearby,
  };
} 