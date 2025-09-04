import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/common/widgets/shimmers/list_shimmer.dart';
import 'package:marketplace_app/src/filter/controllers/filter_notifier.dart';
import 'package:marketplace_app/src/home/widgets/custom_app_bar.dart';
import 'package:marketplace_app/src/home/widgets/select_date_section.dart';
import 'package:marketplace_app/src/properties/controllers/property_notifier.dart';
import 'package:marketplace_app/src/properties/widgets/explore_properties.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:provider/provider.dart';
import 'package:marketplace_app/common/services/push_notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    PushNotificationService().requestPermissionIfNeeded();
    
    // Initialize both filters and wishlist when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final filterNotifier = context.read<FilterNotifier>();
      final wishlistNotifier = context.read<WishlistNotifier>();
      final propertyNotifier = context.read<PropertyNotifier>();
      
      // Only apply filters if we have specific filter criteria or if properties aren't loaded yet
      // This avoids redundant API call since splash screen already fetched basic properties
      bool hasActiveFilters = filterNotifier.searchKey.isNotEmpty ||
          filterNotifier.selectedBedrooms.isNotEmpty ||
          filterNotifier.selectedBathrooms.isNotEmpty ||
          filterNotifier.selectedPropertyTypes.isNotEmpty ||
          filterNotifier.selectedSchools.isNotEmpty ||
          filterNotifier.latitude != null ||
          filterNotifier.longitude != null ||
          filterNotifier.availableFrom != null ||
          filterNotifier.availableTo != null ||
          filterNotifier.smokingPreference.isNotEmpty ||
          filterNotifier.partyingPreference.isNotEmpty ||
          filterNotifier.dietaryPreference.isNotEmpty ||
          filterNotifier.nationalityPreference.isNotEmpty ||
          filterNotifier.amenities.values.any((selected) => selected);
      
      if (hasActiveFilters || propertyNotifier.properties.isEmpty) {
        debugPrint("HomeScreen: Applying filters due to active filters or empty properties");
        await filterNotifier.applyFilters();
      } else {
        debugPrint("HomeScreen: Skipping filter application - using properties from splash screen (${propertyNotifier.properties.length} items)");
        // Initialize filtered properties with data from splash screen
        filterNotifier.initializeFromProperties(
          propertyNotifier.properties,
          propertyNotifier.totalPropertiesCount,
          propertyNotifier.nextPageUrl,
        );
      }
      
      // Initialize wishlist state
      final accessToken = Storage().getString('accessToken');
      
      if (accessToken != null) {
        // User is logged in - load their wishlist to ensure proper state
        wishlistNotifier.loadWishlistFromStorage();
        wishlistNotifier.fetchWishlist();
      } else {
        // No user logged in - clear wishlist
        wishlistNotifier.clearWishlist();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String? accessToken = Storage().getString('accessToken');
    final filterNotifier = context.watch<FilterNotifier>();
    
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: CustomAppBar()
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Fixed header section with date selector
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: const SelectDateSection(),
            ),
            
            // Expandable content section
            Expanded(
              child: filterNotifier.isLoading
                  ? const ListShimmer()
                  : Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: ExploreProperties(filteredProperties: filterNotifier.filteredProperties),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 48.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Kolors.kPrimary.withOpacity(0.8),
                    Kolors.kPrimaryLight.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(25.r),
                border: Border.all(
                  color: Kolors.kPrimaryLight.withOpacity(0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Kolors.kPrimary.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Kolors.kPrimaryLight.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25.r),
                  onTap: () {
                    if (accessToken == null) {
                      loginBottomSheet(context);
                    } else {
                      final filterNotifier = context.read<FilterNotifier>();
                      context.push("/property/create").then((_) async {
                        if (mounted) {
                          await filterNotifier.applyFilters();
                        }
                      });
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          color: Kolors.kWhite,
                          size: 24.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'List your Place',
                          style: TextStyle(
                            color: Kolors.kWhite,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                color: Kolors.kDark.withOpacity(0.5),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}