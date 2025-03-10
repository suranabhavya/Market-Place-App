import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:table_calendar/table_calendar.dart';

class SelectDurationPage extends StatefulWidget {
  final DateTime? initialFromDate;
  final DateTime? initialToDate;

  const SelectDurationPage({super.key, this.initialFromDate, this.initialToDate});

  @override
  State<SelectDurationPage> createState() => _SelectDurationPageState();
}

class _SelectDurationPageState extends State<SelectDurationPage> {
  DateTime? checkInDate;
  DateTime? checkOutDate;
  final CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    checkInDate = widget.initialFromDate;
    checkOutDate = widget.initialToDate;
  }

  void _resetDates() {
    setState(() {
      checkInDate = null;
      checkOutDate = null;
    });
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
          style: appStyle(15, Kolors.kPrimary, FontWeight.bold)
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Check-in
                GestureDetector(
                  onTap: () => setState(() => checkOutDate = null),
                  child: Column(
                    children: [
                      const Text("Move-in"),
                      Text(
                        formattedCheckIn,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_right_alt, size: 24),
                // Check-out
                GestureDetector(
                  onTap: () => {
                    if (checkInDate != null) {
                      setState(() => checkOutDate = null)
                    }
                  },
                  child: Column(
                    children: [
                      const Text("Move-out"),
                      Text(
                        formattedCheckOut,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Calendar
          Expanded(
            child: Padding(
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
                    color: Kolors.kPrimary.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Kolors.kPrimary,
                    shape: BoxShape.circle,
                  ),
                  rangeHighlightColor: Kolors.kPrimary.withOpacity(0.3),
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
          ),
          // Fixed Buttons at the Bottom
          SafeArea(
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
                        Navigator.pop(context, {
                          "fromDate": checkInDate,
                          "toDate": checkOutDate,
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
        ],
      ),
    );
  }
}