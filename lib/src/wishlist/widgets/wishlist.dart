import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
    final results = useFetchWishlist();
    final properties = results.properties;
    final isLoading = results.isLoading;
    final refetch = results.refetch;

    if (isLoading) {
      return const ListShimmer();
    }

    return properties.isEmpty
        ? const EmptyScreenWidget()
        : Consumer<WishlistNotifier>(
            builder: (context, wishlistNotifier, child) {
              // Ensure that only properties in the local wishlist are displayed
              final filteredProperties = properties
                  .where((property) => wishlistNotifier.wishlist.contains(property.id))
                  .toList();

              return Column(
                children: List.generate(
                  filteredProperties.length,
                  (i) {
                    final property = filteredProperties[i];
                    return StaggeredTileWidget(
                      onTap: () {
                        final accessToken = Storage().getString('accessToken');
                        if (accessToken == null) {
                          loginBottomSheet(context);
                        } else {
                          context.read<WishlistNotifier>().toggleWishlist(
                                property.id,
                                refetch,
                              );
                        }
                      },
                      property: property,
                    );
                  },
                ),
              );
            },
          );
  }
}
