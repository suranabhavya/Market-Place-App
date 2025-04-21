import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/const/constants.dart';
import 'package:marketplace_app/src/properties/controllers/property_notifier.dart';
import 'package:marketplace_app/src/properties/models/property_detail_model.dart';
import 'package:marketplace_app/src/properties/widgets/expandable_text.dart';
import 'package:marketplace_app/src/properties/widgets/property_bottom_bar.dart';
import 'package:marketplace_app/src/properties/widgets/staggered_tile_widget.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:provider/provider.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class PropertyPage extends StatefulWidget {
  final String propertyId;

  const PropertyPage({super.key, required this.propertyId});

  @override
  State<PropertyPage> createState() => _PropertyPageState();
}

class _PropertyPageState extends State<PropertyPage> {
  // Add a key for the ExpandableText widget
  final GlobalKey<ExpandableTextState> _expandableTextKey = GlobalKey<ExpandableTextState>();
  bool _hasFetchedNearby = false;
  bool _isLoadingNearby = false;

  @override
  void initState() {
    super.initState();
    context.read<PropertyNotifier>().fetchPropertyDetail(widget.propertyId);
  }

  @override
  void didUpdateWidget(PropertyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset the expandable text state when the property changes
    if (oldWidget.propertyId != widget.propertyId) {
      _expandableTextKey.currentState?.reset();
      _hasFetchedNearby = false;
    }
  }

  Future<void> _fetchNearbyProperties(PropertyDetailModel property) async {
    if (!_hasFetchedNearby && property.latitude != null && property.longitude != null) {
      setState(() {
        _hasFetchedNearby = true;
        _isLoadingNearby = true;
      });

      try {
        await context.read<PropertyNotifier>().fetchNearbyProperties(
          property.latitude!,
          property.longitude!,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingNearby = false;
          });
        }
      }
    }
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
    String fromDate = "${availableFrom.day} ${_getMonthName(availableFrom.month)} ${availableFrom.year}";

    if (availableTo == null) {
      return fromDate; // Return only the from date if availableTo is null
    }

    String toDate = "${availableTo.day} ${_getMonthName(availableTo.month)} ${availableFrom.year}";
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

    // Fetch nearby properties when property details are loaded
    _fetchNearbyProperties(property);

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
              // Share Button
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    // TODO: Implement share functionality to share property details
                  },
                  child: CircleAvatar(
                    backgroundColor: Kolors.kSecondaryLight,
                    child: Icon(
                      MaterialCommunityIcons.share,
                      color: Kolors.kGray,
                      size: 30.h,
                    ),
                  ),
                ),
              ),
              // Wishlist Button
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Consumer<WishlistNotifier>(
                  builder: (context, wishlistNotifier, child) { 
                    return GestureDetector(
                      onTap: () {
                        if(accessToken == null) {
                          loginBottomSheet(context);
                        } else {
                          wishlistNotifier.toggleWishlist(property.id, () {});
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
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Kolors.kGray,
                          ),
                        ),
                      ),
                      height: 350.h,
                      imageUrl: property.images![i].url,
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ReusableText(
                      text: '\$${property.rent}/${property.rentFrequency}',
                      style: appStyle(24, Kolors.kGray, FontWeight.w600)
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Kolors.kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: ReusableText(
                        text: property.propertyType.replaceAll('_', ' ').toUpperCase(),
                        style: appStyle(12, Kolors.kPrimary, FontWeight.w500)
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Kolors.kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: ReusableText(
                        text: property.listingType.toUpperCase(),
                        style: appStyle(12, Kolors.kPrimary, FontWeight.w500)
                      ),
                    ),
                  ],
                ),
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
                    style: appStyle(18, Kolors.kGray, FontWeight.bold)
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  ExpandableText(
                    key: _expandableTextKey,
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
            ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReusableText(
                        text: 'Nearby Schools',
                        style: appStyle(16, Kolors.kGray, FontWeight.bold)
                      ),
                      SizedBox(
                        height: 10.h,
                      ),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: property.subleaseDetails.getSchoolNames().map<Widget>((schoolName) {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: Colors.grey[300], // Background color
                              borderRadius: BorderRadius.circular(20), // Circular shape
                              border: Border.all(color: Kolors.kPrimary, width: 1),
                            ),
                            child: Text(
                              schoolName,
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
            ],

          if (property.amenities != null && property.amenities!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReusableText(
                      text: 'Amenities',
                      style: appStyle(16, Kolors.kGray, FontWeight.bold)
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

          // Lifestyle Section
          if (property.propertyType != 'apartment' &&
              property.lifestyle != null &&
              (property.lifestyle!.smoking != null ||
               property.lifestyle!.partying != null ||
               property.lifestyle!.dietary != null ||
               property.lifestyle!.nationality != null))
            ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReusableText(
                        text: 'Flatmate Lifestyle',
                        style: appStyle(16, Kolors.kGray, FontWeight.bold)
                      ),
                      SizedBox(height: 10.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          if (property.lifestyle!.smoking != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Kolors.kPrimary, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.smoking_rooms, size: 16.sp, color: Kolors.kPrimary),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Smoking: ${property.lifestyle!.smoking!.replaceAll('_', ' ').capitalize()}',
                                    style: appStyle(12, Kolors.kPrimary, FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          if (property.lifestyle!.partying != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Kolors.kPrimary, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.wine_bar, size: 16.sp, color: Kolors.kPrimary),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Partying: ${property.lifestyle!.partying!.replaceAll('_', ' ').capitalize()}',
                                    style: appStyle(12, Kolors.kPrimary, FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          if (property.lifestyle!.dietary != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Kolors.kPrimary, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lunch_dining, size: 16.sp, color: Kolors.kPrimary),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Dietary: ${property.lifestyle!.dietary!.replaceAll('_', ' ').capitalize()}',
                                    style: appStyle(12, Kolors.kPrimary, FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          if (property.lifestyle!.nationality != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Kolors.kPrimary, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.groups_3_sharp, size: 16.sp, color: Kolors.kPrimary),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Nationality: ${property.lifestyle!.nationality!.replaceAll('_', ' ').capitalize()}',
                                    style: appStyle(12, Kolors.kPrimary, FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(height: 10.h),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Divider(thickness: .5.h),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(height: 10.h),
              ),
            ],

          // Preferences Section
          if (property.propertyType != 'apartment' &&
              property.preference != null &&
              (property.preference!.genderPreference != null ||
               property.preference!.smokingPreference != null ||
               property.preference!.partyingPreference != null ||
               property.preference!.dietaryPreference != null ||
               property.preference!.nationalityPreference != null))
            ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReusableText(
                        text: 'Flatmate Preferences',
                        style: appStyle(16, Kolors.kGray, FontWeight.bold)
                      ),
                      SizedBox(height: 10.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          if (property.preference!.genderPreference != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Kolors.kPrimary, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people, size: 16.sp, color: Kolors.kPrimary),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Gender: ${property.preference!.genderPreference!.replaceAll('_', ' ').capitalize()}',
                                    style: appStyle(12, Kolors.kPrimary, FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          if (property.preference!.smokingPreference != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Kolors.kPrimary, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.smoking_rooms, size: 16.sp, color: Kolors.kPrimary),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Smoking: ${property.preference!.smokingPreference!.replaceAll('_', ' ').capitalize()}',
                                    style: appStyle(12, Kolors.kPrimary, FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          if (property.preference!.partyingPreference != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Kolors.kPrimary, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.wine_bar, size: 16.sp, color: Kolors.kPrimary),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Partying: ${property.preference!.partyingPreference!.replaceAll('_', ' ').capitalize()}',
                                    style: appStyle(12, Kolors.kPrimary, FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          if (property.preference!.dietaryPreference != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Kolors.kPrimary, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lunch_dining, size: 16.sp, color: Kolors.kPrimary),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Dietary: ${property.preference!.dietaryPreference!.replaceAll('_', ' ').capitalize()}',
                                    style: appStyle(12, Kolors.kPrimary, FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          if (property.preference!.nationalityPreference != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Kolors.kPrimary, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.groups_3_sharp, size: 16.sp, color: Kolors.kPrimary),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Nationality: ${property.preference!.nationalityPreference!.replaceAll('_', ' ').capitalize()}',
                                    style: appStyle(12, Kolors.kPrimary, FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(height: 10.h),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Divider(thickness: .5.h),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(height: 10.h),
              ),
            ],

          // Posted By section (moved outside of conditions)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReusableText(
                    text: 'Posted By',
                    style: appStyle(16, Kolors.kGray, FontWeight.bold)
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.grey,
                          backgroundImage: property.profilePhoto != null && property.profilePhoto!.isNotEmpty
                              ? NetworkImage(property.profilePhoto!)
                              : null,
                          child: property.profilePhoto == null || property.profilePhoto!.isEmpty
                              ? const Icon(Icons.person, size: 50, color: Colors.white)
                              : null,
                        ),
                        SizedBox(width: 24.w),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: () {
                            context.push('/public-profile', extra: property.userId);
                          },
                          child: Text(property.name, style: appStyle(14, Kolors.kPrimary, FontWeight.w500)),
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

          // Similar Properties section (moved outside of conditions)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReusableText(
                    text: 'Nearby Properties',
                    style: appStyle(16, Kolors.kGray, FontWeight.bold)
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  if (_isLoadingNearby)
                    const Center(child: CircularProgressIndicator())
                  else if (propertyNotifier.nearbyProperties.isNotEmpty)
                    Column(
                      children: propertyNotifier.nearbyProperties
                          .where((p) => p.id != property.id) // Exclude current property
                          .take(3) // Show only 3 nearby properties
                          .map((nearbyProperty) => Padding(
                                padding: EdgeInsets.only(bottom: 16.h),
                                child: StaggeredTileWidget(
                                  onTap: () {
                                    if (accessToken == null) {
                                      loginBottomSheet(context);
                                    } else {
                                      context.read<WishlistNotifier>().toggleWishlist(
                                        nearbyProperty.id,
                                        () {},
                                      );
                                    }
                                  },
                                  property: nearbyProperty,
                                ),
                              ))
                          .toList(),
                    )
                  else
                    Center(
                      child: Text(
                        "No nearby properties found",
                        style: appStyle(14, Kolors.kGray, FontWeight.normal),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      
      bottomNavigationBar: PropertyBottomBar(
        senderId: property.userId,
        senderName: property.name,
        senderProfilePhoto: property.profilePhoto,
      ),
    );
  }
}