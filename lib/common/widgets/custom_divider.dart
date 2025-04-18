import 'package:flutter/material.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';

class CustomDivider extends StatelessWidget {
  final double height;
  final double thickness;
  final Color? color;
  final double? indent;
  final double? endIndent;

  const CustomDivider({
    super.key,
    this.height = 1,
    this.thickness = 1,
    this.color,
    this.indent,
    this.endIndent,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      thickness: thickness,
      color: color ?? Kolors.kPrimary.withOpacity(0.1),
      indent: indent,
      endIndent: endIndent,
    );
  }
} 