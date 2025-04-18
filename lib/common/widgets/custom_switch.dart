import 'package:flutter/material.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';

class CustomSwitch extends StatelessWidget {
  final bool value;
  final void Function(bool)? onChanged;
  final String label;
  final bool isRequired;

  const CustomSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: appStyle(14, Kolors.kPrimary, FontWeight.bold),
            ),
            if (isRequired)
              const Text(
                " *",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Kolors.kPrimary,
            inactiveThumbColor: Colors.grey,
          ),
        ),
      ],
    );
  }
} 