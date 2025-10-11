import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/services/data_preload_service.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/const/resource.dart';
import 'package:marketplace_app/src/filter/controllers/filter_notifier.dart';
import 'package:marketplace_app/src/marketplace/controllers/marketplace_notifier.dart';
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

		// Start navigation timer (2s splash)
		_navigator();

		// Start background preload in parallel (non-blocking)
		_startBackgroundPreload();
	}

	/// Start background data preload during splash animation
	/// This runs in parallel with the 2s splash timer and does not block navigation
	void _startBackgroundPreload() {
		try {
			final filterNotifier = context.read<FilterNotifier>();
			final marketplaceNotifier = context.read<MarketplaceNotifier>();

			// Start preloading properties and marketplace (non-blocking for navigation)
			// This will continue in background even if navigation happens at 2s
			DataPreloadService().preloadAll(filterNotifier, marketplaceNotifier);
		} catch (e) {
			debugPrint('Failed to start background preload: $e');
			// Don't crash app if preload fails - screens will load data normally
		}
	}

	@override
	void dispose() {
		_animationController.dispose();
		super.dispose();
	}

	_navigator() async {
		// Wait only for minimum splash screen duration
		await Future.delayed(const Duration(milliseconds: 2000));
		
		// Check if widget is still mounted before using context
		if (!mounted) return;

		final firstOpen = Storage().getBool('firstOpen');
		
		if (firstOpen == null) {
			GoRouter.of(context).go('/onboarding');
		} else {
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