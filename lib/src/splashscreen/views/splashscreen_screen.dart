import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/debug_utils.dart';
import 'package:marketplace_app/const/resource.dart';
import 'package:marketplace_app/src/marketplace/controllers/marketplace_notifier.dart';
import 'package:marketplace_app/src/properties/controllers/property_notifier.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
	late AnimationController _animationController;
	late Animation<double> _fadeAnimation;
	late Animation<double> _scaleAnimation;

	@override
	void initState() {
		super.initState();
		
		// Initialize animations for smooth logo appearance
		_animationController = AnimationController(
			duration: const Duration(milliseconds: 1500),
			vsync: this,
		);
		
		_fadeAnimation = Tween<double>(
			begin: 0.0,
			end: 1.0,
		).animate(CurvedAnimation(
			parent: _animationController,
			curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
		));
		
		_scaleAnimation = Tween<double>(
			begin: 0.8,
			end: 1.0,
		).animate(CurvedAnimation(
			parent: _animationController,
			curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
		));
		
		// Start animation
		_animationController.forward();
		
		_navigator();
	}

	@override
	void dispose() {
		_animationController.dispose();
		super.dispose();
	}

	_navigator() async {
		// Add debugging for Android storage issues
		DebugUtils.logStorageState();
		DebugUtils.logAuthenticationState();
		
		// Preload properties and marketplace data during splash screen
		// Start property loading first, then marketplace items sequentially
		Future<void> dataLoadingFuture = Future.value();
		try {
			debugPrint("SplashScreen: Starting data preload...");
			final propertyNotifier = context.read<PropertyNotifier>();
			final marketplaceNotifier = context.read<MarketplaceNotifier>();
			
			// Sequential loading: properties first, then marketplace items
			dataLoadingFuture = propertyNotifier.fetchProperties()
				.then((_) {
					debugPrint("SplashScreen: Properties loaded, now loading marketplace items...");
					return marketplaceNotifier.refreshMarketplaceItems();
				})
				.then((_) {
					debugPrint("SplashScreen: All data preloading completed");
				})
				.catchError((error) {
					debugPrint("SplashScreen: Error during data preload: $error");
				});
		} catch (e) {
			debugPrint("SplashScreen: Exception during data preload: $e");
		}

		// Wait for both splash screen duration and data loading to complete
		await Future.wait([
			Future.delayed(const Duration(milliseconds: 3000)),
			dataLoadingFuture,
		]);
		
		// Check if widget is still mounted before using context
		if (!mounted) return;

		// Check if this is the first time opening the app
		final firstOpen = Storage().getBool('firstOpen');
		debugPrint("SplashScreen: firstOpen value: $firstOpen");
		
		if (firstOpen == null) {
			debugPrint("SplashScreen: First time opening app - going to onboarding");
			// First time opening app - go to onboarding
			GoRouter.of(context).go('/onboarding');
		} else {
			debugPrint("SplashScreen: Not first time - going to home");
			// Not first time - always go to home screen
			// Home screen will handle authentication state internally
			GoRouter.of(context).go('/home');
		}
	}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Kolors.kWhite,
      body: SizedBox(
				width: MediaQuery.of(context).size.width,
				height: MediaQuery.of(context).size.height,
				child: Center(
					child: AnimatedBuilder(
						animation: _animationController,
						builder: (context, child) {
							return Transform.scale(
								scale: _scaleAnimation.value,
								child: Opacity(
									opacity: _fadeAnimation.value,
									child: Column(
										mainAxisAlignment: MainAxisAlignment.center,
										children: [
											// PNG Logo with responsive sizing
											Image.asset(
												R.ASSETS_ICONS_COMPANY_LOGO_PNG,
												width: ScreenUtil().screenWidth * 0.35,
												height: ScreenUtil().screenWidth * 0.35,
												fit: BoxFit.contain,
											),
										],
									),
								),
							);
						},
					),
				),
			),
    );
  }
}