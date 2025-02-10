import 'package:flutter/material.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/const/resource.dart';
import 'package:marketplace_app/src/properties/models/property_detail_model.dart';
import 'package:marketplace_app/src/properties/models/property_list_model.dart';

LinearGradient kGradient = const LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Kolors.kPrimaryLight,
    Kolors.kWhite,
    Kolors.kPrimary,
  ],
);

LinearGradient kPGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Kolors.kPrimaryLight,
    Kolors.kPrimaryLight.withOpacity(0.7),
    Kolors.kPrimary,
  ],
);

LinearGradient kBtnGradient = const LinearGradient(
  begin: Alignment.bottomLeft,
  end: Alignment.bottomRight,
  colors: [
    Kolors.kPrimaryLight,
    Kolors.kWhite,
  ],
);

BorderRadiusGeometry kClippingRadius = const BorderRadius.only(
  topLeft: Radius.circular(20),
  topRight: Radius.circular(20),
);

BorderRadiusGeometry kRadiusAll = BorderRadius.circular(12);

BorderRadiusGeometry kRadiusTop = const BorderRadius.only(
  topLeft: Radius.circular(9),
  topRight: Radius.circular(9),
);

BorderRadiusGeometry kRadiusBottom = const BorderRadius.only(
  bottomLeft: Radius.circular(12),
  bottomRight: Radius.circular(12),
);

Widget Function(BuildContext, String)? placeholder = (p0, p1) => Image.asset(
      R.ASSETS_IMAGES_PLACEHOLDER_WEBP,
      fit: BoxFit.cover,
    );

Widget Function(BuildContext, String, Object)? errorWidget =
    (p0, p1, p3) => Image.asset(
          R.ASSETS_IMAGES_PLACEHOLDER_WEBP,
          fit: BoxFit.cover,
        );

List<String> images = [
  "https://firebasestorage.googleapis.com/v0/b/authenification-b4dc9.appspot.com/o/uploads%2Fslider1.png?alt=media&token=8b27e621-e5ea-4ba4-ab15-0302d02c75f3",
  "https://firebasestorage.googleapis.com/v0/b/authenification-b4dc9.appspot.com/o/uploads%2Fslider1.png?alt=media&token=8b27e621-e5ea-4ba4-ab15-0302d02c75f3",
  "https://firebasestorage.googleapis.com/v0/b/authenification-b4dc9.appspot.com/o/uploads%2Fslider1.png?alt=media&token=8b27e621-e5ea-4ba4-ab15-0302d02c75f3",
  "https://firebasestorage.googleapis.com/v0/b/authenification-b4dc9.appspot.com/o/uploads%2Fslider1.png?alt=media&token=8b27e621-e5ea-4ba4-ab15-0302d02c75f3",
  "https://firebasestorage.googleapis.com/v0/b/authenification-b4dc9.appspot.com/o/uploads%2Fslider1.png?alt=media&token=8b27e621-e5ea-4ba4-ab15-0302d02c75f3",
];

// [{"title":"Sneakers","id":3,"imageUrl":"https://firebasestorage.googleapis.com/v0/b/authenification-b4dc9.appspot.com/o/uploads%2Frunning_shoe.svg?alt=media&token=0dcb0e57-315e-457c-89dc-1233f6421368"},{"title":"T-Shirts","id":5,"imageUrl":"https://firebasestorage.googleapis.com/v0/b/authenification-b4dc9.appspot.com/o/uploads%2Fjersey.svg?alt=media&token=6ca7eabd-54b3-47bb-bb8f-41c3a8920171"},{"title":"Jackets","id":4,"imageUrl":"https://firebasestorage.googleapis.com/v0/b/authenification-b4dc9.appspot.com/o/uploads%2Fjacket.svg?alt=media&token=ffdc9a1e-917f-4e8f-b58e-4df2e6e8587e"},{"title":"Dresses","id":2,"imageUrl":"https://firebasestorage.googleapis.com/v0/b/authenification-b4dc9.appspot.com/o/uploads%2Fdress.svg?alt=media&token=cf832383-4c8a-4ee1-9676-b66c4d515a1c"},{"title":"Pants","id":1,"imageUrl":"https://firebasestorage.googleapis.com/v0/b/authenification-b4dc9.appspot.com/o/uploads%2Fjeans.svg?alt=media&token=eb62f916-a4c2-441a-a469-5684f1a62526"}]

// List<Categories> categories = [
//   Categories(
//       title: "Pants",
//       id: 1,
//       imageUrl:
//           "https://firebasestorage.googleapis.com/v0/b/authenification-b4dc9.appspot.com/o/uploads%2Fjeans.svg?alt=media&token=eb62f916-a4c2-441a-a469-5684f1a62526"),
//   Categories(
//       title: "T-Shirts",
//       id: 5,
//       imageUrl:
//           "https://firebasestorage.googleapis.com/v0/b/authenification-b4dc9.appspot.com/o/uploads%2Fjersey.svg?alt=media&token=6ca7eabd-54b3-47bb-bb8f-41c3a8920171"),
//   Categories(
//       title: "Sneakers",
//       id: 3,
//       imageUrl:
//           "https://firebasestorage.googleapis.com/v0/b/authenification-b4dc9.appspot.com/o/uploads%2Frunning_shoe.svg?alt=media&token=0dcb0e57-315e-457c-89dc-1233f6421368"),
//   Categories(
//       title: "Dresses",
//       id: 2,
//       imageUrl:
//           "https://firebasestorage.googleapis.com/v0/b/authenification-b4dc9.appspot.com/o/uploads%2Fdress.svg?alt=media&token=cf832383-4c8a-4ee1-9676-b66c4d515a1c"),
//   Categories(
//       title: "Jackets",
//       id: 4,
//       imageUrl:
//           "https://firebasestorage.googleapis.com/v0/b/authenification-b4dc9.appspot.com/o/uploads%2Fjacket.svg?alt=media&token=ffdc9a1e-917f-4e8f-b58e-4df2e6e8587e")
// ];

// var products = [
//   {
//     "id": 3,
//     "title": "Converse Chuck Taylor All Star",
//     "price": 60.0,
//     "description":
//         "The classic Chuck Taylor All Star sneaker from Converse, featuring a timeless design and comfortable fit.",
//     "is_featured": true,
//     "clothesType": "kids",
//     "ratings": 4.333333333333333,
//     "colors": ["black", "white", "red"],
//     "imageUrls": [
//       "https://media.cnn.com/api/v1/images/stellar/prod/220210051008-04-lv-virgil-abloh.jpg?q=w_2000,c_fill/f_webp",
//       "https://media.cnn.com/api/v1/images/stellar/prod/220210051008-04-lv-virgil-abloh.jpg?q=w_2000,c_fill/f_webp"
//     ],
//     "sizes": ["7", "8", "9", "10", "11"],
//     "created_at": "2024-06-06T07:57:45Z",
//     "category": 3,
//     "brand": 1
//   },
//   {
//     "id": 1,
//     "title": "LV Trainers",
//     "price": 798.88,
//     "description":
//         "LV Trainers blend sleek style with athletic functionality, featuring bold logos, premium materials, and comfortable designs that elevate your everyday look with a touch of luxury.",
//     "is_featured": true,
//     "clothesType": "women",
//     "ratings": 4.5,
//     "colors": ["white", "black", "red"],
//     "imageUrls": [
//       "https://media.cnn.com/api/v1/images/stellar/prod/220210051008-04-lv-virgil-abloh.jpg?q=w_2000,c_fill/f_webp",
//       "https://media.cnn.com/api/v1/images/stellar/prod/220210051008-04-lv-virgil-abloh.jpg?q=w_2000,c_fill/f_webp"
//     ],
//     "sizes": ["7", "8", "9", "10", "11"],
//     "created_at": "2024-06-06T07:49:15Z",
//     "category": 3,
//     "brand": 1
//   },
//   {
//     "id": 2,
//     "title": "Adidas Ultraboost",
//     "price": 180.0,
//     "description":
//         "xperience the comfort and energy return of the Ultraboost, designed for running and everyday wear.",
//     "is_featured": true,
//     "clothesType": "unisex",
//     "ratings": 5.0,
//     "colors": ["navy", "grey", "blue"],
//     "imageUrls": [
//       "https://media.cnn.com/api/v1/images/stellar/prod/220210051008-04-lv-virgil-abloh.jpg?q=w_2000,c_fill/f_webp",
//       "https://media.cnn.com/api/v1/images/stellar/prod/220210051008-04-lv-virgil-abloh.jpg?q=w_2000,c_fill/f_webp"
//     ],
//     "sizes": ["7", "8", "9", "10", "11"],
//     "created_at": "2024-06-06T07:55:20Z",
//     "category": 3,
//     "brand": 1
//   }
// ];

List<PropertyListModel> properties = [
  PropertyListModel(
    id: "1",
    title: "Cozy Studio Apartment",
    address: "123 Main Street, City Center",
    latitude: 40.7128,
    longitude: -74.0060,
    rent: 1500.00,
    rentFrequency: "Monthly",
    bedrooms: 1,
    bathrooms: 1,
    images: [
      "https://imageio.forbes.com/specials-images/imageserve/64525acf1d511e01e8ee1aee/Airbnb-Rooms/1960x0.jpg?height=474&width=711&fit=bounds",
      "https://a0.muscache.com/im/pictures/b59084da-fa5e-49b7-bb22-5534654377ca.jpg"
    ],
    createdAt: DateTime.parse("2024-01-01T10:00:00Z"),
    updatedAt: DateTime.parse("2024-01-10T12:00:00Z"),
    isActive: true,
  ),
  PropertyListModel(
    id: "2",
    title: "Spacious 2BHK Apartment",
    address: "456 Elm Street, Uptown",
    latitude: 37.7749,
    longitude: -122.4194,
    rent: 2200.00,
    rentFrequency: "Monthly",
    bedrooms: 2,
    bathrooms: 2,
    images: [
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQopNAigGHDCSfu_pIf1k3_iguagCjspB-hQB6QTFIx3p-szIlJCiN8n0Qh4zG2SvzSQfo&usqp=CAU",
      "https://a0.muscache.com/im/pictures/be8420b1-ba98-440a-a83f-acfaffa3ca81.jpg"
    ],
    createdAt: DateTime.parse("2024-02-01T09:00:00Z"),
    updatedAt: DateTime.parse("2024-02-05T18:00:00Z"),
    isActive: true,
  ),
  PropertyListModel(
    id: "3",
    title: "Luxury Penthouse",
    address: "789 Park Avenue, Downtown",
    latitude: 34.0522,
    longitude: -118.2437,
    rent: 5000.00,
    rentFrequency: "Monthly",
    bedrooms: 3,
    bathrooms: 3,
    images: [
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQofYq41udw-qlDe47B8J3Oo_JxwC2XKPKSDfC1P8zFrfqEK1Pg2ckvWff2mdCsOrPplsI&usqp=CAU",
      "https://images.unsplash.com/photo-1647996179012-66b87eba3d17?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTF8fHJvb20lMjBmb3IlMjByZW50fGVufDB8fDB8fHww"
    ],
    createdAt: DateTime.parse("2024-03-01T14:00:00Z"),
    updatedAt: DateTime.parse("2024-03-03T16:00:00Z"),
    isActive: true,
  ),
  PropertyListModel(
    id: "4",
    title: "Shared Room in Downtown",
    address: "321 Broadway, Downtown",
    latitude: 42.3601,
    longitude: -71.0589,
    rent: 600.00,
    rentFrequency: "Monthly",
    bedrooms: 1,
    bathrooms: 1,
    images: ["https://images.unsplash.com/photo-1560185009-5bf9f2849488?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"],
    createdAt: DateTime.parse("2024-04-01T08:00:00Z"),
    updatedAt: DateTime.parse("2024-04-05T12:00:00Z"),
    isActive: true,
  ),
  PropertyListModel(
    id: "5",
    title: "Family Home with Garden",
    address: "789 Maple Lane, Suburbs",
    latitude: 47.6062,
    longitude: -122.3321,
    rent: 2500.00,
    rentFrequency: "Monthly",
    bedrooms: 4,
    bathrooms: 3,
    images: [
      "https://media.istockphoto.com/id/2104606940/photo/interior-photographs-of-a-luxurious-residential-home-den-study-dining-room-kitchen-living.jpg?b=1&s=612x612&w=0&k=20&c=hp4NDX8Nc2K96E67z5vFX3VwzlxPUFIqYTNP5V6GLTM=",
      "https://media.istockphoto.com/id/1456467041/photo/beautiful-kitchen-in-new-farmhouse-style-luxury-home-with-island-pendant-lights-and-hardwood.jpg?s=612x612&w=0&k=20&c=wwlKjbAsf_xBveRuqMV2fCJ8cpED0CoXE4GdIUSxpW8="
    ],
    createdAt: DateTime.parse("2024-05-01T11:00:00Z"),
    updatedAt: DateTime.parse("2024-05-03T13:00:00Z"),
    isActive: true,
  ),
];

String avatar =
    'https://firebasestorage.googleapis.com/v0/b/authenification-b4dc9.appspot.com/o/uploads%2Favatar.png?alt=media&token=7da81de9-a163-4296-86ac-3194c490ce15';


// class _buildtextfield extends StatelessWidget {
//   const _buildtextfield({
//     Key? key,
//     required this.hintText,
//     required this.controller,
//     required this.onSubmitted,
//     this.keyboard,
//     this.readOnly,
//   }) : super(key: key);

//   final TextEditingController controller;
//   final String hintText;
//   final TextInputType? keyboard;
//   final void Function(String)? onSubmitted;
//   final bool? readOnly;
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 20.0),
//       child: TextField(
//           keyboardType: keyboard,
//           readOnly: readOnly ?? false,
//           decoration: InputDecoration(
//               hintText: hintText,
//               errorBorder: const UnderlineInputBorder(
//                 borderSide: BorderSide(color: Kolors.kRed, width: 0.5),
//               ),
//               focusedBorder: const UnderlineInputBorder(
//                 borderSide: BorderSide(color: Kolors.kPrimary, width: 0.5),
//               ),
//               focusedErrorBorder: const UnderlineInputBorder(
//                 borderSide: BorderSide(color: Kolors.kRed, width: 0.5),
//               ),
//               disabledBorder: const UnderlineInputBorder(
//                 borderSide: BorderSide(color: Kolors.kGray, width: 0.5),
//               ),
//               enabledBorder: const UnderlineInputBorder(
//                 borderSide: BorderSide(color: Kolors.kGray, width: 0.5),
//               ),
//               border: InputBorder.none),
//           controller: controller,
//           cursorHeight: 25,
//           style: appStyle(12, Colors.black, FontWeight.normal),
//           onSubmitted: onSubmitted),
//     );
//   }
// }


const List<String> schoolOptions = [
  'Boston University',
  'Harvard University',
  'Massachusetts Institute of Technology',
  'Northeastern University'
];
