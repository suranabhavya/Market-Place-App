import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/src/home/views/select_duration_screen.dart';

class CustomAppBar extends StatefulWidget {
  const CustomAppBar({super.key});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  DateTime? fromDate;
  DateTime? toDate;

  void _selectDuration() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectDurationPage(initialFromDate: fromDate, initialToDate: toDate),
      ),
    );

    if (result != null) {
      setState(() {
        fromDate = result["fromDate"];
        toDate = result["toDate"];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedFromDate = fromDate != null ? DateFormat('E, MMM dd').format(fromDate!) : "Available From";
    String formattedToDate = toDate != null ? DateFormat('E, MMM dd').format(toDate!) : "Available Till";

    return Column(
      children: [
        AppBar(
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
                          padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
                          child: Row(
                            children: [
                              const Icon(
                                Ionicons.search, 
                                size: 20, 
                                color: Kolors.kPrimaryLight
                              ),
                              
                              SizedBox(
                                width: 10.w,
                              ),
                              
                              Expanded(
                                child: Text(
                                  "Search University, Pin Code, Address, City", 
                                  style: appStyle(14, Kolors.kGray, FontWeight.w400),
                                  maxLines: 1, // Ensures it doesn't wrap to the next line
                                  overflow: TextOverflow.ellipsis, // Shows "..."
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
        ),
        // Date Selection Section
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // From Date
              Expanded(
                child: GestureDetector(
                  onTap: _selectDuration,
                  child: Container(
                    height: 40.h,
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 0.5,
                        color: Kolors.kGrayLight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18, color: Kolors.kPrimaryLight),
                          SizedBox(width: 12.w),
                          Text(
                            formattedFromDate,
                            style: fromDate == null
                                ? appStyle(14, Kolors.kGray, FontWeight.w400)
                                : appStyle(14, Kolors.kDark, FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 10.w), // Spacing between the two date containers

              // To Date
              Expanded(
                child: GestureDetector(
                  onTap: _selectDuration,
                  child: Container(
                    height: 40.h,
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 0.5,
                        color: Kolors.kGrayLight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18, color: Kolors.kPrimaryLight),
                          SizedBox(width: 12.w),
                          Text(
                            formattedToDate,
                            style: toDate == null
                                ? appStyle(14, Kolors.kGray, FontWeight.w400)
                                : appStyle(14, Kolors.kDark, FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}