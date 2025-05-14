import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/custom_text_field.dart';
import 'package:marketplace_app/common/widgets/email_textfield.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/properties/controllers/property_notifier.dart';
import 'package:marketplace_app/src/properties/models/autocomplete_prediction.dart';
import 'package:marketplace_app/src/properties/models/place_autocomplete_response.dart';
import 'package:marketplace_app/src/properties/widgets/location_list_tile.dart';
import 'package:marketplace_app/src/properties/widgets/property_image_picker.dart';

import '../../../common/widgets/custom_dropdown.dart';
import '../../../common/widgets/custom_checkbox.dart';
import '../../../common/widgets/custom_date_picker.dart';
import '../../../common/widgets/custom_switch.dart';
import '../../../src/marketplace/controllers/marketplace_notifier.dart';
import 'package:provider/provider.dart';

class CreateMarketplacePage extends StatefulWidget {
  final bool isEditing;
  final String? itemId;
  final Map<String, dynamic>? initialData;

  const CreateMarketplacePage({
    super.key,
    this.isEditing = false,
    this.itemId,
    this.initialData,
  });

  @override
  State<CreateMarketplacePage> createState() => _CreateMarketplacePageState();
}

class _CreateMarketplacePageState extends State<CreateMarketplacePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers for input fields
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _availabilityDateController = TextEditingController();

  // List to store selected images
  final List<File> _images = [];
  List<AutocompletePrediction>? placePredictions = [];

  // Form fields
  String itemType = 'furniture';
  String itemSubtype = 'table';
  String condition = 'good';
  bool negotiable = false;
  bool deliveryAvailable = false;
  bool hideAddress = false;
  bool originalReceiptAvailable = false;
  String? _pincode;
  String? _city;
  String? _state;
  String? _country;
  String? _selectedPropertyId;

  Map<String, List<String>> itemSubtypes = {
    'furniture': ['sofa', 'cot', 'mattress', 'table', 'chair', 'wardrobe', 'dresser', 'bookshelf', 'desk', 'dining_table', 'coffee_table', 'other'],
    'electronics': ['tv', 'computer', 'accessories', 'printer', 'monitor', 'speaker', 'gaming_console', 'camera', 'phone', 'other'],
    'appliance': ['refrigerator', 'washing_machine', 'dryer', 'microwave', 'oven', 'toaster', 'coffee_maker', 'blender', 'fan', 'heater' 'other'],
    'kitchen': ['cookware', 'utensils', 'dishes', 'cutlery', 'other'],
    'decor': ['lighting', 'rug', 'curtain', 'mattress', 'art', 'plants', 'other'],
    'other': ['other'],
  };

  Map<String, String> conditionLabels = {
    'new': 'New',
    'like_new': 'Like New',
    'good': 'Good',
    'fair': 'Fair',
    'poor': 'Poor',
  };

  @override
  void initState() {
    super.initState();
    
    // Set default availability date to today
    DateTime today = DateTime.now();
    _availabilityDateController.text =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    // Fetch user properties for the dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketplaceNotifier>().fetchUserProperties();
    });

    // If editing, populate form with initial data
    if (widget.isEditing && widget.initialData != null) {
      final data = widget.initialData!;
      _titleController.text = data['title'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _addressController.text = data['address'] ?? '';
      _unitController.text = data['unit'] ?? '';
      _priceController.text = data['price']?.toString() ?? '';
      _originalPriceController.text = data['original_price']?.toString() ?? '';
      _latitudeController.text = data['latitude']?.toString() ?? '';
      _longitudeController.text = data['longitude']?.toString() ?? '';
      _availabilityDateController.text = data['availability_date'] ?? '';
      
      itemType = data['item_type'] ?? 'electronics';
      itemSubtype = data['item_subtype'] ?? 'phone';
      condition = data['condition'] ?? 'like_new';
      negotiable = data['negotiable'] ?? false;
      deliveryAvailable = data['delivery_available'] ?? false;
      hideAddress = data['hide_address'] ?? false;
      originalReceiptAvailable = data['original_receipt_available'] ?? false;
      
      if (data['property_id'] != null) {
        _selectedPropertyId = data['property_id'].toString();
      }
      
      _pincode = data['pincode'];
      _city = data['city'];
      _state = data['state'];
      _country = data['country'];
    }
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

  Future<void> fetchPlaceDetails(String placeId) async {
    Uri uri = Uri.https(
      "maps.googleapis.com",
      "maps/api/place/details/json",
      {
        "place_id": placeId,
        "key": Environment.googleApiKey,
      },
    );

    String? response = await PropertyNotifier().fetchLocation(uri);

    if (response != null) {
      final data = jsonDecode(response);

      if (data['status'] == 'OK') {
        final location = data['result']['geometry']['location'];
        double lat = location['lat'];
        double lng = location['lng'];

        List<dynamic> addressComponents = data['result']['address_components'];
        
        for (var component in addressComponents) {
          List types = component['types'];

          if (types.contains('postal_code')) {
            _pincode = component['long_name'];
          }
          if (types.contains('locality')) {
            _city = component['long_name'];
          }
          if (types.contains('administrative_area_level_1')) {
            _state = component['long_name'];
          }
          if (types.contains('country')) {
            _country = component['long_name'];
          }
        }

        setState(() {
          _latitudeController.text = lat.toString();
          _longitudeController.text = lng.toString();
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty && !widget.isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one image")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? token = Storage().getString('accessToken');
      if (token == null) throw Exception("User not authenticated");

      Map<String, dynamic> marketplaceData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'price': _priceController.text,
        'original_price': _originalPriceController.text,
        'item_type': itemType,
        'item_subtype': itemSubtype,
        'condition': condition,
        'negotiable': negotiable,
        'delivery_available': deliveryAvailable,
        'address': _addressController.text,
        'unit': _unitController.text,
        'pincode': _pincode,
        'city': _city,
        'state': _state,
        'country': _country,
        'latitude': _latitudeController.text,
        'longitude': _longitudeController.text,
        'hide_address': hideAddress,
        'availability_date': _availabilityDateController.text,
        'original_receipt_available': originalReceiptAvailable,
        'images': _images.map((file) => file.path).toList(),
      };

      if (_selectedPropertyId != null) {
        marketplaceData['property_id'] = _selectedPropertyId;
      }

      await context.read<MarketplaceNotifier>().createMarketplaceItem(
        token: token,
        marketplaceData: marketplaceData,
        onSuccess: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Item created successfully!")),
            );
            context.pop();
            context.read<MarketplaceNotifier>().applyFilters(context);
          }
        },
        onError: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to create item. Please try again.")),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final marketplaceNotifier = Provider.of<MarketplaceNotifier>(context);
    final userProperties = marketplaceNotifier.userProperties;

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(
          onTap: () => context.pop(),
        ),
        title: ReusableText(
          text: widget.isEditing ? "Edit Item" : "Create Listing",
          style: appStyle(15, Kolors.kPrimary, FontWeight.bold)
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              PropertyImagePicker(
                images: _images,
                existingImages: const [],
                onPickImage: (source) async {
                  try {
                    if (source == ImageSource.gallery) {
                      final List<XFile>? pickedImages = await _picker.pickMultiImage(
                        maxWidth: 1200,
                        maxHeight: 1200,
                        imageQuality: 70,
                      );
                      
                      if (pickedImages != null) {
                        setState(() {
                          _images.addAll(pickedImages.map((xFile) => File(xFile.path)));
                        });
                      }
                    } else {
                      final XFile? pickedImage = await _picker.pickImage(
                        source: source,
                        maxWidth: 1200,
                        maxHeight: 1200,
                        imageQuality: 70,
                      );
                      
                      if (pickedImage != null) {
                        setState(() {
                          _images.add(File(pickedImage.path));
                        });
                      }
                    }
                  } catch (e) {
                    print("Error picking images: $e");
                  }
                },
                onRemoveImage: (index) {
                  setState(() {
                    _images.removeAt(index);
                  });
                },
                onRemoveExistingImage: (index) {},
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: _titleController,
                labelText: "Title",
                isRequired: true,
                maxLines: 2,
                hintText: "Enter Title",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Title is required";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: _descriptionController,
                labelText: "Description",
                isRequired: true,
                maxLines: 6,
                hintText: "Enter Description",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Description is required";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _priceController,
                      labelText: "Price",
                      isRequired: true,
                      hintText: "Enter Price",
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(
                        CupertinoIcons.money_dollar,
                        size: 20,
                        color: Kolors.kGray
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Price is required";
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _originalPriceController,
                      labelText: "Original Price",
                      isRequired: true,
                      hintText: "Original Price",
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(
                        CupertinoIcons.money_dollar,
                        size: 20,
                        color: Kolors.kGray
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Original price is required";
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              CustomDropdown<String>(
                value: itemType,
                items: itemSubtypes.keys.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.replaceAll('_', ' ').toUpperCase()),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    itemType = value!;
                    itemSubtype = itemSubtypes[value]!.first;
                  });
                },
                labelText: "Item Type",
                isRequired: true,
              ),

              const SizedBox(height: 16),

              CustomDropdown<String>(
                value: itemSubtype,
                items: itemSubtypes[itemType]!.map((subtype) => DropdownMenuItem(
                  value: subtype,
                  child: Text(subtype.replaceAll('_', ' ').toUpperCase()),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    itemSubtype = value!;
                  });
                },
                labelText: "Item Subtype",
                isRequired: true,
              ),

              const SizedBox(height: 16),

              CustomDropdown<String>(
                value: condition,
                items: conditionLabels.entries.map((entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    condition = value!;
                  });
                },
                labelText: "Condition",
                isRequired: true,
              ),

              const SizedBox(height: 16),

              CustomCheckbox(
                value: negotiable,
                onChanged: (value) {
                  setState(() {
                    negotiable = value ?? false;
                  });
                },
                label: "Price Negotiable",
              ),

              const SizedBox(height: 8),

              CustomCheckbox(
                value: deliveryAvailable,
                onChanged: (value) {
                  setState(() {
                    deliveryAvailable = value ?? false;
                  });
                },
                label: "Delivery Available",
              ),

              const SizedBox(height: 8),

              CustomCheckbox(
                value: originalReceiptAvailable,
                onChanged: (value) {
                  setState(() {
                    originalReceiptAvailable = value ?? false;
                  });
                },
                label: "Original Receipt Available",
              ),

              const SizedBox(height: 16),

              CustomDatePicker(
                controller: _availabilityDateController,
                labelText: "Availability Date",
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Availability date is required";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              ReusableText(
                text: "Address",
                style: appStyle(14, Kolors.kPrimary, FontWeight.bold),
              ),

              const SizedBox(height: 8),

              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    placePredictions = [];
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EmailTextField(
                      hintText: "Address",
                      controller: _addressController,
                      prefixIcon: const Icon(
                        CupertinoIcons.location,
                        size: 20,
                        color: Kolors.kGray
                      ),
                      onChanged: (value) {
                        placeAutocomplete(value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Address is required";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: placePredictions != null && placePredictions!.isNotEmpty ? 200 : 0,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 3.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: placePredictions?.length ?? 0,
                          itemBuilder: (context, index) => LocationListTile(
                            press: () async {
                              _addressController.text = placePredictions![index].description!;
                              await fetchPlaceDetails(placePredictions![index].placeId!);
                              setState(() {
                                placePredictions = [];
                              });
                            },
                            location: placePredictions![index].description!,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: _unitController,
                labelText: "Unit / Apartment",
                maxLines: 1,
                hintText: "Enter Unit / Apartment",
                prefixIcon: const Icon(
                  CupertinoIcons.building_2_fill,
                  size: 20,
                  color: Kolors.kGray,
                ),
              ),

              const SizedBox(height: 16),

              CustomCheckbox(
                value: hideAddress,
                onChanged: (value) {
                  setState(() {
                    hideAddress = value ?? false;
                  });
                },
                label: "Hide Address",
              ),

              const SizedBox(height: 16),

              if (userProperties.isNotEmpty) ...[
                ReusableText(
                  text: "Associate with a Property",
                  style: appStyle(14, Kolors.kPrimary, FontWeight.bold),
                ),
                
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String?>(
                  value: _selectedPropertyId,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text("-- None --"),
                    ),
                    ...userProperties.map((property) => DropdownMenuItem<String?>(
                      value: property.id,
                      child: Text(property.title),
                    )).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPropertyId = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Your Property Listings",
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
                  ),
                ),
                
                const SizedBox(height: 16),
              ],

              CustomButton(
                onTap: _isLoading ? null : _handleSubmit,
                text: widget.isEditing ? "Update Item" : "Create Item",
                btnWidth: ScreenUtil().screenWidth,
                btnHeight: 40,
                radius: 20,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
