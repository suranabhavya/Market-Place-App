import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/message/views/message_screen.dart';
import 'package:marketplace_app/src/properties/models/property_list_model.dart';
import 'package:marketplace_app/src/auth/controllers/auth_notifier.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:marketplace_app/src/properties/widgets/staggered_tile_widget.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:provider/provider.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/src/chat/utils/chat_utils.dart';
import 'package:marketplace_app/src/message/views/message_modal_screen.dart';

class PublicProfilePage extends StatefulWidget {
  final int userId;

  const PublicProfilePage({super.key, required this.userId});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    final String apiUrl = '${Environment.iosAppBaseUrl}/accounts/user/${widget.userId}/';
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        setState(() {
          userProfile = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error fetching profile: $e');
    }
  }

  String _getCityStatePostcode(Map<String, dynamic> item) {
    List<String> locationParts = [];
    
    if (item['city'] != null && item['city'].toString().isNotEmpty) {
      locationParts.add(item['city'].toString());
    }
    
    if (item['state'] != null && item['state'].toString().isNotEmpty) {
      locationParts.add(item['state'].toString());
    }
    
    if (item['pincode'] != null && item['pincode'].toString().isNotEmpty) {
      locationParts.add(item['pincode'].toString());
    }
    
    return locationParts.isEmpty ? 'Location not available' : locationParts.join(', ');
  }

  void _navigateToExistingChat(BuildContext context, int chatId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagePage(
          chatId: chatId,
          participants: userProfile!["name"],
          otherParticipantId: widget.userId,
          otherParticipantProfilePhoto: userProfile!["profile_photo"],
        ),
      ),
    );
  }

  void _showNewChatModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: MessageModalContent(senderId: widget.userId),
        );
      },
    );
  }

  void _handleMessageTap(BuildContext context) async {
    final chatId = await checkExistingChat(widget.userId);
    if (!mounted) return;
    
    if (chatId != null) {
      // Navigate to the existing chat
      if (mounted) {
        // ignore: use_build_context_synchronously
        _navigateToExistingChat(context, chatId);
      }
    } else {
      // Show message modal for new chat
      if (mounted) {
        // ignore: use_build_context_synchronously
        _showNewChatModal(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? accessToken = Storage().getString('accessToken');
    final currentUser = context.read<AuthNotifier>().getUserData();
    
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userProfile == null) {
      return const Scaffold(
        body: Center(child: Text("Failed to load profile")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: ReusableText(
          text: "Public Profile",
          style: appStyle(16, Kolors.kPrimary, FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey,
                      backgroundImage: userProfile!["profile_photo"] != null
                          ? NetworkImage(userProfile!["profile_photo"])
                          : null,
                      child: userProfile!["profile_photo"] == null
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    if (userProfile!["school_email_verified"] == true)
                      const Icon(Icons.verified, color: Colors.blue, size: 24),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: ReusableText(
                  text: userProfile!["name"],
                  style: appStyle(18, Kolors.kGray, FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              // Removed Message button from here
              const SizedBox(height: 10),
              const Divider(thickness: 0.5),
              const SizedBox(height: 10),

              // Properties Section
              if (userProfile!["properties"] != null && userProfile!["properties"].isNotEmpty) ...[
                ReusableText(text: "Property Listings", style: appStyle(16, Kolors.kDark, FontWeight.bold)),
                const SizedBox(height: 10),

                Consumer<WishlistNotifier>(
                  builder: (context, wishlistNotifier, child) {
                    return MasonryGridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 1,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      itemCount: userProfile!["properties"].length,
                      itemBuilder: (context, index) {
                        final property = userProfile!["properties"][index];

                        return StaggeredTileWidget(
                          property: PropertyListModel(
                            id: property["id"],
                            title: property["title"],
                            rent: property["rent"],
                            rentFrequency: property["rent_frequency"],
                            bedrooms: property["bedrooms"],
                            bathrooms: property["bathrooms"],
                            address: property["address"],
                            city: property["city"],
                            state: property["state"],
                            pincode: property["pincode"],
                            hideAddress: property["hide_address"] ?? false,
                            latitude: property["latitude"],
                            longitude: property["longitude"],
                            images: List<String>.from(property["images"] ?? []),
                            createdAt: DateTime.parse(property["created_at"]),
                            updatedAt: DateTime.parse(property["updated_at"]),
                            isActive: property["is_active"],
                          ),
                          onTap: () {
                            if (accessToken == null) {
                              loginBottomSheet(context);
                            } else {
                              wishlistNotifier.toggleWishlist(
                                property["id"],
                                () {
                                  setState(() {});
                                },
                                type: 'property',
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
                
                const SizedBox(height: 20),
              ],

              // Marketplace Items Section
              if (userProfile!["move_out_sale_items"] != null && userProfile!["move_out_sale_items"].isNotEmpty) ...[
                ReusableText(text: "Marketplace Items", style: appStyle(16, Kolors.kDark, FontWeight.bold)),
                const SizedBox(height: 10),

                Consumer<WishlistNotifier>(
                  builder: (context, wishlistNotifier, child) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 10.w,
                        mainAxisSpacing: 10.h,
                      ),
                      itemCount: userProfile!["move_out_sale_items"].length,
                      itemBuilder: (context, index) {
                        final item = userProfile!["move_out_sale_items"][index];
                        debugPrint('Marketplace item $index: ${item["title"]}');
                        debugPrint('Marketplace item images: ${item["images"]}');
                        final String? imageUrl = item["images"] != null && item["images"].isNotEmpty 
                            ? item["images"][0]["url"] 
                            : null;
                        debugPrint('Extracted imageUrl: $imageUrl');

                        return GestureDetector(
                          onTap: () => context.push('/marketplace/${item["id"]}'),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                Column(
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
                                            item["title"],
                                            style: appStyle(14, Kolors.kPrimary, FontWeight.w600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 4.h),
                                          Row(
                                            children: [
                                              Text(
                                                '\$${item["price"]}',
                                                style: appStyle(16, Kolors.kPrimary, FontWeight.bold),
                                              ),
                                              SizedBox(width: 4.w),
                                              if (item["original_price"] != null && 
                                                  double.parse(item["original_price"]) > double.parse(item["price"]))
                                                Text(
                                                  '\$${item["original_price"]}',
                                                  style: appStyle(12, Kolors.kGray, FontWeight.w400).copyWith(
                                                    decoration: TextDecoration.lineThrough,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            (item["hide_address"] ?? false)
                                                ? _getCityStatePostcode(item)
                                                : item["address"] ?? 'Address not available',
                                            style: appStyle(12, Kolors.kGray, FontWeight.w400),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Wishlist button
                                Positioned(
                                  right: 8.h,
                                  top: 8.h,
                                  child: Consumer<WishlistNotifier>(
                                    builder: (context, wishlistNotifier, child) {
                                      final isInWishlist = wishlistNotifier.wishlist.contains(item["id"]);
                                      
                                      return GestureDetector(
                                        onTap: () {
                                          if (accessToken == null) {
                                            loginBottomSheet(context);
                                          } else {
                                            wishlistNotifier.toggleWishlist(
                                              item["id"],
                                              () {
                                                setState(() {});
                                              },
                                              type: 'marketplace',
                                            );
                                          }
                                        },
                                        child: CircleAvatar(
                                          radius: 15.r,
                                          backgroundColor: Kolors.kSecondaryLight,
                                          child: Icon(
                                            isInWishlist ? Icons.favorite : Icons.favorite_border,
                                            color: isInWishlist ? Kolors.kRed : Kolors.kGray,
                                            size: 15.r,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],

              // Show message if no listings found
              if ((userProfile!["properties"] == null || userProfile!["properties"].isEmpty) &&
                  (userProfile!["move_out_sale_items"] == null || userProfile!["move_out_sale_items"].isEmpty))
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.h),
                    child: ReusableText(
                      text: "No listings found",
                      style: appStyle(14, Kolors.kGray, FontWeight.w500),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: (currentUser?.id != widget.userId)
          ? SafeArea(
              top: false,
              left: false,
              right: false,
              bottom: true,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: CustomButton(
                  text: 'Message',
                  onTap: () {
                    final String? accessToken = Storage().getString('accessToken');
                    if(accessToken == null) {
                      loginBottomSheet(context);
                    } else {
                      _handleMessageTap(context);
                    }
                  },
                  btnWidth: double.infinity,
                  btnHeight: 48.h,
                  textSize: 16,
                  radius: 24,
                ),
              ),
            )
          : null,
    );
  }
}