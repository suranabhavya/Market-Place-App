import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/src/marketplace/controllers/marketplace_notifier.dart';
import 'package:marketplace_app/src/marketplace/widgets/marketplace_app_bar.dart';
import 'package:marketplace_app/src/marketplace/widgets/explore_marketplace.dart';
import 'package:provider/provider.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  @override
  void initState() {
    super.initState();
    // Apply filters when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketplaceNotifier>().applyFilters(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    String? accessToken = Storage().getString('accessToken');
    final marketplaceNotifier = context.watch<MarketplaceNotifier>();
    
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: MarketplaceAppBar()
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: marketplaceNotifier.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Kolors.kPrimary),
                ),
              )
            : ExploreMarketplace(marketplaceItems: marketplaceNotifier.marketplaceItems),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 48.w),
        child: FloatingActionButton(
          onPressed: () {
            if (accessToken == null) {
              loginBottomSheet(context);
            } else {
              context.push("/marketplace/create");
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