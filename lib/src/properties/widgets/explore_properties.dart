import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/const/constants.dart';
import 'package:marketplace_app/src/properties/controllers/property_notifier.dart';
import 'package:marketplace_app/src/properties/models/property_list_model.dart';
import 'package:marketplace_app/src/properties/widgets/staggered_tile_widget.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:provider/provider.dart';

class ExploreProperties extends StatefulWidget {
  final List<PropertyListModel>? filteredProperties;

  const ExploreProperties({super.key, this.filteredProperties});

  @override
  State<ExploreProperties> createState() => _ExplorePropertiesState();
}

class _ExplorePropertiesState extends State<ExploreProperties> {
  @override
  void initState() {
    super.initState();
    if (widget.filteredProperties == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PropertyNotifier>().fetchProperties();
      });
      // context.read<PropertyNotifier>().fetchProperties();
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyNotifier = context.watch<PropertyNotifier>();
    final properties = widget.filteredProperties ?? propertyNotifier.properties;
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
          );
        },
      ),
    );
  }
}
