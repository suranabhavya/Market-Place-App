import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/properties/models/property_list_model.dart';
import 'package:marketplace_app/src/properties/widgets/staggered_tile_widget.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/src/profile/controllers/profile_notifier.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:marketplace_app/src/properties/controllers/property_notifier.dart';
import 'package:provider/provider.dart';

class UserListingsPage extends StatefulWidget {
  final int userId;

  const UserListingsPage({super.key, required this.userId});

  @override
  State<UserListingsPage> createState() => _UserListingsPageState();
}

class _UserListingsPageState extends State<UserListingsPage> {
  List<PropertyListModel> userProperties = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchUserListings();
  }

  Future<void> fetchUserListings() async {
    final String apiUrl = '${Environment.iosAppBaseUrl}/accounts/user/${widget.userId}/';
    String? accessToken = Storage().getString('accessToken');

    if (accessToken == null) {
      setState(() {
        errorMessage = "Authentication required";
        isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Token $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<PropertyListModel> properties = (data["properties"] as List)
            .map((property) => PropertyListModel.fromJson(property))
            .toList();

        if (mounted) {
          setState(() {
            userProperties = properties;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = "Failed to load listings: ${response.statusCode}";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Error fetching listings: $e";
          isLoading = false;
        });
      }
      debugPrint('Error fetching listings: $e');
    }
  }

  Future<void> _refreshListings() async {
    await fetchUserListings();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<ProfileNotifier>(context).user;
    final bool isCurrentUser = user != null && user.id == widget.userId;
    
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: ReusableText(
          text: isCurrentUser ? AppText.kMyListings : "My Listings",
          style: appStyle(16, Kolors.kPrimary, FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: isLoading 
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Kolors.kPrimary),
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 50, color: Kolors.kRed),
                      SizedBox(height: 10.h),
                      Text(
                        errorMessage!,
                        style: appStyle(14, Kolors.kDark, FontWeight.normal),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20.h),
                      ElevatedButton(
                        onPressed: _refreshListings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Kolors.kPrimary,
                          foregroundColor: Kolors.kWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : userProperties.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.home_work_outlined, size: 60, color: Kolors.kGray),
                          SizedBox(height: 15.h),
                          Text(
                            "No Listings Available",
                            style: appStyle(16, Kolors.kDark, FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          if (isCurrentUser) ...[
                            SizedBox(height: 10.h),
                            Text(
                              "Create your first listing to get started",
                              style: appStyle(14, Kolors.kGray, FontWeight.normal),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 20.h),
                            ElevatedButton(
                              onPressed: () => context.push('/property/create'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Kolors.kPrimaryLight,
                                foregroundColor: Kolors.kWhite,
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Text(
                                'Create Listing',
                                style: appStyle(14, Kolors.kWhite, FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshListings,
                      color: Kolors.kPrimary,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            crossAxisSpacing: 8.w,
                            mainAxisSpacing: 8.h,
                            childAspectRatio: 1.18 .h,
                          ),
                          itemCount: userProperties.length,
                          itemBuilder: (context, index) {
                            final property = userProperties[index];
                            return StaggeredTileWidget(
                              onTap: () {
                                String? accessToken = Storage().getString('accessToken');
                                if (accessToken == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Please log in to access wishlist"),
                                      backgroundColor: Kolors.kRed,
                                    ),
                                  );
                                } else {
                                  context.read<WishlistNotifier>().toggleWishlist(
                                    property.id,
                                    () {},
                                  );
                                }
                              },
                              property: property,
                              onEdit: isCurrentUser ? () async {
                                await context.push('/my-listings/edit/${property.id}');
                                // Fetch updated properties after returning from edit screen
                                await fetchUserListings();
                              } : null,
                              onDelete: isCurrentUser ? () async {
                                String? accessToken = Storage().getString('accessToken');
                                if (accessToken == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("User not authenticated")),
                                  );
                                  return;
                                }

                                await context.read<PropertyNotifier>().deleteProperty(
                                  token: accessToken,
                                  propertyId: property.id,
                                  onSuccess: () {
                                    setState(() {
                                      userProperties.removeWhere((p) => p.id == property.id);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Property deleted successfully")),
                                    );
                                  },
                                  onError: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Failed to delete property")),
                                    );
                                  },
                                );
                              } : null,
                            );
                          },
                        ),
                      ),
                    ),
    );
  }
}