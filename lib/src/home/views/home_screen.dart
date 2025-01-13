import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/src/auth/views/mobile_signup_screen.dart';
import 'package:marketplace_app/src/home/controllers/home_tab_notifier.dart';
import 'package:marketplace_app/src/home/widgets/custom_app_bar.dart';
import 'package:marketplace_app/src/home/widgets/home_header.dart';
import 'package:marketplace_app/src/home/widgets/home_slider.dart';
import 'package:marketplace_app/src/home/widgets/home_tabs.dart';
import 'package:marketplace_app/src/properties/widgets/explore_properties.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin{
  late final TabController _tabController;

  int _currentTabIndex = 0;

  @override
  void initState() {
    _tabController = TabController(length: homeTabs.length, vsync: this);

    _tabController.addListener(_handleSelection);
    super.initState();
  }

  void _handleSelection() {
    final controller = Provider.of<HomeTabNotifier>(context, listen: false);

    if(_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
      controller.setIndex(homeTabs[_currentTabIndex]);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: CustomAppBar()
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        children: [
          // SizedBox(
          //   height: 20.h,
          // ),

          // const HomeSlider(),

          // SizedBox(
          //   height: 15.h,
          // ),

          // const HomeHeader(),

          HomeTabs(tabController: _tabController),

          SizedBox(
            height: 15.h,
          ),

          const ExploreProperties(),

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
            print("Floating Action Button Pressed");
            context.push("/property/create");
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
  'Popular',
  'Nearby',
];