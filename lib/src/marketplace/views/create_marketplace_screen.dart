import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/custom_dropdown.dart';
import 'package:marketplace_app/common/widgets/custom_text_field.dart';
import 'package:marketplace_app/common/widgets/email_textfield.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/common/widgets/searchable_multi_select_dropdown.dart';
import 'package:marketplace_app/src/properties/controllers/property_notifier.dart';
import 'package:marketplace_app/src/properties/models/autocomplete_prediction.dart';
import 'package:marketplace_app/src/properties/models/place_autocomplete_response.dart';
import 'package:marketplace_app/src/properties/widgets/location_list_tile.dart';
import 'package:marketplace_app/src/marketplace/widgets/marketplace_image_picker.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_detail_model.dart';
import 'package:marketplace_app/src/marketplace/services/marketplace_service_v2.dart';

import '../../../common/widgets/custom_checkbox.dart';
import '../../../common/widgets/custom_date_picker.dart';
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

  // School-related fields
  String _lastSearchQuery = '';
  final Map<String, Map<String, String>> _selectedSchoolsMap = {};
  List<Map<String, String>> schoolOptions = [];
  List<String> selectedSchoolIds = [];
  final ScrollController _schoolScrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMoreSchools = true;
  bool _isLoadingMoreSchools = false;

  // List to store selected images
  final List<File> _images = [];
  // List to store existing images when editing (URLs)
  List<MarketplaceDetailImage> _existingImages = [];
  // List to track removed image IDs
  final List<String> _deletedImages = [];
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
    'furniture': ['sofa', 'cot', 'mattress', 'table', 'chair', 'wardrobe', 'dresser', 'bookshelf', 'desk', 'other'],
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

  Future<void> _fetchNearbySchools(double lat, double lng) async {
    String url = "${Environment.iosAppBaseUrl}/api/school/nearby/?lat=$lat&lng=$lng";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          // Clear previous selections
          selectedSchoolIds = [];
          _selectedSchoolsMap.clear();

          // Update selected schools and map
          for (var school in data) {
            String id = school['id'] as String;
            selectedSchoolIds.add(id);
            _selectedSchoolsMap[id] = {
              'id': id,
              'name': school['name'] as String
            };
          }

          // Fetch full school details to ensure we have them in schoolOptions
          _fetchSchools();
        });
      } else {
        throw Exception("Failed to load nearby schools");
      }
    } catch (e) {
      debugPrint("Error fetching nearby schools: $e");
    }
  }

  Future<void> _fetchSchools() async {
    if (!_hasMoreSchools || _isLoadingMoreSchools) return;

    setState(() {
      _isLoadingMoreSchools = true;
    });

    String url = "${Environment.iosAppBaseUrl}/api/school/lite/?page=$_currentPage";
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        final bool hasNext = data['next'] != null;

        setState(() {
          if (_currentPage == 1) {
            schoolOptions = results.map<Map<String, String>>((school) => {
              'id': school['id'].toString(),
              'name': school['name'].toString()
            }).toList();
          } else {
            schoolOptions.addAll(results.map<Map<String, String>>((school) => {
              'id': school['id'].toString(),
              'name': school['name'].toString()
            }));
          }
          _hasMoreSchools = hasNext;
          if (hasNext) _currentPage++;
          _isLoadingMoreSchools = false;
        });
      } else {
        setState(() {
          _isLoadingMoreSchools = false;
        });
        throw Exception("Failed to load schools");
      }
    } catch (e) {
      setState(() {
        _isLoadingMoreSchools = false;
      });
      debugPrint("Error fetching schools: $e");
    }  
  }

  Future<void> _searchSchools(String query) async {
    // Reset pagination when a new search is initiated
    if (_lastSearchQuery != query) {
      setState(() {
        _currentPage = 1;
        _hasMoreSchools = true;
        _lastSearchQuery = query;
      });
    }

    if (!_hasMoreSchools || _isLoadingMoreSchools) return;

    setState(() {
      _isLoadingMoreSchools = true;
    });

    if (query.isEmpty && _currentPage == 1) {
      await _fetchSchools();
      return;
    }

    String url = "${Environment.iosAppBaseUrl}/api/school/lite/?name=$query&page=$_currentPage";
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        final bool hasNext = data['next'] != null;

        setState(() {
          if (_currentPage == 1) {
            // Create a new list with both API results and selected schools
            List<Map<String, String>> newOptions = results.map<Map<String, String>>((school) => {
              'id': school['id'].toString(),
              'name': school['name'].toString()
            }).toList();

            // Add selected schools that aren't in the search results
            for (String id in selectedSchoolIds) {
              if (!newOptions.any((school) => school['id'] == id) && _selectedSchoolsMap.containsKey(id)) {
                newOptions.add(_selectedSchoolsMap[id]!);
              }
            }
            schoolOptions = newOptions;
          } else {
            // For pagination, only add new schools from API that aren't already in the list
            List<Map<String, String>> newSchools = results.map<Map<String, String>>((school) => {
              'id': school['id'].toString(),
              'name': school['name'].toString()
            }).where((school) => !schoolOptions.any((existing) => existing['id'] == school['id'])).toList();
            schoolOptions.addAll(newSchools);
          }
          _hasMoreSchools = hasNext;
          if (hasNext) _currentPage++;
          _isLoadingMoreSchools = false;
        });
      } else {
        setState(() {
          _isLoadingMoreSchools = false;
        });
        throw Exception("Failed to search schools");
      }
    } catch (e) {
      setState(() {
        _isLoadingMoreSchools = false;
      });
      debugPrint("Error searching schools: $e");
    }
  }

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
      _fetchSchools(); // Fetch initial schools
      
      // If editing, fetch item data
      if (widget.isEditing && widget.itemId != null) {
        _fetchItemData();
      }
    });

    // If editing, populate form with initial data (fallback)
    if (widget.isEditing && widget.initialData != null) {
      _populateFormData(widget.initialData!);
    }
  }

  Future<void> _fetchItemData() async {
    if (widget.itemId == null) return;
    
    try {
      final marketplaceNotifier = context.read<MarketplaceNotifier>();
      final item = await marketplaceNotifier.fetchMarketplaceDetail(widget.itemId!);
      
      if (item != null && mounted) {
        debugPrint('📚 Schools nearby from API: ${item.schoolsNearby.length} schools');
        for (var school in item.schoolsNearby) {
          debugPrint('📚 School: ${school.id} - ${school.name}');
        }
        
        _populateFormData({
          'title': item.title,
          'description': item.description,
          'price': item.price,
          'original_price': item.originalPrice,
          'item_type': item.itemType,
          'item_subtype': item.itemSubtype,
          'condition': item.condition,
          'negotiable': item.negotiable,
          'delivery_available': item.deliveryAvailable,
          'address': item.address,
          'unit': item.unit,
          'latitude': item.latitude,
          'longitude': item.longitude,
          'availability_date': item.availabilityDate?.toIso8601String().split('T')[0],
          'original_receipt_available': item.originalReceiptAvailable,
          'hide_address': item.hideAddress,
          'property_id': item.property?.id,
          'school_ids': item.schoolsNearby.map((s) => s.id).toList(),
          'schools_nearby': item.schoolsNearby, // Pass full school objects
          'images': item.images,
        });
      }
    } catch (e) {
      debugPrint('Error fetching item data: $e');
    }
  }

  void _populateFormData(Map<String, dynamic> data) {
    _titleController.text = data['title'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _addressController.text = data['address'] ?? '';
    _unitController.text = data['unit'] ?? '';
    _priceController.text = data['price']?.toString() ?? '';
    _originalPriceController.text = data['original_price']?.toString() ?? '';
    _latitudeController.text = data['latitude']?.toString() ?? '';
    _longitudeController.text = data['longitude']?.toString() ?? '';
    _availabilityDateController.text = data['availability_date'] ?? '';
    
    setState(() {
      itemType = data['item_type'] ?? 'furniture';
      itemSubtype = data['item_subtype'] ?? 'table';
      condition = data['condition'] ?? 'good';
      negotiable = data['negotiable'] ?? false;
      deliveryAvailable = data['delivery_available'] ?? false;
      hideAddress = data['hide_address'] ?? false;
      originalReceiptAvailable = data['original_receipt_available'] ?? false;
      
      if (data['property_id'] != null) {
        _selectedPropertyId = data['property_id'].toString();
      }
      
      // Handle schools
      if (data['school_ids'] != null) {
        selectedSchoolIds = List<String>.from(data['school_ids']);
        
        // If we have full school objects, use them directly
        if (data['schools_nearby'] != null) {
          debugPrint('📚 Processing ${data['schools_nearby'].length} schools from data');
          _selectedSchoolsMap.clear();
          for (var school in data['schools_nearby']) {
            String id = school.id;
            String name = school.name;
            debugPrint('📚 Adding school to map: $id - $name');
            _selectedSchoolsMap[id] = {
              'id': id,
              'name': name
            };
            
            // Also add to schoolOptions if not already present
            if (!schoolOptions.any((option) => option['id'] == id)) {
              debugPrint('📚 Adding school to options: $id - $name');
              schoolOptions.add({
                'id': id,
                'name': name
              });
            }
          }
        } else {
          // Fallback: set loading state and fetch school details
          for (String id in selectedSchoolIds) {
            _selectedSchoolsMap[id] = {
              'id': id,
              'name': 'Loading...' // This will be updated when schools are fetched
            };
          }
        }
      }
      
      // Handle existing images
      if (data['images'] != null && data['images'] is List) {
        _existingImages = (data['images'] as List<MarketplaceDetailImage>);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _addressController.dispose();
    _unitController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _availabilityDateController.dispose();
    _schoolScrollController.dispose();
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

        // Extract address components
        String? pincode;
        String? city;
        String? state;
        String? country;

        List<dynamic> addressComponents = data['result']['address_components'];
        
        for (var component in addressComponents) {
          List types = component['types'];

          if (types.contains('postal_code')) {
            pincode = component['long_name'];
          }
          if (types.contains('locality')) {
            city = component['long_name'];
          }
          if (types.contains('administrative_area_level_1')) {
            state = component['long_name'];
          }
          if (types.contains('country')) {
            country = component['long_name'];
          }
        }

        setState(() {
          _latitudeController.text = lat.toString();
          _longitudeController.text = lng.toString();
          _pincode = pincode;
          _city = city;
          _state = state;
          _country = country;
        });

        // Fetch nearby schools after getting location
        _fetchNearbySchools(lat, lng);
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // For new items, require at least one image
    if (!widget.isEditing && _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one image")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? token = Storage().getString('accessToken');
      if (token == null) throw Exception("User not authenticated");

      // Extract userId from stored user profile
      String? userJson = Storage().getString('user');
      String? userId;
      if (userJson != null) {
        try {
          final userMap = jsonDecode(userJson);
          userId = userMap['id']?.toString();
        } catch (e) {
          debugPrint('Error decoding user JSON: $e');
        }
      }
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User ID not found. Please re-login.")),
          );
        }
        setState(() { _isLoading = false; });
        return;
      }

      Map<String, dynamic> marketplaceData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'price': _priceController.text,
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
        if (selectedSchoolIds.isNotEmpty) 'school_ids': selectedSchoolIds.join(','),
      };

      // Only include original_price if it's not empty, otherwise send null
      if (_originalPriceController.text.isNotEmpty) {
        marketplaceData['original_price'] = _originalPriceController.text;
      } else {
        marketplaceData['original_price'] = null;
      }

      if (_selectedPropertyId != null) {
        marketplaceData['property_id'] = _selectedPropertyId;
      }

      if (widget.isEditing && widget.itemId != null) {
        if (_deletedImages.isNotEmpty) {
          marketplaceData['deleted_images'] = _deletedImages;
        }
        
        await MarketplaceServiceV2.updateMarketplaceItem(
          itemId: widget.itemId!,
          marketplaceData: marketplaceData,
          images: _images,
          userId: userId,
          onProgress: (progress) {
            debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
          },
        ).then((result) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Item updated successfully!")),
            );
            context.pop();
          }
        }).catchError((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to update item: $error")),
            );
          }
        });
      } else {
        await MarketplaceServiceV2.createMarketplaceItem(
          marketplaceData: marketplaceData,
          images: _images,
          userId: userId,
          onProgress: (progress) {
            debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
          },
        ).then((result) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Item created successfully!")),
            );
            context.pop();
          }
        }).catchError((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to create item: $error")),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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
          text: widget.isEditing ? "Edit Item" : "Create Marketplace Item",
          style: appStyle(15, Kolors.kPrimary, FontWeight.bold)
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              MarketplaceImagePicker(
                images: _images,
                existingImages: _existingImages,
                onPickImage: (source) async {
                  try {
                    if (source == ImageSource.gallery) {
                      final List<XFile> pickedImages = await _picker.pickMultiImage(
                        maxWidth: 800,
                        maxHeight: 800,
                        imageQuality: 50,
                      );
                      
                      setState(() {
                        _images.addAll(pickedImages.map((xFile) => File(xFile.path)));
                      });
                                        } else {
                      final XFile? pickedImage = await _picker.pickImage(
                        source: source,
                        maxWidth: 800,
                        maxHeight: 800,
                        imageQuality: 50,
                      );
                      
                      if (pickedImage != null) {
                        setState(() {
                          _images.add(File(pickedImage.path));
                        });
                      }
                    }
                  } catch (e) {
                    debugPrint("Error picking images: $e");
                  }
                },
                onRemoveImage: (index) {
                  setState(() {
                    _images.removeAt(index);
                  });
                },
                onRemoveExistingImage: (index) {
                  String imageId = _existingImages[index].id;
                  setState(() {
                    // Only add to deleted images if it's not empty
                    if (imageId.isNotEmpty) {
                      _deletedImages.add(imageId);
                    }
                    _existingImages.removeAt(index);
                  });
                },
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
                      isRequired: false,
                      hintText: "Original Price (Optional)",
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(
                        CupertinoIcons.money_dollar,
                        size: 20,
                        color: Kolors.kGray
                      ),
                      // validator: (value) {
                      //   if (value != null && value.isNotEmpty) {
                      //     final price = double.tryParse(value);
                      //     if (price == null) {
                      //       return "Please enter a valid price";
                      //     }
                      //   }
                      //   return null;
                      // },
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

              RichText(
                text: TextSpan(
                  text: "Address",
                  style: appStyle(14, Kolors.kPrimary, FontWeight.bold),
                  children: const [
                    TextSpan(
                      text: " *",
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
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

              // Add Schools Section
              Text(
                "Nearby Schools", 
                style: appStyle(14, Kolors.kPrimary, FontWeight.bold),
              ),

              const SizedBox(height: 8),

              SearchableMultiSelectDropdown(
                title: "Schools",
                options: schoolOptions.map((school) => school['name']!).toList(),
                selectedValues: selectedSchoolIds.map((id) =>
                  schoolOptions.firstWhere((school) => school['id'] == id, orElse: () => _selectedSchoolsMap[id] ?? {'name': '', 'id': id})['name']!
                ).toList(),
                hintText: "Select Nearby Schools",
                onSelectionChanged: (List<String> selectedNames) {
                  setState(() {
                    // Create a new map of name to ID for quick lookup
                    Map<String, String> nameToIdMap = {};
                    for (var school in schoolOptions) {
                      nameToIdMap[school['name']!] = school['id']!;
                    }
                    // Also add from selected schools map for schools not in options
                    for (var entry in _selectedSchoolsMap.entries) {
                      nameToIdMap[entry.value['name']!] = entry.value['id']!;
                    }

                    // Clear existing selections
                    selectedSchoolIds = [];
                    Map<String, Map<String, String>> newSelectedSchoolsMap = {};

                    // Update selections based on selected names
                    for (String name in selectedNames) {
                      String? id = nameToIdMap[name];
                      if (id != null) {
                        selectedSchoolIds.add(id);
                        // Keep or add to selected schools map
                        if (_selectedSchoolsMap.containsKey(id)) {
                          newSelectedSchoolsMap[id] = _selectedSchoolsMap[id]!;
                        } else {
                          newSelectedSchoolsMap[id] = {
                            'id': id,
                            'name': name
                          };
                        }
                      }
                    }

                    // Update the selected schools map
                    _selectedSchoolsMap.clear();
                    _selectedSchoolsMap.addAll(newSelectedSchoolsMap);
                  });
                },
                onSearch: _searchSchools,
                scrollController: _schoolScrollController,
                isLoading: _isLoadingMoreSchools,
              ),

              const SizedBox(height: 16),
              
              CustomDropdown<String?>(
                value: _selectedPropertyId,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text("-- None --"),
                  ),
                  ...userProperties.map((property) => DropdownMenuItem<String?>(
                    value: property.id,
                    child: Text(property.title),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPropertyId = value;
                  });
                },
                labelText: "Associate with a Property",
                hintText: "Select a property",
              ),
              
              const SizedBox(height: 16),

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
