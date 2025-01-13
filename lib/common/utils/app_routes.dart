// ignore_for_file: unused_element

// import 'package:fashion/src/auth/views/login_page.dart';
// import 'package:fashion/src/auth/views/registration_page.dart';
// import 'package:fashion/src/auth/views/verification_page.dart';
// import 'package:fashion/src/categories/views/categories_page.dart';
// import 'package:fashion/src/categories/views/category_page.dart';
// import 'package:fashion/src/checkout/views/checkout_page.dart';
// import 'package:fashion/src/checkout/views/failed_payment.dart';
// import 'package:fashion/src/checkout/views/successful_payment.dart';
// import 'package:fashion/src/entrypoint/entrypoint.dart';
// import 'package:fashion/src/address/views/add_address.dart';
// import 'package:fashion/src/address/views/addresses_page.dart';
// import 'package:fashion/src/notifications/views/notification_page.dart';
// import 'package:fashion/src/notifications/views/tracking_page.dart';
// import 'package:fashion/src/profile/views/help_center.dart';
// import 'package:fashion/src/onboarding/onboarding_screen.dart';
// import 'package:fashion/src/profile/views/order_page.dart';
// import 'package:fashion/src/profile/views/policy_page.dart';
// import 'package:fashion/src/product/views/product_page.dart';
// import 'package:fashion/src/review/review_page.dart';
// import 'package:fashion/src/search/views/search_page.dart';
// import 'package:fashion/src/splashscreen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/src/auth/views/email_signup_screen.dart';
import 'package:marketplace_app/src/auth/views/login_screen.dart';
import 'package:marketplace_app/src/auth/views/mobile_signup_screen.dart';
import 'package:marketplace_app/src/auth/views/registration_screen.dart';
import 'package:marketplace_app/src/categories/views/categories_screen.dart';
import 'package:marketplace_app/src/entrypoint/views/entrypoint.dart';
import 'package:marketplace_app/src/notifications/views/notification_screen.dart';
import 'package:marketplace_app/src/onboarding/views/onboarding_screen.dart';
import 'package:marketplace_app/src/profile/views/orders_screen.dart';
import 'package:marketplace_app/src/profile/views/policy_screen.dart';
import 'package:marketplace_app/src/profile/views/shipping_address_screen.dart';
import 'package:marketplace_app/src/properties/views/create_property_screen.dart';
import 'package:marketplace_app/src/properties/views/property_screen.dart';
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
      builder: (context, state) => AppEntryPoint(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnBoardingScreen(),
    ),
    // GoRoute(
    //   path: '/review',
    //   builder: (context, state) => const ReviewsPage(),
    // ),
    GoRoute(
      path: '/policy',
      builder: (context, state) => const PolicyPage(),
    ),
    // GoRoute(
    //   path: '/verification',
    //   builder: (context, state) => const VerificationPage(),
    // ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchPage(),
    ),
    // GoRoute(
    //   path: '/help',
    //   builder: (context, state) => const HelpCenterPage(),
    // ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrdersPage(),
    ),
    // GoRoute(
    //   path: '/login',
    //   builder: (context, state) => const LoginPage(),
    // ),
    
    
    // GoRoute(
    //   path: '/login',
    //   builder: (context, state) => const LoginPage(),
    // ),

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
      path: '/login/email',
      builder: (context, state) => const EmailSignupPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) {
        final String? prefilledEmail = state.extra != null ? (state.extra as Map<String, dynamic>)['email'] : null;
        return RegistrationPage(prefilledEmail: prefilledEmail);
      },
    ),
    // GoRoute(
    //   path: '/register',
    //   builder: (context, state) => const RegistrationPage(),
    // ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoriesPage(),
    ),
    //  GoRoute(
    //   path: '/category',
    //   builder: (context, state) => const CategoryPage(),
    // ),

    // GoRoute(
    //   path: '/addaddress',
    //   builder: (context, state) => const AddAddress(),
    // ),

    GoRoute(
      path: '/addresses',
      builder: (context, state) => const ShippingAddress()
    ),

     GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),

    //  GoRoute(
    //   path: '/tracking',
    //   builder: (context, state) => const TrackOrderPage(),
    // ),

    // GoRoute(
    //   path: '/checkout',
    //   builder: (context, state) => const CheckoutPage(),
    // ),

    //   GoRoute(
    //   path: '/successful',
    //   builder: (context, state) => const SuccessfulPayment(),
    // ),

    //   GoRoute(
    //   path: '/failed',
    //   builder: (context, state) => const FailedPayment(),
    // ),

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
  ],
);

GoRouter get router => _router;
