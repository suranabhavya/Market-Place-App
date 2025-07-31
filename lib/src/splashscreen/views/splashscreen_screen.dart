import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/auth_service.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/debug_utils.dart';
import 'package:marketplace_app/const/resource.dart';
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
			duration: const Duration(milliseconds: 2000),
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
											// SVG Logo with responsive sizing
											SvgPicture.asset(
												R.ASSETS_ICONS_COMPANY_LOGO_SVG,
												width: ScreenUtil().screenWidth * 0.25, // 25% of screen width (reduced from 30%)
												height: ScreenUtil().screenWidth * 0.29, // Maintain aspect ratio (798/694 ≈ 1.15)
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