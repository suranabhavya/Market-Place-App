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
// Removed direct dependency on PropertyNotifier; fetching handled via FilterNotifier
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

    // Initialize filters and wishlist when the page loads; fetch on entry
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final filterNotifier = context.read<FilterNotifier>();

      // Always fetch properties via filters on screen entry
      await filterNotifier.applyFilters();

      // After filters render, kick off wishlist init without blocking UI
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final accessToken = Storage().getString('accessToken');
        final wishlistNotifier = context.read<WishlistNotifier>();
        
        if (accessToken == null) {
          wishlistNotifier.clearWishlist();
          return;
        }

        // Small delay to ensure first paint is complete, then fire-and-forget
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          wishlistNotifier.loadWishlistFromStorage();
          // Fire-and-forget; do not await
          // ignore: discarded_futures
          wishlistNotifier.fetchWishlist();
        });
      });
    });
  }

  /// Build the main content area with improved loading state handling
  Widget _buildHomeContent(BuildContext context, FilterNotifier filterNotifier) {
    // Check if we're loading or have data
    bool isLoading = filterNotifier.isLoading;
    
    if (isLoading) {
      return const ListShimmer();
    } else if (filterNotifier.filteredProperties.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: ExploreProperties(filteredProperties: filterNotifier.filteredProperties),
      );
    } else {
      // Show empty state or retry option
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.home_outlined,
                size: 64.w,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16.h),
              Text(
                'No properties available',
                style: TextStyle(
                  fontSize: 18.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Properties are loading in the background.\nTap to refresh if needed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 20.h),
              ElevatedButton.icon(
                onPressed: () async {
                  final filterNotifier = context.read<FilterNotifier>();
                  await filterNotifier.applyFilters();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                ),
              ),
            ],
          ),
        ),
      );
    }
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
              child: _buildHomeContent(context, filterNotifier),
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