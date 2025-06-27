import 'package:flutter/material.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/auth/views/email_signup_screen.dart';
import 'package:marketplace_app/src/auth/views/login_screen.dart';
import 'package:marketplace_app/src/properties/widgets/explore_properties.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:marketplace_app/src/wishlist/widgets/wishlist.dart';
import 'package:provider/provider.dart';

class WishListPage extends StatefulWidget {
  const WishListPage({super.key});

  @override
  State<WishListPage> createState() => _WishListPageState();
}

class _WishListPageState extends State<WishListPage> {
  @override
  void initState() {
    super.initState();
    
    // Load wishlist data when the screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accessToken = Storage().getString('accessToken');
      final wishlistNotifier = context.read<WishlistNotifier>();
      
      if (accessToken != null) {
        // User is logged in - load their wishlist
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

    if(accessToken == null) {
      return const EmailSignupPage();
    }
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: ReusableText(
          text: AppText.kWishlist,
          style: appStyle(16, Kolors.kPrimary, FontWeight.bold)
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              WishlistWidget(),
              // Add extra padding at the bottom to prevent tiles from being cut off
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}