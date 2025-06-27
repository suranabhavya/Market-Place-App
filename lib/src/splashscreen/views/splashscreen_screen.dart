import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/const/resource.dart';
import 'package:marketplace_app/src/properties/controllers/property_notifier.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

	@override
	void initState() {
		super.initState();
		_navigator();
	}

	_navigator() async {
		// Preload properties data during splash screen
		// Use addPostFrameCallback to avoid calling setState during build
		WidgetsBinding.instance.addPostFrameCallback((_) {
			try {
				debugPrint("SplashScreen: Starting properties preload...");
				final propertyNotifier = context.read<PropertyNotifier>();
				// Start the API call without waiting for it to complete
				// This allows the splash screen to show for 3 seconds while data loads in background
				propertyNotifier.fetchProperties().catchError((error) {
					debugPrint("SplashScreen: Error preloading properties: $error");
				});
			} catch (e) {
				debugPrint("SplashScreen: Exception during properties preload: $e");
			}
		});

		// Wait for the splash screen duration
		await Future.delayed(const Duration(milliseconds: 3000));
		
		// Check if widget is still mounted before using context
		if (!mounted) return;
		
		if (Storage().getBool('firstOpen') == null) {
			// Go to the onboarding screen
			GoRouter.of(context).go('/onboarding');
		} else {
			// Go to the Home Page
			GoRouter.of(context).go('/home');
		}
	}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Kolors.kWhite,
      body: Container(
				width: MediaQuery.of(context).size.width,
				height: MediaQuery.of(context).size.height,
				decoration: const BoxDecoration(
					image: DecorationImage(image: AssetImage(R.ASSETS_IMAGES_SPLASHSCREEN_PNG))
				),
				
			)
    );
  }
}