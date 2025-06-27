import 'package:flutter/material.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/utils/amenity_emoji_map.dart';

class AmenityChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon; // Made optional since we'll use emoji

  const AmenityChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon, // Made optional
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Kolors.kPrimary.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? Kolors.kPrimary : Colors.grey.shade300,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AmenityEmojiMap.getEmoji(label),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: appStyle(
                12,
                isSelected ? Kolors.kPrimary : Colors.grey.shade600,
                FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 