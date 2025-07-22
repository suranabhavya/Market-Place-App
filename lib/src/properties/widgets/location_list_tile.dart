import 'package:flutter/material.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';

class LocationListTile extends StatelessWidget {
  const LocationListTile({
    super.key,
    required this.location,
    required this.press,
  });

  final String location;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: press,
          horizontalTitleGap: 0,
          title: Text(
            location,
            style: appStyle(12, Kolors.kDark, FontWeight.normal)
          ),
        ),
        // const Divider(
        //   height: 2,
        //   thickness: 2,
        //   color: Kolors.kPrimary,
        // ),
      ],
    );
  }
}