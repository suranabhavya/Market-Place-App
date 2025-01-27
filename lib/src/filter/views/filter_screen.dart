import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/main.dart';
import 'package:marketplace_app/src/filter/controllers/filter_notifier.dart';
import 'package:provider/provider.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  double minRentValue = 0;
  double maxRentValue = 50000;
  late TextEditingController _minRentController;
  late TextEditingController _maxRentController;

  @override
  void initState() {
    super.initState();
    final filterNotifier = Provider.of<FilterNotifier>(context, listen: false);
    minRentValue = filterNotifier.priceRange.start;
    maxRentValue = filterNotifier.priceRange.end;
    _minRentController = TextEditingController(text: filterNotifier.priceRange.start.toInt().toString());
    _maxRentController = TextEditingController(text: filterNotifier.priceRange.end.toInt().toString());
  }

  @override
  void dispose() {
    _minRentController.dispose();
    _maxRentController.dispose();
    super.dispose();
  }

  void _applyFilters(FilterNotifier filterNotifier) {
    final double? minRent = double.tryParse(_minRentController.text);
    final double? maxRent = double.tryParse(_maxRentController.text);

    if (minRent == null || maxRent == null || minRent > maxRent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter valid rent values"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    filterNotifier.setPriceRange(RangeValues(minRent, maxRent));
    filterNotifier.applyFilters(context);
  }

  @override
  Widget build(BuildContext context) {
    final filterNotifier = Provider.of<FilterNotifier>(context);
    
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(
          onTap: () {
            context.pop();
          },
        ),
        title: ReusableText(
          text: AppText.kFilter,
          style: appStyle(15, Kolors.kPrimary, FontWeight.bold)
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Rent Range"),
            RangeSlider(
              values: filterNotifier.priceRange,
              min: 0,
              max: 50000,
              activeColor: Kolors.kPrimary,
              onChanged: (values) {
                setState(() {
                  minRentValue = values.start;
                  maxRentValue = values.end;
                  _minRentController.text = values.start.toInt().toString();
                  _maxRentController.text = values.end.toInt().toString();
                });
              },
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: "Min Rent"),
                    controller: _minRentController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final newValue = double.tryParse(value) ?? 0;
                      setState(() {
                        minRentValue = newValue;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: "Max Rent"),
                    controller: _maxRentController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final newValue = double.tryParse(value) ?? 50000;
                      setState(() {
                        maxRentValue = newValue;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField(
                    value: filterNotifier.selectedBedrooms,
                    onChanged: (value) {
                      filterNotifier.setBedrooms(value.toString());
                    },
                    items: ['All', '1', '2', '3', '4', '5+']
                        .map((item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ))
                        .toList(),
                    decoration: const InputDecoration(labelText: "Bedrooms"),
                  ),
                  // child: _buildDropdown("Bedrooms", selectedBedrooms, ['All', '1', '2', '3', '4', '5+']),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField(
                    value: filterNotifier.selectedBathrooms,
                    onChanged: (value) {
                      filterNotifier.setBathrooms(value.toString());
                    },
                    items: ['All', '1', '2', '3', '4+']
                        .map((item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ))
                        .toList(),
                    decoration: const InputDecoration(labelText: "Bathrooms"),
                  ),
                  // child: _buildDropdown("Bathrooms", selectedBathrooms, ['All', '1', '2', '3', '4+']),
                ),
              ],
            ),

            const SizedBox(height: 20),
            
            const Divider(height: 30),

            // const Text("Must Haves"),

            // CheckboxListTile(
            //   title: const Text("Exclusive"),
            //   value: filterNotifier.exclusive,
            //   onChanged: (value) => filterNotifier.toggleExclusive(value!),
            // ),
            
            const Spacer(),
            
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      filterNotifier.resetFilters();
                      setState(() {
                        minRentValue = filterNotifier.priceRange.start;
                        maxRentValue = filterNotifier.priceRange.end;
                        _minRentController.text = minRentValue.toInt().toString();
                        _maxRentController.text = maxRentValue.toInt().toString();
                      });
                    },
                    child: const Text("Reset All"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (!filterNotifier.isLoading) {
                        _applyFilters(filterNotifier);
                      }
                    },
                    child: filterNotifier.isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Apply Filter"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildDropdown(String label, String value, List<String> options) {
  //   return DropdownButtonFormField<String>(
  //     value: value,
  //     onChanged: (newValue) {
  //       setState(() {
  //         if (label == "Bedrooms") {
  //           selectedBedrooms = newValue!;
  //         } else {
  //           selectedBathrooms = newValue!;
  //         }
  //       });
  //     },
  //     items: options.map((String option) {
  //       return DropdownMenuItem<String>(
  //         value: option,
  //         child: Text(option),
  //       );
  //     }).toList(),
  //     decoration: InputDecoration(labelText: label),
  //   );
  // }

  // Widget _buildCheckbox(String title, bool value, Function(bool?) onChanged) {
  //   return CheckboxListTile(
  //     title: Text(title),
  //     value: value,
  //     onChanged: onChanged,
  //   );
  // }
}