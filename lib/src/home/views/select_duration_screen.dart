import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:table_calendar/table_calendar.dart';

class SelectDurationPage extends StatefulWidget {
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final String? initialFlexibility;

  const SelectDurationPage({
    super.key, 
    this.initialFromDate, 
    this.initialToDate, 
    this.initialFlexibility,
  });

  @override
  State<SelectDurationPage> createState() => _SelectDurationPageState();
}

class _SelectDurationPageState extends State<SelectDurationPage> {
  DateTime? checkInDate;
  DateTime? checkOutDate;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  String selectedFlexibility = "Exact dates"; // Default to exact dates

  @override
  void initState() {
    super.initState();
    checkInDate = widget.initialFromDate;
    checkOutDate = widget.initialToDate;
    selectedFlexibility = widget.initialFlexibility ?? "Exact dates";
  }

  void _resetDates() {
    setState(() {
      checkInDate = null;
      checkOutDate = null;
      selectedFlexibility = "Exact dates";
    });
  }

  int _getFlexibilityDays(String flexibility) {
    if (flexibility == "Exact dates") return 0;
    
    // Extract number from strings like "± 1 day", "± 2 days", etc.
    final regex = RegExp(r'± (\d+) day');
    final match = regex.firstMatch(flexibility);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 0;
  }

  Map<String, DateTime?> _calculateActualDateRange() {
    if (checkInDate == null) {
      return {"actualFromDate": null, "actualToDate": null};
    }

    final flexibilityDays = _getFlexibilityDays(selectedFlexibility);
    
    // For backend filtering:
    // - available_from <= user_search_from (property can start earlier or same day)
    // - available_to >= user_search_to (property can end later or same day)
    // 
    // So with flexibility:
    // - user_search_from = move-in + flexibility (willing to move in later)
    // - user_search_to = move-out - flexibility (willing to move out earlier)
    final actualFromDate = checkInDate!.add(Duration(days: flexibilityDays));
    final actualToDate = checkOutDate?.subtract(Duration(days: flexibilityDays)); // Don't set actualToDate if no checkout date is selected

    return {
      "actualFromDate": actualFromDate,
      "actualToDate": actualToDate,
    };
  }

  void _onDaySelected(DateTime selectedDay) {
    setState(() {
      if (checkInDate == null || (checkInDate != null && checkOutDate != null)) {
        checkInDate = selectedDay;
        checkOutDate = null; // Reset checkout to force user to select it after check-in
      } else if (selectedDay.isAfter(checkInDate!)) {
        checkOutDate = selectedDay;
      } else {
        checkInDate = selectedDay;
        checkOutDate = null; // Reset checkout if selecting an earlier check-in date
      }
    });
  }

  Widget _buildFlexibilityChip(String label) {
    final bool isSelected = selectedFlexibility == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFlexibility = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? Kolors.kPrimary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? Kolors.kPrimary : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: appStyle(
            14,
            isSelected ? Kolors.kWhite : Kolors.kDark,
            FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedCheckIn = checkInDate != null ? DateFormat('E, MMM dd').format(checkInDate!) : "Select";
    String formattedCheckOut = checkOutDate != null ? DateFormat('E, MMM dd').format(checkOutDate!) : "Select";

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(
          onTap: () {
            Navigator.pop(context);
          },
        ),
        title: ReusableText(
          text: AppText.kSelectDuration,
          style: appStyle(16, Kolors.kPrimary, FontWeight.bold)
        ),
      ),
      body: Column(
        children: [
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 10.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Check-in
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => checkOutDate = null),
                            child: Column(
                              children: [
                                Text(
                                  "Move-in",
                                  style: appStyle(14, Kolors.kPrimary, FontWeight.w400),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  formattedCheckIn,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: const Icon(Icons.arrow_right_alt, size: 24),
                        ),
                        // Check-out
                        Expanded(
                          child: GestureDetector(
                            onTap: () => {
                              if (checkInDate != null) {
                                setState(() => checkOutDate = null)
                              }
                            },
                            child: Column(
                              children: [
                                Text(
                                  "Move-out",
                                  style: appStyle(14, Kolors.kPrimary, FontWeight.w400),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  formattedCheckOut,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Calendar with fixed height
                  Container(
                    height: 400.h, // Fixed height for calendar
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 365)), // 1 year ahead
                      focusedDay: checkInDate ?? DateTime.now(),
                      calendarFormat: _calendarFormat,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Month',
                      },

                      rangeStartDay: checkInDate,
                      rangeEndDay: checkOutDate,
                      onDaySelected: (selectedDay, _) => _onDaySelected(selectedDay),

                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Kolors.kPrimary.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: Kolors.kPrimary,
                          shape: BoxShape.circle,
                        ),
                        rangeHighlightColor: Kolors.kPrimary.withValues(alpha: 0.3),
                        rangeStartDecoration: const BoxDecoration(
                          color: Kolors.kPrimary,
                          shape: BoxShape.circle,
                        ),
                        rangeEndDecoration: const BoxDecoration(
                          color: Kolors.kPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: appStyle(16, Kolors.kDark, FontWeight.bold),
                      ),
                    ),
                  ),
                  // Flexibility Options
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Date Flexibility",
                          style: appStyle(16, Kolors.kDark, FontWeight.w600),
                        ),
                        SizedBox(height: 8.h),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFlexibilityChip("Exact dates"),
                              SizedBox(width: 8.w),
                              _buildFlexibilityChip("± 1 day"),
                              SizedBox(width: 8.w),
                              _buildFlexibilityChip("± 2 days"),
                              SizedBox(width: 8.w),
                              _buildFlexibilityChip("± 3 days"),
                              SizedBox(width: 8.w),
                              _buildFlexibilityChip("± 7 days"),
                              SizedBox(width: 8.w),
                              _buildFlexibilityChip("± 14 days"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 80.h), // Extra space to ensure buttons aren't covered
                ],
              ),
            ),
          ),
          // Fixed Buttons at the Bottom
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _resetDates,
                        style: TextButton.styleFrom(backgroundColor: Colors.grey[200]),
                        child: Text(
                          "Reset All",
                          style: appStyle(15, Kolors.kPrimary, FontWeight.bold)
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final actualDateRange = _calculateActualDateRange();
                          Navigator.pop(context, {
                            "fromDate": checkInDate,
                            "toDate": checkOutDate,
                            "actualFromDate": actualDateRange["actualFromDate"],
                            "actualToDate": actualDateRange["actualToDate"],
                            "flexibility": selectedFlexibility,
                            "flexibilityDays": _getFlexibilityDays(selectedFlexibility),
                          });
                        },
                        style: TextButton.styleFrom(backgroundColor: Kolors.kPrimary),
                        child: Text(
                          "Confirm",
                          style: appStyle(15, Kolors.kWhite, FontWeight.bold)
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}