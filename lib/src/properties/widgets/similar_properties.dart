// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:marketplace_app/common/services/storage.dart';
// import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
// import 'package:marketplace_app/const/constants.dart';
// import 'package:marketplace_app/src/properties/widgets/staggered_tile_widget.dart';

// class SimilarProperties extends StatelessWidget {
//   const SimilarProperties({super.key});

//   @override
//   Widget build(BuildContext context) {
//     String? accessToken = Storage().getString('accessToken');

//     return Column(
//       children: List.generate(
//         properties.length,
//         (i) {
//           final property = properties[i];
//           return StaggeredTileWidget(
//             onTap: () {
//               if (accessToken == null) {
//                 loginBottomSheet(context);
//               } else {
//                 // TODO: Handle Wishlist Functionality
//               }
//             },
//             property: property,
//             i: i,
//           );
//         },
//       ),
//     );
//   }
  
//   // @override
//   // Widget build(BuildContext context) {
//   //   String? accessToken = Storage().getString('accessToken');

//   //   return Padding(
//   //     padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
//   //     child: SizedBox(
//   //       height: MediaQuery.of(context).size.height,
//   //       child: ListView.builder(
//   //         itemCount: properties.length,
//   //         itemBuilder: (context, i) {
//   //           final property = properties[i];
//   //           return StaggeredTileWidget(
//   //             onTap: () {
//   //               if (accessToken == null) {
//   //                 loginBottomSheet(context);
//   //               } else {
//   //                 context.read<WishlistNotifier>().addRemoveWishlist(
                        //   property.id,
                        //   () {}
                        // );
//   //               }
//   //             },
//   //             property: property,
//   //             i: i,
//   //           );
//   //         },
//   //       ),
//   //     ),
//   //   );
//   // }
// }