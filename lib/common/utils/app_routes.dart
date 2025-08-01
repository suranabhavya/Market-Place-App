import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/src/auth/views/email_signup_screen.dart';
import 'package:marketplace_app/src/auth/views/login_screen.dart';
import 'package:marketplace_app/src/auth/views/mobile_otp_screen.dart';
import 'package:marketplace_app/src/auth/views/mobile_signup_screen.dart';
import 'package:marketplace_app/src/auth/views/registration_screen.dart';
import 'package:marketplace_app/src/categories/views/categories_screen.dart';
import 'package:marketplace_app/src/entrypoint/views/entrypoint.dart';
import 'package:marketplace_app/src/filter/views/filter_screen.dart';
import 'package:marketplace_app/src/marketplace/views/create_marketplace_screen.dart';
import 'package:marketplace_app/src/marketplace/views/marketplace_detail_screen.dart';
import 'package:marketplace_app/src/marketplace/views/marketplace_filter_screen.dart';
import 'package:marketplace_app/src/marketplace/views/marketplace_search_screen.dart';
import 'package:marketplace_app/src/notifications/views/notification_screen.dart';
import 'package:marketplace_app/src/onboarding/views/onboarding_screen.dart';
import 'package:marketplace_app/src/profile/views/account_screen.dart';
import 'package:marketplace_app/src/profile/views/settings_screen.dart';
import 'package:marketplace_app/src/profile/views/update_email_screen.dart';
import 'package:marketplace_app/src/profile/views/update_password_screen.dart';
import 'package:marketplace_app/src/profile/views/user_listings_screen.dart';
import 'package:marketplace_app/src/profile/views/user_marketplace_listings_screen.dart';
import 'package:marketplace_app/src/profile/views/verify_school_email_screen.dart';
import 'package:marketplace_app/src/properties/views/create_property_screen.dart';
import 'package:marketplace_app/src/properties/views/property_edit_screen.dart';
import 'package:marketplace_app/src/properties/views/property_screen.dart';
import 'package:marketplace_app/src/properties/views/public_profile_screen.dart';
import 'package:marketplace_app/src/search/views/search_screen.dart';
import 'package:marketplace_app/src/splashscreen/views/splashscreen_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GoRouter _router = GoRouter(
   navigatorKey: navigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        return const AppEntryPoint();
      },
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnBoardingScreen(),
    ),
    GoRoute(
      path: '/check-email',
      builder: (context, state) => const EmailSignupPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) {
        final String? prefilledEmail = state.extra != null ? (state.extra as Map<String, dynamic>)['email'] : null;
        return RegistrationPage(prefilledEmail: prefilledEmail);
      },
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: '/filter',
      builder: (context, state) => const FilterPage(),
    ),
    GoRoute(
      path: '/account',
      builder: (context, state) => const AccountPage(),
    ),
    GoRoute(
      path: '/update-email',
      builder: (context, state) => const UpdateEmailPage(),
    ),
    GoRoute(
      path: '/update-password',
      builder: (context, state) => const UpdatePasswordPage(),
    ),
    GoRoute(
      path: '/profile/verify-school-email',
      builder: (context, state) => const VerifySchoolEmailPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) {
        final String? prefilledEmail = state.extra != null ? (state.extra as Map<String, dynamic>)['email'] : null;
        return LoginPage(prefilledEmail: prefilledEmail);
      },
    ),
    GoRoute(
      path: '/login/mobile',
      builder: (context, state) => const MobileSignupPage(),
    ),
    GoRoute(
      path: '/login/mobile/otp',
      builder: (context, state) {
        final String mobileNumber = state.extra != null ? (state.extra as Map<String, dynamic>)['mobileNumber'] : null;
        return MobileOtpPage(mobileNumber: mobileNumber);
      },
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoriesPage(),
    ),
     GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/property/create',
      builder: (context, state) => const CreatePropertyPage(),
    ),
    GoRoute(
      path: '/property/:id',
      builder: (BuildContext context, GoRouterState state) {
        final propertyId = state.pathParameters['id'];
        return PropertyPage(propertyId: propertyId.toString());
      },
    ),
    GoRoute(
      path: '/public-profile',
      builder: (context, state) {
        final userId = state.extra as int;
        return PublicProfilePage(userId: userId);
      },
    ),
    GoRoute(
      path: '/my-listings/:userId',
      builder: (context, state) {
        final userId = int.parse(state.pathParameters['userId']!);
        return UserListingsPage(userId: userId);
      },
    ),
    GoRoute(
      path: '/my-listings/edit/:propertyId',
      builder: (context, state) {
        final propertyId = state.pathParameters['propertyId']!;
        return PropertyEditPage(propertyId: propertyId);
      },
    ),
    GoRoute(
      path: '/my-marketplace/:userId',
      builder: (context, state) {
        final userId = int.parse(state.pathParameters['userId']!);
        return UserMarketplaceListingsPage(userId: userId);
      },
    ),
    GoRoute(
      path: '/marketplace/create',
      builder: (context, state) => const CreateMarketplacePage(),
    ),
    GoRoute(
      path: '/marketplace/:itemId',
      builder: (context, state) {
        final itemId = state.pathParameters['itemId']!;
        return MarketplaceDetailScreen(itemId: itemId);
      },
    ),
    GoRoute(
      path: '/marketplace/edit/:itemId',
      builder: (context, state) {
        final itemId = state.pathParameters['itemId']!;
        return CreateMarketplacePage(
          isEditing: true,
          itemId: itemId,
        );
      },
    ),
    GoRoute(
      path: '/marketplace/search',
      builder: (context, state) => const MarketplaceSearchPage(),
    ),
    GoRoute(
      path: '/marketplace/filter',
      builder: (context, state) => const MarketplaceFilterPage(),
    ),
  ],
);

GoRouter get router => _router;
