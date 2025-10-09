import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:marketplace_app/common/services/push_notification_service.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/app_routes.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/src/auth/controllers/auth_notifier.dart';
import 'package:marketplace_app/src/auth/controllers/password_notifier.dart';
import 'package:marketplace_app/src/entrypoint/controllers/bottom_tab_notifier.dart';
import 'package:marketplace_app/src/entrypoint/controllers/unread_count_notifier.dart';
import 'package:marketplace_app/src/filter/controllers/filter_notifier.dart';
import 'package:marketplace_app/src/home/controllers/home_tab_notifier.dart';
import 'package:marketplace_app/src/marketplace/controllers/marketplace_notifier.dart';
import 'package:marketplace_app/src/profile/controllers/profile_notifier.dart';
import 'package:marketplace_app/src/properties/controllers/property_notifier.dart';
import 'package:marketplace_app/src/search/controllers/search_notifier.dart';
import 'package:marketplace_app/src/splashscreen/views/splashscreen_screen.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:provider/provider.dart';


// Define background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase here if needed
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set the background message handler (APNS is now configured)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: Environment.firebaseWebApiKey,
        appId: Environment.firebaseWebAppId,
        messagingSenderId: Environment.firebaseMessagingSenderId,
        projectId: Environment.firebaseProjectId,
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  await dotenv.load(fileName: 'assets/.env.development');
  
  // Initialize notification handlers only (but NOT permission or token)
  await PushNotificationService().initializeHandlersOnly();

  await Storage.initialize();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => TabIndexNotifier()),
      ChangeNotifierProvider(create: (_) => PasswordNotifier()),
      ChangeNotifierProvider(create: (_) => HomeTabNotifier()),
      ChangeNotifierProvider(create: (_) => PropertyNotifier()),
      ChangeNotifierProvider(create: (_) => MarketplaceNotifier()),
      ChangeNotifierProvider(create: (_) => AuthNotifier()),
      ChangeNotifierProvider(create: (_) => SearchNotifier()),
      ChangeNotifierProvider(create: (_) => FilterNotifier()),
      ChangeNotifierProvider(create: (_) => WishlistNotifier()),
      ChangeNotifierProvider(create: (_) => ProfileNotifier()),
      ChangeNotifierProvider(create: (_) => UnreadCountNotifier()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return ScreenUtilInit(
      designSize: screenSize,
      minTextAdapt: true,
      splitScreenMode: false,
      useInheritedMediaQuery: true,
      builder: (_, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: AppText.kAppName,
          theme: ThemeData(
            // Use a custom color scheme with white background
            colorScheme: const ColorScheme.light(
              primary: Kolors.kPrimary,
              secondary: Kolors.kSecondaryLight,
              surface: Colors.white,
            ),
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
            ),
            useMaterial3: true,
          ),
          routerConfig: router,
        );
      },
      child: const SplashScreen(),
    );
  }
}
