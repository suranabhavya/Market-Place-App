import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/const/constants.dart';
import 'package:marketplace_app/src/properties/controllers/property_notifier.dart';
import 'package:marketplace_app/src/properties/widgets/expandable_text.dart';
import 'package:marketplace_app/src/properties/widgets/property_bottom_bar.dart';
import 'package:marketplace_app/src/properties/widgets/similar_properties.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:provider/provider.dart';

class PropertyPage extends StatefulWidget {
  final String propertyId;

  const PropertyPage({super.key, required this.propertyId});

  @override
  State<PropertyPage> createState() => _PropertyPageState();
}

class _PropertyPageState extends State<PropertyPage> {
  @override
  void initState() {
    super.initState();
    context.read<PropertyNotifier>().fetchPropertyDetail(widget.propertyId);
  }

  String getDaysAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt).inDays;

    if (difference == 0) {
      return 'Listed today';
    } else {
      return 'Listed $difference days ago';
    }
  }

  // Helper function to get month name
  String _getMonthName(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  String getAvailableDuration(DateTime availableFrom, DateTime? availableTo) {
    String fromDate = "${availableFrom.day} ${_getMonthName(availableFrom.month)}";

    if (availableTo == null) {
      return fromDate; // Return only the from date if availableTo is null
    }

    String toDate = "${availableTo.day} ${_getMonthName(availableTo.month)}";
    return "$fromDate - $toDate";
  }

  @override
  Widget build(BuildContext context) {
    String? accessToken = Storage().getString(('accessToken'));
    final propertyNotifier = context.watch<PropertyNotifier>();
    final property = propertyNotifier.selectedProperty;

    if (propertyNotifier.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (property == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Property Details")),
        body: const Center(child: Text("Failed to load property details.")),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            expandedHeight: 280.h,
            collapsedHeight: 65.h,
            floating: false,
            pinned: true,
            leading: const AppBackButton(),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Consumer<WishlistNotifier>(
                  builder: (context, wishlistNotifier, child) { 
                    return GestureDetector(
                      onTap: () {
                        if(accessToken == null) {
                          loginBottomSheet(context);
                        } else {
                          wishlistNotifier.addRemoveWishlist(property.id, () {});
                        }
                      },
                      child: CircleAvatar(
                        backgroundColor: Kolors.kSecondaryLight,
                        child: Icon(
                          AntDesign.heart,
                          color: wishlistNotifier.wishlist.contains(property.id)? Kolors.kRed : Kolors.kGray,
                        ),
                      ),
                    );
                  }
                )
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              background: SizedBox(
                height: 415.h,
                child: property.images!.isNotEmpty
                ? ImageSlideshow(
                  indicatorColor: Kolors.kPrimaryLight,
                  onPageChanged: (p) {},
                  autoPlayInterval: 15000,
                  isLoop: property.images!.length > 1 ? true : false,
                  children: List.generate(property.images!.length, (i) {
                    return CachedNetworkImage(
                      placeholder: placeholder,
                      errorWidget: errorWidget,
                      height: 350.h,
                      imageUrl: property.images![i],
                      fit: BoxFit.cover,
                    );
                  }),
                ) : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.image_not_supported,
                        size: 100,
                        color: Kolors.kGray,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        "No images available",
                        style: appStyle(14.sp, Kolors.kGray, FontWeight.w400),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: SizedBox(
              height: 16.h,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: ReusableText(
                text: '\$${property.rent}/${property.rentFrequency}',
                style: appStyle(24, Kolors.kGray, FontWeight.w600)
              ),
            )
          ),

          // Bedrooms, Bathrooms, Square Footage (Shown only if not null)
          if (property.bedrooms != null || property.bathrooms != null || property.squareFootage != null)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 8.h,
              ),
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    if (property.bedrooms != null) ...[
                      Icon(Icons.bed, size: 16.sp, color: Kolors.kGray),
                      SizedBox(width: 4.w),
                      Text('${property.bedrooms}BR',
                          style: appStyle(13.sp, Kolors.kGray, FontWeight.w400)),
                      SizedBox(width: 8.w),
                    ],
                    if (property.bathrooms != null) ...[
                      Icon(Icons.bathtub, size: 16.sp, color: Kolors.kGray),
                      SizedBox(width: 4.w),
                      Text('${property.bathrooms}BA',
                          style: appStyle(13.sp, Kolors.kGray, FontWeight.w400)),
                      SizedBox(width: 8.w),
                    ],
                    if (property.squareFootage != null) ...[
                      Icon(MaterialCommunityIcons.ruler, size: 16.sp, color: Kolors.kGray),
                      SizedBox(width: 4.w),
                      Text('${property.squareFootage} Sqft',
                          style: appStyle(13.sp, Kolors.kGray, FontWeight.w400)),
                    ],
                  ],
                ),
              ),
            ),
        
          SliverToBoxAdapter(
            child: SizedBox(
              height: 16.h,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ReusableText(
                    text: property.address,
                    style: appStyle(14, Kolors.kGray, FontWeight.w600)
                  ),
                ],
              ),
            )
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 12.h,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Divider(
                thickness: .5.h,
              ),
            )
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 16.sp,
                        color: Kolors.kGray,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        getDaysAgo(property.createdAt),
                        style: appStyle(13.sp, Kolors.kGray, FontWeight.w400),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        MaterialCommunityIcons.clock_outline,
                        size: 16.sp,
                        color: Kolors.kGray,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        getAvailableDuration(property.subleaseDetails.availableFrom, property.subleaseDetails.availableTo),
                        style: appStyle(13.sp, Kolors.kGray, FontWeight.w400),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Divider(
                thickness: .5.h,
              ),
            )
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 10.h,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReusableText(
                    text: property.title,
                    style: appStyle(18, Kolors.kGray, FontWeight.normal)
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  ExpandableText(
                    text: property.description
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 10.h,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Divider(
                thickness: .5.h,
              ),
            )
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 10.h,
            ),
          ),

          if (property.subleaseDetails.schoolsNearby != null && property.subleaseDetails.schoolsNearby!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReusableText(
                      text: 'Nearby Schools',
                      style: appStyle(18, Kolors.kGray, FontWeight.normal)
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: property.subleaseDetails.schoolsNearby!.map<Widget>((amenity) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: Colors.grey[300], // Background color
                            borderRadius: BorderRadius.circular(20), // Circular shape
                            border: Border.all(color: Kolors.kPrimary, width: 1),
                          ),
                          child: Text(
                            amenity,
                            style: appStyle(12, Kolors.kPrimary, FontWeight.w500),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 10.h,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Divider(
                thickness: .5.h,
              ),
            )
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 10.h,
            ),
          ),

          if (property.amenities != null && property.amenities!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReusableText(
                      text: 'Amenities',
                      style: appStyle(18, Kolors.kGray, FontWeight.normal)
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: property.amenities!.map<Widget>((amenity) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: Colors.grey[300], // Background color
                            borderRadius: BorderRadius.circular(20), // Circular shape
                            border: Border.all(color: Kolors.kPrimary, width: 1),
                          ),
                          child: Text(
                            amenity,
                            style: appStyle(12, Kolors.kPrimary, FontWeight.w500),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Divider(
                        thickness: .5.h,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 10.h,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReusableText(
                    text: 'Posted By',
                    style: appStyle(18, Kolors.kGray, FontWeight.normal)
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 35,
                          backgroundColor: Kolors.kOffWhite,
                          backgroundImage: NetworkImage(
                            AppText.kProfilePic
                          ),
                        ),
                        SizedBox(width: 24.w),
                        ReusableText(
                          text: property.name,
                          style: appStyle(18, Kolors.kGray, FontWeight.normal)
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        
          SliverToBoxAdapter(
            child: SizedBox(
              height: 10.h,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Divider(
                thickness: .5.h,
              ),
            )
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 10.h,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReusableText(
                    text: 'Similar Homes Nearby',
                    style: appStyle(18, Kolors.kGray, FontWeight.normal)
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  // const SimilarProperties(),
                ],
              ),
            ),
          ),
        ],
      ),
      
      bottomNavigationBar: PropertyBottomBar(
        price: property.rent.toString(),
      ),
    );
  }
}








