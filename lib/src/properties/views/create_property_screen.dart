import 'dart:io';

import 'package:flutter/material.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/src/properties/controllers/property_notifier.dart';
import 'package:marketplace_app/src/properties/models/autocomplete_prediction.dart';
import 'package:marketplace_app/src/properties/models/place_autocomplete_response.dart';
import 'package:marketplace_app/src/properties/widgets/location_list_tile.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

class CreatePropertyPage extends StatefulWidget {
  const CreatePropertyPage({super.key});

  @override
  State<CreatePropertyPage> createState() => _CreatePropertyPageState();
}

class _CreatePropertyPageState extends State<CreatePropertyPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for input fields
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _rentController = TextEditingController();
  final TextEditingController _squareFootageController = TextEditingController();
  final TextEditingController _bedroomsController = TextEditingController();
  final TextEditingController _bathroomsController = TextEditingController();

  // List to store selected images
  final List<File> _images = [];

  List<AutocompletePrediction>? placePredictions = [];

  // Dropdown values
  String listingType = 'rent';
  String rentFrequency = 'monthly';
  String propertyType = 'apartment';
  bool furnished = false;

  // Method to pick an image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedImage = await _picker.pickImage(source: source);
      if (pickedImage != null) {
        setState(() {
          _images.add(File(pickedImage.path));
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  // Method to remove an image
  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _rentController.dispose();
    _squareFootageController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    super.dispose();
  }

  Future<void> placeAutocomplete(String query) async {
    Uri uri = Uri.https(
      "maps.googleapis.com",
      "maps/api/place/autocomplete/json",
      {
        "input": query,
        "key": Environment.googleApiKey,
      }
    );
    String? response = await PropertyNotifier().fetchLocation(uri);

    if(response != null) {
      PlaceAutocompleteResponse result = PlaceAutocompleteResponse.parseAutocompleteResult(response);
      if(result.predictions != null) {
        setState(() {
          placePredictions = result.predictions;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Listing"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Image Picker Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Images"),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo),
                        label: const Text("Pick from Gallery"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera),
                        label: const Text("Take Photo"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Display Selected Images
                  _images.isNotEmpty
                      ? Wrap(
                          spacing: 10,
                          children: _images
                              .asMap()
                              .entries
                              .map((entry) => Stack(
                                    children: [
                                      Image.file(
                                        entry.value,
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: IconButton(
                                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                                          onPressed: () => _removeImage(entry.key),
                                        ),
                                      ),
                                    ],
                                  ))
                              .toList(),
                        )
                      : const Text("No images selected."),
                ],
              ),
              const SizedBox(height: 16),
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a title";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a description";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _addressController,
                    onChanged: (value) {
                      placeAutocomplete(value);
                    },
                    decoration: const InputDecoration(labelText: "Address"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter an address";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Place Predictions List with Fixed Height
                  SizedBox(
                    height: placePredictions != null && placePredictions!.isNotEmpty ? 200 : 0,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: placePredictions?.length ?? 0,
                      itemBuilder: (context, index) => LocationListTile(
                        press: () {
                          _addressController.text = placePredictions![index].description!;
                          setState(() {
                            placePredictions = [];
                          });
                        },
                        location: placePredictions![index].description!,
                      ),
                    ),
                  ),
                ],
              ),

              // TextFormField(
              //   controller: _addressController,
              //   onChanged: (value) {
              //     placeAutocomplete(value);
              //   },
              //   decoration: const InputDecoration(labelText: "Address"),
              //   validator: (value) {
              //     if (value == null || value.isEmpty) {
              //       return "Please enter an address";
              //     }
              //     return null;
              //   },
              // ),
              // const SizedBox(height: 16),

              // const Divider(
              //   height: 4,
              //   thickness: 4,
              //   color: Kolors.kPrimaryLight,
              // ),

              // Expanded(
              //   child: ListView.builder(
              //     itemCount: placePredictions?.length,
              //     itemBuilder: (context, index) => LocationListTile(
              //       press: () {},
              //       location: placePredictions![index].description!,
              //     ),
              //   ),
              // ),

              // Rent
              TextFormField(
                controller: _rentController,
                decoration: const InputDecoration(labelText: "Rent"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter rent amount";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Rent Frequency
              DropdownButtonFormField(
                value: rentFrequency,
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text("Monthly")),
                  DropdownMenuItem(value: 'weekly', child: Text("Weekly")),
                  DropdownMenuItem(value: 'daily', child: Text("Daily")),
                ],
                onChanged: (value) {
                  setState(() {
                    rentFrequency = value!;
                  });
                },
                decoration: const InputDecoration(labelText: "Rent Frequency"),
              ),
              const SizedBox(height: 16),

              // Property Type
              DropdownButtonFormField(
                value: propertyType,
                items: const [
                  DropdownMenuItem(value: 'apartment', child: Text("Apartment")),
                  DropdownMenuItem(value: 'house', child: Text("House")),
                  DropdownMenuItem(value: 'studio', child: Text("Studio")),
                ],
                onChanged: (value) {
                  setState(() {
                    propertyType = value!;
                  });
                },
                decoration: const InputDecoration(labelText: "Property Type"),
              ),
              const SizedBox(height: 16),

              // Furnished Checkbox
              CheckboxListTile(
                title: const Text("Furnished"),
                value: furnished,
                onChanged: (value) {
                  setState(() {
                    furnished = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Bedrooms and Bathrooms
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bedroomsController,
                      decoration: const InputDecoration(labelText: "Bedrooms"),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter bedrooms";
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _bathroomsController,
                      decoration: const InputDecoration(labelText: "Bathrooms"),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter bathrooms";
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Square Footage
              TextFormField(
                controller: _squareFootageController,
                decoration: const InputDecoration(labelText: "Square Footage"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter square footage";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Submit Button
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    String? accessToken = Storage().getString('accessToken');
                    final propertyData = {
                      "listing_type": listingType,
                      "title": _titleController.text,
                      "description": _descriptionController.text,
                      "address": _addressController.text,
                      "latitude": double.tryParse(_latitudeController.text) ?? 0.0,
                      "longitude": double.tryParse(_longitudeController.text) ?? 0.0,
                      "rent": double.tryParse(_rentController.text) ?? 0.0,
                      "rent_frequency": rentFrequency,
                      "property_type": propertyType,
                      "furnished": furnished,
                      "bedrooms": int.tryParse(_bedroomsController.text) ?? 0,
                      "bathrooms": int.tryParse(_bathroomsController.text) ?? 0,
                      "square_footage": int.tryParse(_squareFootageController.text) ?? 0,
                      // "images": _images,
                      "created_at": DateTime.now().toIso8601String(),
                      "updated_at": DateTime.now().toIso8601String(),
                      "is_active": true,
                    };

                    if (accessToken != null) {
                      context.read<PropertyNotifier>().createProperty(
                        token: accessToken,
                        propertyData: propertyData,
                        onSuccess: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Property created successfully!")),
                          );
                          Navigator.pop(context); // Navigate back after success
                        },
                        onError: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Failed to create property")),
                          );
                        },
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Access token not available. Please log in.")),
                      );
                    }
                  }
                },
                child: const Text("Create Listing"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}