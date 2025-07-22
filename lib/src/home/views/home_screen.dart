import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/src/filter/controllers/filter_notifier.dart';
import 'package:marketplace_app/src/home/widgets/custom_app_bar.dart';
import 'package:marketplace_app/src/home/widgets/select_date_section.dart';
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
      // Apply filters
      final filterNotifier = context.read<FilterNotifier>();
      final wishlistNotifier = context.read<WishlistNotifier>(); // capture before async
      await filterNotifier.applyFilters();
      
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
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Kolors.kPrimary),
                      ),
                    )
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
        child: FloatingActionButton(
          onPressed: () {
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
          backgroundColor: Kolors.kPrimary,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 32, color: Kolors.kWhite),
        ),
      ),
    );
  }
}