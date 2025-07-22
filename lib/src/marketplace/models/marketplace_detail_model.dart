import 'dart:convert';

MarketplaceDetailModel marketplaceDetailModelFromJson(String str) =>
    MarketplaceDetailModel.fromJson(json.decode(str));

String marketplaceDetailModelToJson(MarketplaceDetailModel data) =>
    json.encode(data.toJson());

class MarketplaceDetailModel {
  final String id;
  final SellerModel seller;
  final PropertyModel? property;
  final String title;
  final String? description;
  final double price;
  final double? originalPrice;
  final String itemType;
  final String itemSubtype;
  final String condition;
  final bool negotiable;
  final bool deliveryAvailable;
  final String address;
  final String? unit;
  final String? pincode;
  final String? city;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;
  final bool hideAddress;
  final DateTime? availabilityDate;
  final bool originalReceiptAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isSold;
  final DateTime? soldAt;
  final List<MarketplaceDetailImage> images;
  final List<SchoolNearby> schoolsNearby;

  MarketplaceDetailModel({
    required this.id,
    required this.seller,
    this.property,
    required this.title,
    this.description,
    required this.price,
    this.originalPrice,
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
    required this.schoolsNearby,
  });

  factory MarketplaceDetailModel.fromJson(Map<String, dynamic> json) => MarketplaceDetailModel(
    id: json["id"],
    seller: SellerModel.fromJson(json["seller"]),
    property: json["property"] != null ? PropertyModel.fromJson(json["property"]) : null,
    title: json["title"],
    description: json["description"],
    price: double.parse(json["price"]),
    originalPrice: json["original_price"] != null ? double.parse(json["original_price"]) : null,
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
    images: List<MarketplaceDetailImage>.from(
        json["images"].map((x) => MarketplaceDetailImage.fromJson(x))),
    schoolsNearby: List<SchoolNearby>.from(
        json["schools_nearby"].map((x) => SchoolNearby.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "seller": seller.toJson(),
    "property": property?.toJson(),
    "title": title,
    "description": description,
    "price": price.toString(),
    "original_price": originalPrice?.toString(),
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
    "schools_nearby": List<dynamic>.from(schoolsNearby.map((x) => x.toJson())),
  };
}

class SellerModel {
  final int id;
  final String name;
  final String email;
  final String? profilePhoto;

  SellerModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhoto,
  });

  factory SellerModel.fromJson(Map<String, dynamic> json) => SellerModel(
    id: json["id"],
    name: json["name"],
    email: json["email"],
    profilePhoto: json["profile_photo"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "profile_photo": profilePhoto,
  };
}

class PropertyModel {
  final String id;
  final String title;

  PropertyModel({
    required this.id,
    required this.title,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) => PropertyModel(
    id: json["id"],
    title: json["title"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
  };
}

class MarketplaceDetailImage {
  final String id;
  final String image;
  final DateTime uploadedAt;

  MarketplaceDetailImage({
    required this.id,
    required this.image,
    required this.uploadedAt,
  });

  factory MarketplaceDetailImage.fromJson(Map<String, dynamic> json) => MarketplaceDetailImage(
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

class SchoolNearby {
  final String id;
  final String name;

  SchoolNearby({
    required this.id,
    required this.name,
  });

  factory SchoolNearby.fromJson(Map<String, dynamic> json) => SchoolNearby(
    id: json["id"],
    name: json["name"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
  };
} 