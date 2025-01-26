import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/const/constants.dart';
import 'package:marketplace_app/src/properties/controllers/property_notifier.dart';
import 'package:marketplace_app/src/properties/widgets/staggered_tile_widget.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:provider/provider.dart';

class ExploreProperties extends StatefulWidget {
  const ExploreProperties({super.key});

  @override
  State<ExploreProperties> createState() => _ExplorePropertiesState();
}

class _ExplorePropertiesState extends State<ExploreProperties> {
  @override
  void initState() {
    super.initState();
    context.read<PropertyNotifier>().fetchProperties();
  }

  Future<void> _loadProperties() async {
    await context.read<PropertyNotifier>().fetchProperties();
  }

  @override
  Widget build(BuildContext context) {
    final propertyNotifier = context.watch<PropertyNotifier>();
    final properties = propertyNotifier.properties;
    String? accessToken = Storage().getString('accessToken');

    if (properties.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(), // Show loading indicator while fetching data
      );
    }

    return Column(
      children: List.generate(
        properties.length,
        (i) {
          final property = properties[i];
          return StaggeredTileWidget(
            onTap: () {
              if (accessToken == null) {
                loginBottomSheet(context);
              } else {
                context.read<WishlistNotifier>().addRemoveWishlist(
                  property.id,
                  () {}
                );
              }
            },
            property: property,
            i: i,
          );
        },
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:flutter_hooks/flutter_hooks.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
// import 'package:marketplace_app/common/services/storage.dart';
// import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
// import 'package:marketplace_app/common/widgets/shimmers/list_shimmer.dart';
// import 'package:marketplace_app/const/constants.dart';
// import 'package:marketplace_app/const/resource.dart';
// import 'package:marketplace_app/src/home/controllers/home_tab_notifier.dart';
// import 'package:marketplace_app/src/properties/controllers/property_notifier.dart';
// import 'package:marketplace_app/src/properties/widgets/staggered_tile_widget.dart';
// import 'package:provider/provider.dart';

// class ExploreProperties extends HookWidget {
//   const ExploreProperties({super.key});

//   @override
//   Widget build(BuildContext context) {
//     String? accessToken = Storage().getString('accessToken');
//     final results = fetchProperties(context.watch<HomeTabNotifier>().queryType);
//     final properties = results.properties;
//     final isLoading = results.isLoading;
//     final error = results.error;

//     if(isLoading) {
//       return Padding(
//         padding: EdgeInsets.symmetric(horizontal: 12.w),
//         child: const ListShimmer(),
//       );
//     }

//     return properties.isEmpty ? Padding(
//       padding: EdgeInsets.all(25.w),
//       child: Image.asset(R.ASSETS_IMAGES_EMPTY_PNG, height: ScreenUtil().screenHeight * .3,),
//     ) : Column(
//       children: List.generate(
//         properties.length,
//         (i) {
//           final property = properties[i];
//           print("rent is: ${property.rent}");
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
// }
