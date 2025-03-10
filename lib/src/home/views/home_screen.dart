import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/src/auth/views/mobile_signup_screen.dart';
import 'package:marketplace_app/src/filter/controllers/filter_notifier.dart';
import 'package:marketplace_app/src/home/controllers/home_tab_notifier.dart';
import 'package:marketplace_app/src/home/services/location_service.dart';
import 'package:marketplace_app/src/home/widgets/custom_app_bar.dart';
import 'package:marketplace_app/src/home/widgets/home_header.dart';
import 'package:marketplace_app/src/home/widgets/home_slider.dart';
import 'package:marketplace_app/src/home/widgets/home_tabs.dart';
import 'package:marketplace_app/src/home/widgets/select_date_section.dart';
import 'package:marketplace_app/src/properties/controllers/property_notifier.dart';
import 'package:marketplace_app/src/properties/models/property_list_model.dart';
import 'package:marketplace_app/src/properties/widgets/explore_properties.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  final List<PropertyListModel>? filteredProperties;

  const HomePage({super.key, this.filteredProperties});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    if (widget.filteredProperties == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<FilterNotifier>().applyFilters(context);
      });
    }
    _getLocation();
  }

  void _getLocation() async {
    await Geolocator.checkPermission();
    await Geolocator.requestPermission();

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
  }

  @override
  Widget build(BuildContext context) {
    String? accessToken = Storage().getString('accessToken');
    final filterNotifier = context.watch<FilterNotifier>();
    
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: CustomAppBar()
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        children: [
          const SelectDateSection(),

          filterNotifier.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ExploreProperties(filteredProperties: filterNotifier.filteredProperties),

          SizedBox(
            height: 100.h,
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 48.w),
        child: FloatingActionButton(
          onPressed: () {
            if (accessToken == null) {
              loginBottomSheet(context);
            } else {
              context.push("/property/create");
            }
          },
          backgroundColor: Kolors.kPrimary,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 32, color: Kolors.kWhite,),
        ),
      ),
    );
  }
}