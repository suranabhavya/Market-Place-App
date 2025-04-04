import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:marketplace_app/common/services/storage.dart';
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
    final String apiUrl = 'http://127.0.0.1:8000/accounts/user/${widget.userId}/';
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
      print('Error fetching profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String? accessToken = Storage().getString('accessToken');
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
      body: Padding(
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
            if (currentUser?.id != widget.userId) Center(
              child: CustomButton(
                text: 'Message',
                onTap: () async {
                  // Check if a chat already exists
                  final chatId = await checkExistingChat(widget.userId);
                  if (chatId != null) {
                    // Navigate to the existing chat
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessagePage(
                          chatId: chatId,
                          participants: userProfile!["name"],
                          otherParticipantProfilePhoto: userProfile!["profile_photo"],
                          otherParticipantId: widget.userId,
                        ),
                      ),
                    );
                  } else {
                    // Navigate to a temporary message screen
                    showMessageModal(context, widget.userId);
                  }
                },
                btnWidth: 150.w,
                btnHeight: 40.h,
                textSize: 16,
                radius: 24,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(thickness: 0.5),
            const SizedBox(height: 10),

            ReusableText(text: "Listings", style: appStyle(16, Kolors.kDark, FontWeight.bold)),
            // ...userProfile!["properties"].map<Widget>((property) {
            //   return ListTile(
            //     title: Text(property["title"]),
            //     subtitle: Text("${property["bedrooms"]} BR • ${property["bathrooms"]} BA"),
            //   );
            // }).toList(),
            const SizedBox(height: 10),

            Expanded(
              child: Consumer<WishlistNotifier>(
                builder: (context, wishlistNotifier, child) {
                  return MasonryGridView.count(
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
                            );
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}