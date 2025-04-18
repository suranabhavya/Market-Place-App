import 'package:flutter/material.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/src/properties/views/create_property_screen.dart';
import 'package:marketplace_app/src/properties/services/property_service.dart';

class PropertyEditPage extends StatefulWidget {
  final String propertyId;

  const PropertyEditPage({super.key, required this.propertyId});

  @override
  State<PropertyEditPage> createState() => _PropertyEditPageState();
}

class _PropertyEditPageState extends State<PropertyEditPage> {
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? propertyData;

  @override
  void initState() {
    super.initState();
    _fetchPropertyDetails();
  }

  Future<void> _fetchPropertyDetails() async {
    try {
      propertyData = await PropertyService.fetchProperty(widget.propertyId);
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: Text(
            "Edit Property",
            style: appStyle(15, Kolors.kPrimary, FontWeight.bold),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage!),
              ElevatedButton(
                onPressed: _fetchPropertyDetails,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (propertyData == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: Text(
            "Edit Property",
            style: appStyle(15, Kolors.kPrimary, FontWeight.bold),
          ),
        ),
        body: const Center(
          child: Text("No property data available"),
        ),
      );
    }

    return CreatePropertyPage(
      isEditing: true,
      propertyId: widget.propertyId,
      initialData: propertyData,
    );
  }
}