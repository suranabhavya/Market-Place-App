import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/properties/models/property_list_model.dart';
import 'package:marketplace_app/src/properties/widgets/staggered_tile_widget.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
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

  @override
  void initState() {
    super.initState();
    fetchUserListings();
  }

  Future<void> fetchUserListings() async {
    final String apiUrl = 'http://127.0.0.1:8000/accounts/user/${widget.userId}/';
    String? accessToken = Storage().getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<PropertyListModel> properties = (data["properties"] as List)
            .map((property) => PropertyListModel.fromJson(property))
            .toList();

        setState(() {
          userProperties = properties;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load listings');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching listings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String? accessToken = Storage().getString('accessToken');

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(
          onTap: () {
            context.pop();
          },
        ),
        title: ReusableText(
          text: AppText.kMyListings,
          style: appStyle(15, Kolors.kPrimary, FontWeight.bold)
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userProperties.isEmpty
              ? const Center(child: Text("No Listings Available"))
              : Padding(
                  padding: EdgeInsets.all(16.w),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: userProperties.length,
                    itemBuilder: (context, index) {
                      final property = userProperties[index];
                      return StaggeredTileWidget(
                        onTap: () {
                          if (accessToken == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please log in to access wishlist")),
                            );
                          } else {
                            context.read<WishlistNotifier>().toggleWishlist(
                              property.id,
                              () {},
                            );
                          }
                        },
                        property: property,
                      );
                    },
                  ),
                ),
    );
  }
}