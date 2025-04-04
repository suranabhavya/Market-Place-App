import 'package:flutter/material.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';

class SearchableMultiSelectDropdown extends StatefulWidget {
  final String title;
  final List<String> options;
  final List<String> selectedValues;
  final Function(List<String>) onSelectionChanged;
  final String hintText;
  final Function(String)? onSearch;
  final ScrollController? scrollController;
  final bool isLoading;

  const SearchableMultiSelectDropdown({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.onSelectionChanged,
    required this.hintText,
    this.onSearch,
    this.scrollController,
    this.isLoading = false,
  });

  @override
  State<SearchableMultiSelectDropdown> createState() =>
      _SearchableMultiSelectDropdownState();
}

class _SearchableMultiSelectDropdownState
    extends State<SearchableMultiSelectDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _filteredOptions = [];
  bool _dropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
    _searchController.addListener(_filterOptions);
  }

  @override
  void didUpdateWidget(SearchableMultiSelectDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options != widget.options) {
      setState(() {
        _filteredOptions = widget.options;
      });
    }
  }

  void _filterOptions() {
    if (widget.onSearch != null) {
      widget.onSearch!(_searchController.text);
    } else {
      setState(() {
        _filteredOptions = widget.options
            .where((option) => option
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();
      });
    }
  }

  void _toggleSelection(String option) {
    List<String> updatedSelection = List.from(widget.selectedValues);
    if (updatedSelection.contains(option)) {
      updatedSelection.remove(option);
    } else {
      updatedSelection.add(option);
    }
    widget.onSelectionChanged(updatedSelection);
  }

  void _removeSelection(String option) {
    List<String> updatedSelection = List.from(widget.selectedValues);
    updatedSelection.remove(option);
    widget.onSelectionChanged(updatedSelection);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _dropdownOpen = !_dropdownOpen;
              if (_dropdownOpen) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  _searchFocusNode.requestFocus();
                });
              }
            });
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
              hintStyle: appStyle(12, Kolors.kGray, FontWeight.normal),
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
                    style: appStyle(12, Kolors.kDark, FontWeight.normal),
                  ),
                ),
                Icon(_dropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        
        if (_dropdownOpen)
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: 100,
              maxHeight: MediaQuery.of(context).size.height * 0.3,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search ${widget.title}...',
                      hintStyle: appStyle(12, Kolors.kGray, FontWeight.normal),
                      prefixIcon: const Icon(Icons.search),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: appStyle(12, Kolors.kDark, FontWeight.normal),
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (widget.scrollController != null && 
                          !widget.isLoading &&
                          scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                        widget.onSearch?.call(_searchController.text);
                      }
                      return true;
                    },
                    child: ListView.builder(
                      shrinkWrap: true,
                      controller: widget.scrollController,
                      itemCount: _filteredOptions.length + (widget.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _filteredOptions.length) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                                ),
                              ),
                            ),
                          );
                        }
                        final option = _filteredOptions[index];
                        bool isSelected = widget.selectedValues.contains(option);
                        return InkWell(
                          onTap: () => _toggleSelection(option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                  color: isSelected ? Theme.of(context).primaryColor : Kolors.kPrimary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    option,
                                    overflow: TextOverflow.ellipsis,
                                    style: appStyle(12, Kolors.kPrimary, FontWeight.normal),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

        // **Display Selected Options Below**
        if (widget.selectedValues.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: widget.selectedValues.map((value) {
                return Chip(
                  label: Text(value),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeSelection(value),
                  backgroundColor: Colors.grey[200],
                  labelStyle: appStyle(12, Kolors.kPrimary, FontWeight.normal),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}