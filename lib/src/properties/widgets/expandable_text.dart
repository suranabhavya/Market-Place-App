import 'package:flutter/material.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/src/entrypoint/views/entrypoint.dart';
import 'package:marketplace_app/src/properties/controllers/property_notifier.dart';
import 'package:provider/provider.dart';

class ExpandableText extends StatelessWidget {
  const ExpandableText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          textAlign: TextAlign.justify,
          maxLines: !context.watch<PropertyNotifier>().description ? 6 : null,
          style: appStyle(13, Kolors.kGray, FontWeight.normal),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: () {
                context.read<PropertyNotifier>().setDescription();
              },

              child: Text(
                !context.watch<PropertyNotifier>().description ? "View More" : "View Less",
                style: appStyle(11, Kolors.kPrimaryLight, FontWeight.normal),
              ),
            )
          ],
        )
      ],
    );
  }
}