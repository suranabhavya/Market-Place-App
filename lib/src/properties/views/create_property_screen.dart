import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/email_textfield.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/common/widgets/searchable_multi_select_dropdown.dart';
import 'package:marketplace_app/src/properties/controllers/property_notifier.dart';
import 'package:marketplace_app/src/properties/models/autocomplete_prediction.dart';
import 'package:marketplace_app/src/properties/models/place_autocomplete_response.dart';
import 'package:marketplace_app/src/properties/widgets/location_list_tile.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../common/widgets/custom_text.dart';


// TODO: fetch schools API is behaving weirdly when multiple schools are selected it keeps on loading check later

class CreatePropertyPage extends StatefulWidget {
  const CreatePropertyPage({super.key});

  @override
  State<CreatePropertyPage> createState() => _CreatePropertyPageState();
}

class _CreatePropertyPageState extends State<CreatePropertyPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for input fields
  final ImagePicker _picker = ImagePicker();
  String _lastSearchQuery = '';
  final Map<String, Map<String, String>> _selectedSchoolsMap = {};
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _unitController= TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _rentController = TextEditingController();
  final TextEditingController _squareFootageController = TextEditingController();
  final TextEditingController _bedroomsController = TextEditingController();
  final TextEditingController _bathroomsController = TextEditingController();
  final TextEditingController _availableFromController = TextEditingController();
  final TextEditingController _availableTillController = TextEditingController();

  Map<String, bool> amenities = {};
  // List to store selected images
  final List<File> _images = [];

  List<AutocompletePrediction>? placePredictions = [];

  // Dropdown values
  String listingType = 'sublease';
  String rentFrequency = 'monthly';
  String propertyType = 'shared_room';
  String smoking = '';
  String partying = '';
  String dietary = '';
  String nationality = '';
  String genderPreference = '';
  String smokingPreference = '';
  String partyingPreference = '';
  String dietaryPreference = '';
  String nationalityPreference = '';
  bool furnished = false;
  bool _hideAddress = false;
  String? _pincode;
  String? _city;
  String? _state;
  String? _country;
  List<Map<String, String>> schoolOptions = [];
  List<String> selectedSchoolIds = [];
  final ScrollController _schoolScrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMoreSchools = true;
  bool _isLoadingMoreSchools = false;

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

  // Method to pick a date
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _unitController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _rentController.dispose();
    _squareFootageController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _availableFromController.dispose();
    _availableTillController.dispose();
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
      print("Error fetching nearby schools: $e");
    }
  }

  // Function to fetch place details (lat/lng) based on the place_id
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

        // **Fetch Nearby Schools After Address Selection**
        _fetchNearbySchools(lat, lng);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to get location details: ${data['status']}")),
        );
      }
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
      print("Error fetching schools: $e");
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
      print("Error searching schools: $e");
    }
  }

  // Validate Form
  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    DateTime? availableFrom = _availableFromController.text.isNotEmpty
      ? DateTime.parse(_availableFromController.text)
      : null;
    DateTime? availableTo = _availableTillController.text.isNotEmpty
      ? DateTime.parse(_availableTillController.text)
      : null;

    if (availableFrom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Available From is required.")),
      );
      return false;
    }

    if (availableTo != null && availableTo.isBefore(availableFrom)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Available Till must be after Available From!")),
      );
      return false;
    }
    return true;
  }

  // Fetch Amenities from API
  Future<void> _fetchAmenities() async {
    const String url = 'http://127.0.0.1:8000/api/amenities/';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        print("API Response: $responseBody");

        List<dynamic> data = json.decode(responseBody);

        setState(() {
          // Convert List into a Map for selection tracking
          amenities = {for (var item in data) item["name"]: false};
        });
      } else {
        throw Exception("Failed to load amenities");
      }
    } catch (e) {
      print("Error fetching amenities: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchSchools();
    _fetchAmenities();

    // Set default available_from to today's date
    DateTime today = DateTime.now();
    _availableFromController.text =
      "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
  }

  // Helper function to add red asterisk to required fields
  Widget requiredLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: appStyle(14, Kolors.kPrimary, FontWeight.bold),
        children: const [
          TextSpan(
            text: " *",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(
          onTap: () {
            context.pop();
          },
        ),
        title: ReusableText(
          text: AppText.kCreateListing,
          style: appStyle(15, Kolors.kPrimary, FontWeight.bold)
        ),
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
                  Text(
                    "Images", 
                    style: appStyle(14, Kolors.kPrimary, FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo, color: Kolors.kPrimary),
                        label: Text(
                          "Pick from Gallery",
                          style: appStyle(14, Kolors.kPrimary, FontWeight.normal),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera, color: Kolors.kPrimary),
                        label: Text(
                          "Take Photo",
                          style: appStyle(14, Kolors.kPrimary, FontWeight.normal),
                        ),
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
                      : Text(
                        "No images selected.",
                        style: appStyle(14, Kolors.kPrimary, FontWeight.normal)
                      ),
                ],
              ),
              const SizedBox(height: 16),
              // Title
              requiredLabel("Title"),

              const SizedBox(height: 8),
              
              CustomTextField(
                controller: _titleController,
                maxLines: 2,
                hintText: "Enter Title",
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Title is required.";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description
              requiredLabel("Description"),
              
              const SizedBox(height: 8),

              CustomTextField(
                controller: _descriptionController,
                maxLines: 6,
                hintText: "Enter Description",
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Description is required.";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              requiredLabel("Address"),

              const SizedBox(height: 8),

              // Address
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus(); // Dismiss keyboard when tapping outside
                  setState(() {
                    placePredictions = []; // Hide dropdown
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
                      keyboardType: TextInputType.name,
                      onChanged: (value) {
                        placeAutocomplete(value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Address is required.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                
                    // Place Predictions List with Fixed Height
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
              // Title
              Text(
                "Unit / Apartment #", 
                style: appStyle(14, Kolors.kPrimary, FontWeight.bold),
              ),

              const SizedBox(height: 8),

              CustomTextField(
                prefixIcon: const Icon(
                  CupertinoIcons.building_2_fill,
                  size: 20,
                  color: Kolors.kGray,
                ),
                controller: _unitController,
                maxLines: 1,
                hintText: "Enter Unit / Apartment",
                keyboardType: TextInputType.name,
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _hideAddress,
                    onChanged: (bool? value) {
                      setState(() {
                        _hideAddress = value ?? false;
                      });
                    },
                    activeColor: Kolors.kPrimary,
                    checkColor: Colors.white,
                  ),
                  Text(
                    "Hide Address",
                    style: appStyle(14, Kolors.kPrimary, FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Title
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
                    // Update selectedSchoolIds and _selectedSchoolsMap
                    selectedSchoolIds = selectedNames.map((name) {
                      var school = schoolOptions.firstWhere((s) => s['name'] == name);
                      _selectedSchoolsMap[school['id']!] = school;
                      return school['id']!;
                    }).toList();
                  });
                },
                onSearch: _searchSchools,
                scrollController: _schoolScrollController,
                isLoading: _isLoadingMoreSchools,
              ),

              const SizedBox(height: 16),

              requiredLabel("Property Type"),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: propertyType,
                items: const [
                  DropdownMenuItem(value: 'private_room', child: Text("Private Room")),
                  DropdownMenuItem(value: 'shared_room', child: Text("Shared Room")),
                  DropdownMenuItem(value: 'apartment', child: Text("Apartment")),
                ],
                style: appStyle(12, Kolors.kDark, FontWeight.normal),
                onChanged: (value) {
                  setState(() {
                    propertyType = value!;
                  });
                },
                decoration: InputDecoration(
                  labelStyle: appStyle(12, Kolors.kGray, FontWeight.normal),
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
              requiredLabel("Listing Type"),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: listingType,
                items: const [
                  DropdownMenuItem(value: 'sublease', child: Text("Sublease")),
                  DropdownMenuItem(value: 'rent', child: Text("Rent")),
                ],
                style: appStyle(12, Kolors.kDark, FontWeight.normal),
                onChanged: (value) {
                  setState(() {
                    listingType = value!;
                  });
                },
                decoration: InputDecoration(
                  labelStyle: appStyle(12, Kolors.kGray, FontWeight.normal),
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

              // Available From Date Picker
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        requiredLabel("Available From"),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _availableFromController,
                          readOnly: true,
                          onTap: () => _selectDate(context, _availableFromController),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Available From is required.";
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Kolors.kPrimary, width: 1.5),
                            ),
                            suffixIcon: const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                            hintText: "Select Date",
                            hintStyle: appStyle(12, Kolors.kGray, FontWeight.normal),
                          ),
                        ),
                      ]
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Available Till",
                          style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _availableTillController,
                          readOnly: true,
                          onTap: () => _selectDate(context, _availableTillController),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              DateTime availableFrom = DateTime.parse(_availableFromController.text);
                              DateTime availableTill = DateTime.parse(value);
                              if (availableTill.isBefore(availableFrom)) {
                                return "Available Till must be after Available From.";
                              }
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Kolors.kPrimary, width: 1.5),
                            ),
                            suffixIcon: const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                            hintText: "Select Date",
                            hintStyle: appStyle(12, Kolors.kGray, FontWeight.normal),
                          ),
                        ),
                      ]
                    ),
                  )
                ]
              ),

              const SizedBox(height: 16),

              // Rent
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        requiredLabel("Rent"),

                        const SizedBox(height: 8),

                        CustomTextField(
                          controller: _rentController,
                          maxLines: 1,
                          hintText: "Enter Rent",
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(
                            CupertinoIcons.money_dollar,
                            size: 20,
                            color: Kolors.kGray
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Rent is required.";
                            }
                            return null;
                          },
                        ),
                      ]
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        requiredLabel("Rent Frequency"),

                        const SizedBox(height: 8),

                        DropdownButtonFormField<String>(
                          value: rentFrequency,
                          items: const [
                            DropdownMenuItem(value: 'monthly', child: Text("Monthly")),
                            DropdownMenuItem(value: 'weekly', child: Text("Weekly")),
                            DropdownMenuItem(value: 'daily', child: Text("Daily")),
                          ],
                          style: appStyle(12, Kolors.kDark, FontWeight.normal),
                          onChanged: (value) {
                            setState(() {
                              rentFrequency = value!;
                            });
                          },
                          decoration: InputDecoration(
                            labelStyle: appStyle(12, Kolors.kGray, FontWeight.normal),
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
                      ]
                    ),
                  )
                ]
              ),

              const SizedBox(height: 16),

              // Furnished Checkbox
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Furnished",
                    style: appStyle(14, Kolors.kPrimary, FontWeight.bold),
                  ),
                  Transform.scale(
                    scale: 0.8, // Reduce switch size
                    child: Switch(
                      value: furnished,
                      onChanged: (bool value) {
                        setState(() {
                          furnished = value;
                        });
                      },
                      activeColor: Kolors.kPrimary,
                      inactiveThumbColor: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Square Footage Area",
                    style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
                  ),

                  const SizedBox(height: 8),

                  CustomTextField(
                    controller: _squareFootageController,
                    maxLines: 1,
                    hintText: "Area of the Room / Apartment in Sqft",
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(
                      MaterialCommunityIcons.ruler,
                      size: 20,
                      color: Kolors.kGray
                    ),
                  ),
                ]
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bedrooms",
                          style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
                        ),

                        const SizedBox(height: 8),

                        CustomTextField(
                          controller: _bedroomsController,
                          maxLines: 1,
                          hintText: "Bedrooms",
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(
                            Icons.bed,
                            size: 20,
                            color: Kolors.kGray
                          ),
                        ),
                      ]
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bathrooms",
                          style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
                        ),

                        const SizedBox(height: 8),

                        CustomTextField(
                          controller: _bathroomsController,
                          maxLines: 1,
                          hintText: "Bathrooms",
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(
                            Icons.bathtub,
                            size: 20,
                            color: Kolors.kGray
                          ),
                        ),
                      ]
                    ),
                  )
                ]
              ),
              
              const SizedBox(height: 16),

              Divider(
                color: Kolors.kGrayLight,
                thickness: 0.5.h,
              ),

              const SizedBox(height: 16),

              Text(
                "Amenities (Optional)",
                style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
              ),

              const SizedBox(height: 16),

              amenities.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: amenities.keys.map((String key) {
                      bool isSelected = amenities[key]!;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            amenities[key] = !isSelected;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Kolors.kPrimary : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) const Icon(Icons.check, color: Colors.white, size: 16),
                              if (isSelected) const SizedBox(width: 6),
                              Text(
                                key,
                                style: appStyle(12, isSelected ? Colors.white : Colors.black, FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

              const SizedBox(height: 16),

              Divider(
                color: Kolors.kGrayLight,
                thickness: 0.5.h,
              ),

              const SizedBox(height: 16),

              Text(
                "Lifestyle (Optional)",
                style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
              ),

              const SizedBox(height: 16),

              Text(
                "Smoking",
                style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: smoking,
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Prefer not to say",
                          style: appStyle(14, Kolors.kPrimary, FontWeight.normal)
                        ),
                        SizedBox(width: 8.w),
                        const Icon(Icons.smoking_rooms , color: Colors.black, size: 16)
                      ],
                    )
                  ),
                  const DropdownMenuItem(value: 'never', child: Text("Never")),
                  const DropdownMenuItem(value: 'rarely', child: Text("Rarely")),
                  const DropdownMenuItem(value: 'occasionally', child: Text("Occasionally")),
                  const DropdownMenuItem(value: 'regularly', child: Text("Regularly")),
                ],
                style: appStyle(12, Kolors.kDark, FontWeight.normal),
                onChanged: (value) {
                  setState(() {
                    smoking = value!;
                  });
                },
                decoration: InputDecoration(
                  labelStyle: appStyle(12, Kolors.kGray, FontWeight.normal),
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

              const SizedBox(height: 8),

              Text(
                "Partying",
                style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: partying,
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Prefer not to say",
                          style: appStyle(14, Kolors.kPrimary, FontWeight.normal)
                        ),
                        SizedBox(width: 8.w),
                        const Icon(Icons.wine_bar , color: Colors.black, size: 16)
                      ],
                    )
                  ),
                  const DropdownMenuItem(value: 'never', child: Text("Never")),
                  const DropdownMenuItem(value: 'rarely', child: Text("Rarely")),
                  const DropdownMenuItem(value: 'occasionally', child: Text("Occasionally")),
                  const DropdownMenuItem(value: 'regularly', child: Text("Regularly")),
                ],
                style: appStyle(12, Kolors.kDark, FontWeight.normal),
                onChanged: (value) {
                  setState(() {
                    partying = value!;
                  });
                },
                decoration: InputDecoration(
                  labelStyle: appStyle(12, Kolors.kGray, FontWeight.normal),
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

              const SizedBox(height: 8),

              Text(
                "Dietary",
                style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: dietary,
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Prefer not to say",
                          style: appStyle(14, Kolors.kPrimary, FontWeight.normal)
                        ),
                        SizedBox(width: 8.w),
                        const Icon(Icons.lunch_dining , color: Colors.black, size: 16)
                      ],
                    )
                  ),
                  const DropdownMenuItem(value: 'veg', child: Text("Vegetarian")),
                  const DropdownMenuItem(value: 'non_veg', child: Text("Non Vegetarian")),
                  const DropdownMenuItem(value: 'vegan', child: Text("Vegan")),
                ],
                style: appStyle(12, Kolors.kDark, FontWeight.normal),
                onChanged: (value) {
                  setState(() {
                    dietary = value!;
                  });
                },
                decoration: InputDecoration(
                  labelStyle: appStyle(12, Kolors.kGray, FontWeight.normal),
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

              const SizedBox(height: 8),

              Text(
                "Nationality",
                style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: nationality,
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Prefer not to say",
                          style: appStyle(14, Kolors.kPrimary, FontWeight.normal)
                        ),
                        SizedBox(width: 8.w),
                        const Icon(Icons.groups_3_sharp , color: Colors.black, size: 16)
                      ],
                    )
                  ),
                  const DropdownMenuItem(value: 'indian', child: Text("Indian")),
                  const DropdownMenuItem(value: 'korean', child: Text("Korean")),
                  const DropdownMenuItem(value: 'chinese', child: Text("Chinese")),
                  const DropdownMenuItem(value: 'american', child: Text("American")),
                  const DropdownMenuItem(value: 'others', child: Text("Others")),
                  const DropdownMenuItem(value: 'mixed', child: Text("Mixed")),
                ],
                style: appStyle(12, Kolors.kDark, FontWeight.normal),
                onChanged: (value) {
                  setState(() {
                    nationality = value!;
                  });
                },
                decoration: InputDecoration(
                  labelStyle: appStyle(12, Kolors.kGray, FontWeight.normal),
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

              Divider(
                color: Kolors.kGrayLight,
                thickness: 0.5.h,
              ),

              const SizedBox(height: 16),

              Text(
                "Preference (Optional)",
                style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
              ),

              const SizedBox(height: 16),

              Text(
                "Gender Preference",
                style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: genderPreference,
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Any",
                          style: appStyle(14, Kolors.kPrimary, FontWeight.normal)
                        ),
                        SizedBox(width: 8.w),
                        const Icon(Icons.people , color: Colors.black, size: 16)
                      ],
                    )
                  ),
                  const DropdownMenuItem(value: 'boys', child: Text("Boys Only")),
                  const DropdownMenuItem(value: 'girls', child: Text("Girls Only")),
                ],
                style: appStyle(12, Kolors.kDark, FontWeight.normal),
                onChanged: (value) {
                  setState(() {
                    genderPreference = value!;
                  });
                },
                decoration: InputDecoration(
                  labelStyle: appStyle(12, Kolors.kGray, FontWeight.normal),
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

              const SizedBox(height: 8),

              Text(
                "Smoking Preference",
                style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: smokingPreference,
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Doesn't Matter",
                          style: appStyle(14, Kolors.kPrimary, FontWeight.normal)
                        ),
                        SizedBox(width: 8.w),
                        const Icon(Icons.smoking_rooms , color: Colors.black, size: 16)
                      ],
                    )
                  ),
                  const DropdownMenuItem(value: 'never', child: Text("Never")),
                  const DropdownMenuItem(value: 'rarely', child: Text("Rarely")),
                  const DropdownMenuItem(value: 'occasionally', child: Text("Occasionally")),
                  const DropdownMenuItem(value: 'regularly', child: Text("Regularly")),
                ],
                style: appStyle(12, Kolors.kDark, FontWeight.normal),
                onChanged: (value) {
                  setState(() {
                    smokingPreference = value!;
                  });
                },
                decoration: InputDecoration(
                  labelStyle: appStyle(12, Kolors.kGray, FontWeight.normal),
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

              const SizedBox(height: 8),

              Text(
                "Partying Preference",
                style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: partyingPreference,
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Doesn't Matter",
                          style: appStyle(14, Kolors.kPrimary, FontWeight.normal)
                        ),
                        SizedBox(width: 8.w),
                        const Icon(Icons.wine_bar , color: Colors.black, size: 16)
                      ],
                    )
                  ),
                  const DropdownMenuItem(value: 'never', child: Text("Never")),
                  const DropdownMenuItem(value: 'rarely', child: Text("Rarely")),
                  const DropdownMenuItem(value: 'occasionally', child: Text("Occasionally")),
                  const DropdownMenuItem(value: 'regularly', child: Text("Regularly")),
                ],
                style: appStyle(12, Kolors.kDark, FontWeight.normal),
                onChanged: (value) {
                  setState(() {
                    partyingPreference = value!;
                  });
                },
                decoration: InputDecoration(
                  labelStyle: appStyle(12, Kolors.kGray, FontWeight.normal),
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

              const SizedBox(height: 8),

              Text(
                "Dietary Preference",
                style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: dietaryPreference,
                items: [
                  DropdownMenuItem(
                    value: '', 
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Doesn't Matter",
                          style: appStyle(14, Kolors.kPrimary, FontWeight.normal)
                        ),
                        SizedBox(width: 8.w),
                        const Icon(Icons.lunch_dining , color: Colors.black, size: 16)
                      ],
                    )
                  ),
                  const DropdownMenuItem(value: 'veg', child: Text("Vegetarian")),
                  const DropdownMenuItem(value: 'non_veg', child: Text("Non Vegetarian")),
                  const DropdownMenuItem(value: 'vegan', child: Text("Vegan")),
                ],
                style: appStyle(12, Kolors.kDark, FontWeight.normal),
                onChanged: (value) {
                  setState(() {
                    dietaryPreference = value!;
                  });
                },
                decoration: InputDecoration(
                  labelStyle: appStyle(12, Kolors.kGray, FontWeight.normal),
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

              const SizedBox(height: 8),

              Text(
                "Nationality Preference",
                style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: nationalityPreference,
                items: [
                  DropdownMenuItem(
                    value: '', 
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Doesn't Matter",
                          style: appStyle(14, Kolors.kPrimary, FontWeight.normal)
                        ),
                        SizedBox(width: 8.w),
                        const Icon(Icons.groups_3_sharp , color: Colors.black, size: 16)
                      ],
                    )
                  ),
                  const DropdownMenuItem(value: 'indian', child: Text("Indian")),
                  const DropdownMenuItem(value: 'korean', child: Text("Korean")),
                  const DropdownMenuItem(value: 'chinese', child: Text("Chinese")),
                  const DropdownMenuItem(value: 'american', child: Text("American")),
                  const DropdownMenuItem(value: 'others', child: Text("Others")),
                  const DropdownMenuItem(value: 'mixed', child: Text("Mixed")),
                ],
                style: appStyle(12, Kolors.kDark, FontWeight.normal),
                onChanged: (value) {
                  setState(() {
                    nationalityPreference = value!;
                  });
                },
                decoration: InputDecoration(
                  labelStyle: appStyle(12, Kolors.kGray, FontWeight.normal),
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

              const SizedBox(height: 32),

              // Submit Button
              CustomButton(
                onTap: () async {
                  if (_validateForm()) {
                    String? accessToken = Storage().getString('accessToken');

                    // Process amenities
                    List<String> selectedAmenities = amenities.entries
                        .where((e) => e.value)
                        .map((e) => e.key.replaceAll(RegExp(r'^\p{So}\s*', unicode: true), '').trim())
                        .toList();

                    // Process lifestyle
                    Map<String, String> lifestyleData = {};
                    if (smoking.isNotEmpty) lifestyleData["smoking"] = smoking;
                    if (partying.isNotEmpty) lifestyleData["partying"] = partying;
                    if (dietary.isNotEmpty) lifestyleData["dietary"] = dietary;

                    // Process preference
                    Map<String, String> preferenceData = {};
                    if (genderPreference.isNotEmpty) preferenceData["gender_preference"] = genderPreference;
                    if (smokingPreference.isNotEmpty) preferenceData["smoking_preference"] = smokingPreference;
                    if (partyingPreference.isNotEmpty) preferenceData["partying_preference"] = partyingPreference;
                    if (dietaryPreference.isNotEmpty) preferenceData["dietary_preference"] = dietaryPreference;

                    final propertyData = {
                      "images": _images.map((image) => image.path).toList(),
                      "title": _titleController.text,
                      "description": _descriptionController.text,
                      "address": _addressController.text,
                      if (_unitController.text.isNotEmpty) "unit": _unitController.text,
                      if (_pincode != null) "pincode": _pincode,
                      if (_city != null) "city": _city,
                      if (_state != null) "state": _state,
                      if (_country != null) "country": _country,
                      if (_latitudeController.text.isNotEmpty) "latitude": double.tryParse(_latitudeController.text),
                      if (_longitudeController.text.isNotEmpty) "longitude": double.tryParse(_longitudeController.text),
                      "hide_address": _hideAddress,
                      "property_type": propertyType,
                      "listing_type": listingType,
                      "rent": double.tryParse(_rentController.text),
                      "rent_frequency": rentFrequency,
                      "furnished": furnished,
                      if (_squareFootageController.text.isNotEmpty) "square_footage": int.tryParse(_squareFootageController.text),
                      if (_bedroomsController.text.isNotEmpty) "bedrooms": int.tryParse(_bedroomsController.text),
                      if (_bathroomsController.text.isNotEmpty) "bathrooms": int.tryParse(_bathroomsController.text),
                      "sublease_details": {
                        "available_from": _availableFromController.text,
                        if (_availableTillController.text.isNotEmpty) "available_to": _availableTillController.text,
                        if (selectedSchoolIds.isNotEmpty) "school_ids": selectedSchoolIds,
                        "shared_room": true,
                      },
                      if (selectedAmenities.isNotEmpty) "amenities": selectedAmenities,
                      if (lifestyleData.isNotEmpty) "lifestyle": lifestyleData,
                      if (preferenceData.isNotEmpty) "preference": preferenceData,
                      "is_active": true,
                      "created_at": DateTime.now().toIso8601String(),
                      "updated_at": DateTime.now().toIso8601String(),
                    };
                    print("property data is: $propertyData");

                    if (accessToken != null) {
                      context.read<PropertyNotifier>().createProperty(
                        token: accessToken,
                        propertyData: propertyData,
                        onSuccess: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Property created successfully!")),
                          );
                          context.pop(); // Navigate back after success
                          context.read<PropertyNotifier>().fetchProperties();
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
                text: "Create Listing",
                btnWidth: ScreenUtil().screenWidth,
                btnHeight: 40,
                radius: 20,
              )
            ],
          ),
        ),
      ),
    );
  }
}