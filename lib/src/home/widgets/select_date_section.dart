import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/src/filter/controllers/filter_notifier.dart';
import 'package:marketplace_app/src/home/views/select_duration_screen.dart';
import 'package:provider/provider.dart';

class SelectDateSection extends StatefulWidget {
  const SelectDateSection({super.key});

  @override
  State<SelectDateSection> createState() => _SelectDateSectionState();
}

class _SelectDateSectionState extends State<SelectDateSection> {
  DateTime? fromDate;
  DateTime? toDate;

  void _selectDuration() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectDurationPage(
          initialFromDate: context.read<FilterNotifier>().availableFrom,
          initialToDate: context.read<FilterNotifier>().availableTo,
        ),
      ),
    );

    if (result != null) {
      final filterNotifier = context.read<FilterNotifier>();
      filterNotifier.setMoveInDate(result["fromDate"]);
      filterNotifier.setMoveOutDate(result["toDate"]);
      filterNotifier.applyFilters(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filterNotifier = context.watch<FilterNotifier>();

    String formattedFromDate = filterNotifier.availableFrom != null
        ? DateFormat('E, MMM dd').format(filterNotifier.availableFrom!)
        : "Move-In";
    String formattedToDate = filterNotifier.availableTo != null
        ? DateFormat('E, MMM dd').format(filterNotifier.availableTo!)
        : "Move-Out";

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
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
                  border: Border.all(width: 0.5, color: Kolors.kGrayLight),
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
                        style: filterNotifier.availableFrom == null
                            ? appStyle(14, Kolors.kGray, FontWeight.w400)
                            : appStyle(14, Kolors.kDark, FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          // To Date
          Expanded(
            child: GestureDetector(
              onTap: _selectDuration,
              child: Container(
                height: 40.h,
                decoration: BoxDecoration(
                  border: Border.all(width: 0.5, color: Kolors.kGrayLight),
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
                        style: filterNotifier.availableTo == null
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
    );
  }
}