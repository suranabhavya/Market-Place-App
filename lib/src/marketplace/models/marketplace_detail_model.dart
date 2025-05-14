import 'dart:convert';
import 'package:marketplace_app/src/marketplace/models/marketplace_list_model.dart';

MarketplaceDetailModel marketplaceDetailModelFromJson(String str) =>
    MarketplaceDetailModel.fromJson(json.decode(str));

String marketplaceDetailModelToJson(MarketplaceDetailModel data) =>
    json.encode(data.toJson());

class MarketplaceDetailModel {
  String id;
  Map<String, dynamic> seller;
  String? propertyId;
  String title;
  String description;
  double price;
  double originalPrice;
  String itemType;
  String itemSubtype;
  String condition;
  bool negotiable;
  bool deliveryAvailable;
  String address;
  String? unit;
  String? pincode;
  String? city;
  String? state;
  String? country;
  double? latitude;
  double? longitude;
  bool hideAddress;
  DateTime? availabilityDate;
  bool originalReceiptAvailable;
  DateTime createdAt;
  DateTime updatedAt;
  bool isActive;
  bool isSold;
  DateTime? soldAt;
  List<MarketplaceImage> images;

  MarketplaceDetailModel({
    required this.id,
    required this.seller,
    this.propertyId,
    required this.title,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.itemType,
    required this.itemSubtype,
    required this.condition,
    required this.negotiable,
    required this.deliveryAvailable,
    required this.address,
    this.unit,
    this.pincode,
    this.city,
    this.state,
    this.country,
    this.latitude,
    this.longitude,
    required this.hideAddress,
    this.availabilityDate,
    required this.originalReceiptAvailable,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.isSold,
    this.soldAt,
    required this.images,
  });

  factory MarketplaceDetailModel.fromJson(Map<String, dynamic> json) =>
      MarketplaceDetailModel(
        id: json["id"],
        seller: json["seller"],
        propertyId: json["property_id"],
        title: json["title"],
        description: json["description"],
        price: double.parse(json["price"]),
        originalPrice: double.parse(json["original_price"]),
        itemType: json["item_type"],
        itemSubtype: json["item_subtype"],
        condition: json["condition"],
        negotiable: json["negotiable"],
        deliveryAvailable: json["delivery_available"],
        address: json["address"],
        unit: json["unit"],
        pincode: json["pincode"],
        city: json["city"],
        state: json["state"],
        country: json["country"],
        latitude: json["latitude"]?.toDouble(),
        longitude: json["longitude"]?.toDouble(),
        hideAddress: json["hide_address"],
        availabilityDate: json["availability_date"] != null
            ? DateTime.parse(json["availability_date"])
            : null,
        originalReceiptAvailable: json["original_receipt_available"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        isActive: json["is_active"],
        isSold: json["is_sold"],
        soldAt: json["sold_at"] != null ? DateTime.parse(json["sold_at"]) : null,
        images: json["images"] != null
            ? List<MarketplaceImage>.from(
                json["images"].map((x) => MarketplaceImage.fromJson(x)))
            : [],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "seller": seller,
        "property_id": propertyId,
        "title": title,
        "description": description,
        "price": price.toString(),
        "original_price": originalPrice.toString(),
        "item_type": itemType,
        "item_subtype": itemSubtype,
        "condition": condition,
        "negotiable": negotiable,
        "delivery_available": deliveryAvailable,
        "address": address,
        "unit": unit,
        "pincode": pincode,
        "city": city,
        "state": state,
        "country": country,
        "latitude": latitude,
        "longitude": longitude,
        "hide_address": hideAddress,
        "availability_date": availabilityDate?.toIso8601String(),
        "original_receipt_available": originalReceiptAvailable,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "is_active": isActive,
        "is_sold": isSold,
        "sold_at": soldAt?.toIso8601String(),
        "images": List<dynamic>.from(images.map((x) => x.toJson())),
      };
} 