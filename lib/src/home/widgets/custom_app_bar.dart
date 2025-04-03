import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/src/filter/controllers/filter_notifier.dart';
import 'package:provider/provider.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final filterNotifier = Provider.of<FilterNotifier>(context);
    final String searchText = filterNotifier.searchKey.isNotEmpty 
        ? filterNotifier.searchKey 
        : "Search University, Pin Code, Address, City";
    
    // Check if using location-based search
    final bool isLocationSearch = filterNotifier.searchKey == "Properties Near Me" && 
                                  filterNotifier.latitude != null && 
                                  filterNotifier.longitude != null;
    
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      title: PreferredSize(
        preferredSize: Size.fromHeight(55.h),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.h, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  context.push('/search');
                },
                child: Padding(
                  padding: EdgeInsets.only(left: 6.w),
                  child: Container(
                    height: 40.h,
                    width: ScreenUtil().screenWidth - 100,
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 0.5,
                        color: Kolors.kGrayLight,
                      ),
                      borderRadius: BorderRadius.circular(24)
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      child: Row(
                        children: [
                          Icon(
                            isLocationSearch ? Icons.location_on : Ionicons.search, 
                            size: 20, 
                            color: Kolors.kPrimaryLight
                          ),
                          
                          SizedBox(width: 10.w),
                          
                          Expanded(
                            child: Text(
                              searchText,
                              style: appStyle(14, Kolors.kGray, FontWeight.w400),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          // Show clear button if there's search text
                          if (filterNotifier.searchKey.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                filterNotifier.clearSearch();
                                filterNotifier.resetLocation();
                                filterNotifier.applyFilters(context);
                              },
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Kolors.kGray,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Filter Button
              GestureDetector(
                onTap: () {
                  context.push('/filter');
                },
                child: Container(
                  height: 40.h,
                  width: 40.w,
                  decoration: BoxDecoration(
                    color: Kolors.kPrimary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    FontAwesome.sliders,
                    color: Kolors.kWhite,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        )
      ),
    );
  }
}