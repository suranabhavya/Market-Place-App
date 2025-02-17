import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/widgets/empty_screen_widget.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/common/widgets/shimmers/list_shimmer.dart';
import 'package:marketplace_app/src/properties/widgets/staggered_tile_widget.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:marketplace_app/src/wishlist/hooks/fetch_wishlist.dart';
import 'package:provider/provider.dart';

class WishlistWidget extends HookWidget {
  const WishlistWidget({super.key});

  @override
  Widget build(BuildContext context) {
    String? accessToken = Storage().getString('accessToken');
    final results = useFetchWishlist();
    final properties = results.properties;
    final isLoading = results.isLoading;
    final refetch = results.refetch;
    final error = results.error;

    if(isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: const ListShimmer(),
      );
    }

    return properties.isEmpty ? const EmptyScreenWidget() : Column(
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
                  refetch
                );
              }
            },
            property: property,
          );
        },
      ),
    );
  }
}