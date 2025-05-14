import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_list_model.dart';

class ExploreMarketplace extends StatelessWidget {
  final List<MarketplaceListModel> marketplaceItems;

  const ExploreMarketplace({
    super.key,
    required this.marketplaceItems,
  });

  @override
  Widget build(BuildContext context) {
    if (marketplaceItems.isEmpty) {
      return Center(
        child: ReusableText(
          text: "No items found",
          style: appStyle(14, Kolors.kGray, FontWeight.w500),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
      ),
      itemCount: marketplaceItems.length,
      itemBuilder: (context, index) {
        final item = marketplaceItems[index];
        final String? imageUrl = item.images.isNotEmpty ? item.images.first.image : null;

        return GestureDetector(
          onTap: () => context.push('/marketplace/item/${item.id}'),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Kolors.kGray,
                                    size: 32,
                                  ),
                                );
                              },
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Kolors.kGray,
                              size: 32,
                            ),
                          ),
                  ),
                ),
                
                // Item details
                Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: appStyle(14, Kolors.kPrimary, FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Text(
                            '\$${item.price}',
                            style: appStyle(16, Kolors.kPrimary, FontWeight.bold),
                          ),
                          SizedBox(width: 4.w),
                          if (item.originalPrice > item.price)
                            Text(
                              '\$${item.originalPrice}',
                              style: appStyle(12, Kolors.kGray, FontWeight.w400).copyWith(
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        item.itemType,
                        style: appStyle(12, Kolors.kGray, FontWeight.w400),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}