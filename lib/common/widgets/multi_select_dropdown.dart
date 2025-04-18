import 'package:flutter/material.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';

class MultiSelectDropdown extends StatefulWidget {
  final String title;
  final List<String> options;
  final List<String> selectedValues;
  final Function(List<String>) onSelectionChanged;
  final String hintText;

  const MultiSelectDropdown({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.onSelectionChanged,
    required this.hintText,
  });

  @override
  State<MultiSelectDropdown> createState() => _MultiSelectDropdownState();
}

class _MultiSelectDropdownState extends State<MultiSelectDropdown> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _menuController,
      builder: (context, controller, child) {
        return InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Kolors.kPrimary, width: 1.5),
              ),
              hintText: widget.hintText,
              hintStyle: appStyle(14, Kolors.kGray, FontWeight.normal),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.selectedValues.isNotEmpty
                        ? widget.selectedValues.join(", ")
                        : widget.hintText,
                    overflow: TextOverflow.ellipsis,
                    style: appStyle(14, Kolors.kPrimary, FontWeight.normal),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        );
      },
      menuChildren: widget.options.map((option) {
        return InkWell(
          onTap: () {
            List<String> updatedSelection = List.from(widget.selectedValues);
            if (updatedSelection.contains(option)) {
              updatedSelection.remove(option);
            } else {
              updatedSelection.add(option);
            }
            widget.onSelectionChanged(updatedSelection);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.selectedValues.contains(option)
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: widget.selectedValues.contains(option)
                      ? Theme.of(context).primaryColor
                      : Kolors.kPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  option,
                  style: appStyle(14, Kolors.kPrimary, FontWeight.normal),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}