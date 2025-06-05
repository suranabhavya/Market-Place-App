import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/src/marketplace/controllers/marketplace_notifier.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_detail_model.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:marketplace_app/src/properties/widgets/property_bottom_bar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class MarketplaceDetailScreen extends StatefulWidget {
  final String itemId;
  
  const MarketplaceDetailScreen({
    super.key,
    required this.itemId,
  });

  @override
  State<MarketplaceDetailScreen> createState() => _MarketplaceDetailScreenState();
}

class _MarketplaceDetailScreenState extends State<MarketplaceDetailScreen> {
  MarketplaceDetailModel? _item;
  bool _isLoading = true;
  String? _error;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchItemDetail();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchItemDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final marketplaceNotifier = context.read<MarketplaceNotifier>();
      final item = await marketplaceNotifier.fetchMarketplaceDetail(widget.itemId);
      
      if (item != null) {
        setState(() {
          _item = item;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load item details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading item: $e';
        _isLoading = false;
      });
    }
  }

  String _formatCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'like_new':
        return 'Like New';
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      case 'poor':
        return 'Poor';
      default:
        return condition;
    }
  }

  String _formatItemType(String itemType) {
    return itemType.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  Future<void> _launchMaps() async {
    if (_item?.latitude != null && _item?.longitude != null) {
      final Uri mapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${_item!.latitude},${_item!.longitude}'
      );
      
      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open maps')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: AppBackButton(onTap: () => context.pop()),
          title: Text('Loading...', style: appStyle(16, Kolors.kPrimary, FontWeight.w600)),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Kolors.kPrimary),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: AppBackButton(onTap: () => context.pop()),
          title: Text('Error', style: appStyle(16, Kolors.kPrimary, FontWeight.w600)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Kolors.kRed),
              SizedBox(height: 16.h),
              Text(_error!, style: appStyle(16, Kolors.kDark, FontWeight.w500)),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _fetchItemDetail,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_item == null) {
      return Scaffold(
        appBar: AppBar(
          leading: AppBackButton(onTap: () => context.pop()),
          title: Text('Not Found', style: appStyle(16, Kolors.kPrimary, FontWeight.w600)),
        ),
        body: const Center(
          child: Text('Item not found'),
        ),
      );
    }

    final String? accessToken = Storage().getString('accessToken');
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Images
          SliverAppBar(
            expandedHeight: 300.h,
            pinned: true,
            leading: Container(
              margin: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: AppBackButton(
                onTap: () => context.pop(),
                color: Kolors.kWhite,
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Consumer<WishlistNotifier>(
                  builder: (context, wishlistNotifier, child) {
                    final isInWishlist = wishlistNotifier.wishlist
                        .contains(_item!.id);
                    
                    return IconButton(
                      onPressed: () {
                        if (accessToken == null) {
                          loginBottomSheet(context);
                        } else {
                          wishlistNotifier.toggleWishlist(
                            _item!.id, 
                            () {}, // Empty refetch function since we're not on a list screen
                            type: 'marketplace'
                          );
                        }
                      },
                      icon: Icon(
                        isInWishlist ? Icons.favorite : Icons.favorite_border,
                        color: isInWishlist ? Kolors.kRed : Kolors.kWhite,
                      ),
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _item!.images.isNotEmpty
                  ? Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemCount: _item!.images.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              _item!.images[index].image,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Kolors.kGrayLight,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 64,
                                    color: Kolors.kGray,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        if (_item!.images.length > 1)
                          Positioned(
                            bottom: 16.h,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _item!.images.length,
                                (index) => Container(
                                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                                  width: 8.w,
                                  height: 8.h,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == index
                                        ? Kolors.kWhite
                                        : Kolors.kWhite.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      color: Kolors.kGrayLight,
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: Kolors.kGray,
                      ),
                    ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _item!.title,
                          style: appStyle(24, Kolors.kDark, FontWeight.bold),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${_item!.price.toStringAsFixed(2)}',
                            style: appStyle(24, Kolors.kPrimary, FontWeight.bold),
                          ),
                          if (_item!.originalPrice != null && _item!.originalPrice! > _item!.price)
                            Text(
                              '\$${_item!.originalPrice!.toStringAsFixed(2)}',
                              style: appStyle(16, Kolors.kGray, FontWeight.w400)
                                  .copyWith(decoration: TextDecoration.lineThrough),
                            ),
                        ],
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Item Details
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Kolors.kOffWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Category', _formatItemType(_item!.itemType)),
                        _buildDetailRow('Subcategory', _formatItemType(_item!.itemSubtype)),
                        _buildDetailRow('Condition', _formatCondition(_item!.condition)),
                        if (_item!.availabilityDate != null)
                          _buildDetailRow('Available From', 
                              DateFormat('MMM dd, yyyy').format(_item!.availabilityDate!)),
                        _buildDetailRow('Negotiable', _item!.negotiable ? 'Yes' : 'No'),
                        _buildDetailRow('Delivery Available', _item!.deliveryAvailable ? 'Yes' : 'No'),
                        _buildDetailRow('Original Receipt', _item!.originalReceiptAvailable ? 'Available' : 'Not Available'),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  // Description
                  if (_item!.description != null && _item!.description!.isNotEmpty) ...[
                    Text(
                      'Description',
                      style: appStyle(18, Kolors.kDark, FontWeight.w600),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _item!.description!,
                      style: appStyle(14, Kolors.kDark, FontWeight.w400),
                    ),
                    SizedBox(height: 20.h),
                  ],
                  
                  // Location
                  if (!_item!.hideAddress) ...[
                    Text(
                      'Location',
                      style: appStyle(18, Kolors.kDark, FontWeight.w600),
                    ),
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: _launchMaps,
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          border: Border.all(color: Kolors.kGrayLight),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: Kolors.kPrimary, size: 20),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                _item!.unit != null 
                                    ? '${_item!.address}, Unit ${_item!.unit}'
                                    : _item!.address,
                                style: appStyle(14, Kolors.kDark, FontWeight.w400),
                              ),
                            ),
                            Icon(Icons.open_in_new, color: Kolors.kGray, size: 16),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                  
                  // Schools Nearby
                  if (_item!.schoolsNearby.isNotEmpty) ...[
                    Text(
                      'Schools Nearby',
                      style: appStyle(18, Kolors.kDark, FontWeight.w600),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: _item!.schoolsNearby.map((school) => Chip(
                        label: Text(school.name),
                        backgroundColor: Kolors.kPrimaryLight.withOpacity(0.1),
                        labelStyle: appStyle(12, Kolors.kPrimary, FontWeight.w500),
                      )).toList(),
                    ),
                    SizedBox(height: 20.h),
                  ],
                  
                  // Seller Information
                  Text(
                    'Seller Information',
                    style: appStyle(18, Kolors.kDark, FontWeight.w600),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: Kolors.kGrayLight),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24.r,
                          backgroundColor: Kolors.kPrimaryLight,
                          backgroundImage: _item!.seller.profilePhoto != null
                              ? NetworkImage(_item!.seller.profilePhoto!)
                              : null,
                          child: _item!.seller.profilePhoto == null
                              ? Text(
                                  _item!.seller.name.isNotEmpty 
                                      ? _item!.seller.name[0].toUpperCase()
                                      : _item!.seller.email[0].toUpperCase(),
                                  style: appStyle(18, Kolors.kWhite, FontWeight.bold),
                                )
                              : null,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _item!.seller.name.isNotEmpty 
                                    ? _item!.seller.name 
                                    : 'Anonymous Seller',
                                style: appStyle(16, Kolors.kDark, FontWeight.w600),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Member since ${DateFormat('MMM yyyy').format(_item!.createdAt)}',
                                style: appStyle(12, Kolors.kGray, FontWeight.w400),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20.h), // Space for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Bottom Action Buttons
      bottomNavigationBar: PropertyBottomBar(
        senderId: _item!.seller.id,
        senderName: _item!.seller.name.isNotEmpty ? _item!.seller.name : 'Anonymous Seller',
        senderProfilePhoto: _item!.seller.profilePhoto,
        isMarketplaceItem: true,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: appStyle(14, Kolors.kGray, FontWeight.w500),
          ),
          Text(
            value,
            style: appStyle(14, Kolors.kDark, FontWeight.w500),
          ),
        ],
      ),
    );
  }
} 