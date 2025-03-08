import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/src/auth/views/mobile_signup_screen.dart';
import 'package:marketplace_app/src/home/controllers/home_tab_notifier.dart';
import 'package:marketplace_app/src/home/services/location_service.dart';
import 'package:marketplace_app/src/home/widgets/custom_app_bar.dart';
import 'package:marketplace_app/src/home/widgets/home_header.dart';
import 'package:marketplace_app/src/home/widgets/home_slider.dart';
import 'package:marketplace_app/src/home/widgets/home_tabs.dart';
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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin{
  // late final TabController _tabController;

  // int _currentTabIndex = 0;

  @override
  void initState() {
     super.initState();
    // _tabController = TabController(length: homeTabs.length, vsync: this);
    // _tabController.addListener(_handleSelection);
    _getLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyNotifier>().fetchProperties();
    });
  }

  // void _handleSelection() {
  //   final controller = Provider.of<HomeTabNotifier>(context, listen: false);
  //   final propertyNotifier = Provider.of<PropertyNotifier>(context, listen: false);

  //   if(_tabController.indexIsChanging) {
  //     setState(() {
  //       _currentTabIndex = _tabController.index;
  //     });
  //     controller.setIndex(homeTabs[_currentTabIndex], propertyNotifier);
  //   }
  // }

  // @override
  // void dispose() {
  //   _tabController.removeListener(_handleSelection);
  //   _tabController.dispose();
  //   super.dispose();
  // }

  void _getLocation() async {
    await Geolocator.checkPermission();
    await Geolocator.requestPermission();

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
    
    // final homeTabNotifier = Provider.of<HomeTabNotifier>(context, listen: false);
    // homeTabNotifier.setUserLocation(position.latitude, position.longitude);
  }

  @override
  Widget build(BuildContext context) {
    String? accessToken = Storage().getString('accessToken');
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 60.h),
        child: const CustomAppBar()
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        children: [
          // HomeTabs(tabController: _tabController),

          // SizedBox(
          //   height: 15.h,
          // ),

          ExploreProperties(filteredProperties: widget.filteredProperties),

          SizedBox(
            height: 100.h,
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 48.w),
        child: FloatingActionButton(
          // onTap: () {
          //   context.read<PropertyNotifier>().setProperty(property);
          //   context.push('/property/${property.id}');
          // },
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

List<String> homeTabs = [
  'All',
  'School',
  'Nearby',
];