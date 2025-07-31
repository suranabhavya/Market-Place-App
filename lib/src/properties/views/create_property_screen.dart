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
import 'package:marketplace_app/src/properties/services/property_service_v2.dart';
import 'package:marketplace_app/src/properties/models/autocomplete_prediction.dart';
import 'package:marketplace_app/src/properties/models/place_autocomplete_response.dart';
import 'package:marketplace_app/src/properties/models/property_detail_model.dart';
import 'package:marketplace_app/src/properties/widgets/location_list_tile.dart';
import 'package:marketplace_app/src/properties/widgets/property_image_picker.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../common/widgets/custom_dropdown.dart';
import '../../../common/widgets/custom_checkbox.dart';
import '../../../common/widgets/custom_switch.dart';
import '../../../common/widgets/custom_divider.dart';
import '../../../common/widgets/custom_text_field.dart';
import '../../../common/widgets/amenity_chip.dart';
import '../../../common/widgets/section_title.dart';
import '../../../common/widgets/custom_date_picker.dart';


class CreatePropertyPage extends StatefulWidget {
  final bool isEditing;
  final String? propertyId;
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>)? onSubmit;

  const CreatePropertyPage({
    super.key, 
    this.isEditing = false,
    this.propertyId,
    this.initialData,
    this.onSubmit,
  });

  @override
  State<CreatePropertyPage> createState() => _CreatePropertyPageState();
}

class _CreatePropertyPageState extends State<CreatePropertyPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

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
  // List to store existing images when editing (URLs)
  List<PropertyImage> _existingImages = [];
  // List to track removed image IDs
  final List<String> _deletedImages = [];

  List<AutocompletePrediction>? placePredictions = [];

  // Dropdown values
  String listingType = 'sublease';
  String rentFrequency = 'monthly';
  String propertyType = 'shared_room';
  String smoking = '';
  String partying = '';
  String dietary = '';
  String nationality = '';
  String genderPreference = 'any';
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
      if (source == ImageSource.gallery) {
        final List<XFile> pickedImages = await _picker.pickMultiImage(
          maxWidth: 800,  // Reduced from 1200
          maxHeight: 800, // Reduced from 1200
          imageQuality: 50, // Reduced from 70 for better compression
        );
        
        setState(() {
          _images.addAll(pickedImages.map((xFile) => File(xFile.path)));
        });
            } else {
        // For camera, we can't use pickMultiImage
        final XFile? pickedImage = await _picker.pickImage(
          source: source,
          maxWidth: 800,  // Reduced from 1200
          maxHeight: 800, // Reduced from 1200
          imageQuality: 50, // Reduced from 70 for better compression
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
  }

  // Alternative method using advanced compression (uncomment to use)
  // Future<void> _pickImageAdvanced(ImageSource source) async {
  //   try {
  //     if (source == ImageSource.gallery) {
  //       final List<File> compressedImages = await ImageCompressionUtil.pickAndCompressFromGallery(
  //         multiple: true,
  //         maxImages: 10, // Limit to 10 images
  //       );
  //       
  //       if (compressedImages.isNotEmpty) {
  //         setState(() {
  //           _images.addAll(compressedImages);
  //         });
  //       }
  //     } else {
  //       final File? compressedImage = await ImageCompressionUtil.pickAndCompressFromCamera();
  //       
  //       if (compressedImage != null) {
  //         setState(() {
  //           _images.add(compressedImage);
  //         });
  //       }
  //     }
  //   } catch (e) {
  //     print("Error picking and compressing images: $e");
  //   }
  // }

  // Method to remove an image
  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  // Method to remove an existing image
  void _removeExistingImage(int index) {
    debugPrint("Removing image at index $index");
    String imageId = _existingImages[index].id;
    setState(() {
      // Only add to deleted images if it's not a placeholder and not empty
      if (imageId.isNotEmpty) {
        _deletedImages.add(imageId);
      }
      _existingImages.removeAt(index);
    });
    debugPrint("Current deleted images: $_deletedImages");
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
      debugPrint("Error fetching nearby schools: $e");
    }
  }

  // Function to fetch place details (lat/lng) based on the place_id
  Future<void> fetchPlaceDetails(String placeId) async {
    final messenger = ScaffoldMessenger.of(context);
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
        messenger.showSnackBar(
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
    String url = '${Environment.iosAppBaseUrl}/api/amenities/';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        List<dynamic> data = json.decode(responseBody);

        setState(() {
          // Initialize all amenities as false
          amenities = {for (var item in data) item["name"]: false};
          
          // If editing mode and we have initial data with amenities
          if (widget.isEditing && widget.initialData != null && widget.initialData!['amenities'] != null) {
            List<dynamic> selectedAmenities = widget.initialData!['amenities'];
            
            // Mark selected amenities as true
            for (String amenity in selectedAmenities) {
              if (amenities.containsKey(amenity)) {
                amenities[amenity] = true;
              }
            }
          }
        });
      } else {
        throw Exception("Failed to load amenities");
      }
    } catch (e) {
      debugPrint("Error fetching amenities: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchSchools();
    _fetchAmenities();

    // If editing, populate form with initial data
    if (widget.isEditing && widget.initialData != null) {
      final data = widget.initialData!;
      
      // Populate text fields
      _titleController.text = data['title'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _addressController.text = data['address'] ?? '';
      _unitController.text = data['unit'] ?? '';
      _latitudeController.text = data['latitude']?.toString() ?? '';
      _longitudeController.text = data['longitude']?.toString() ?? '';
      _rentController.text = data['rent']?.toString() ?? '';
      _squareFootageController.text = data['square_footage']?.toString() ?? '';
      _bedroomsController.text = data['bedrooms']?.toString() ?? '';
      _bathroomsController.text = data['bathrooms']?.toString() ?? '';
      
      // Set location fields
      _pincode = data['pincode'];
      _city = data['city'];
      _state = data['state'];
      _country = data['country'];
      
      // Set dropdown values
      listingType = data['listing_type'] ?? 'sublease';
      rentFrequency = data['rent_frequency'] ?? 'monthly';
      propertyType = data['property_type'] ?? 'shared_room';
      furnished = data['furnished'] ?? false;
      _hideAddress = data['hide_address'] ?? false;

      // Load existing images
      if (data['images'] != null && data['images'] is List) {
        _existingImages = (data['images'] as List)
            .map<PropertyImage>((img) => img is Map<String, dynamic>
                ? PropertyImage.fromJson(img)
                : PropertyImage(id: '', url: img.toString()))
            .toList();
      }

      // Handle sublease details
      if (data['sublease_details'] != null) {
        _availableFromController.text = data['sublease_details']['available_from'] ?? '';
        _availableTillController.text = data['sublease_details']['available_to'] ?? '';
        
        // Handle schools
        if (data['sublease_details']['schools_nearby'] != null) {
          selectedSchoolIds = (data['sublease_details']['schools_nearby'] as List)
              .map((school) => school['id'].toString())
              .toList();
          
          for (var school in data['sublease_details']['schools_nearby']) {
            _selectedSchoolsMap[school['id']] = {
              'id': school['id'],
              'name': school['name']
            };
          }
        }
      }

      // Handle lifestyle preferences
      if (data['lifestyle'] != null) {
        smoking = data['lifestyle']['smoking'] ?? '';
        partying = data['lifestyle']['partying'] ?? '';
        dietary = data['lifestyle']['dietary'] ?? '';
        nationality = data['lifestyle']['nationality'] ?? '';
      }

      // Handle preferences
      genderPreference = data['preference']?['gender_preference'] ?? 'any';
      smokingPreference = data['preference']?['smoking_preference'] ?? '';
      partyingPreference = data['preference']?['partying_preference'] ?? '';
      dietaryPreference = data['preference']?['dietary_preference'] ?? '';
      nationalityPreference = data['preference']?['nationality_preference'] ?? '';
    } else {
      // Set default available_from to today's date if not editing
      DateTime today = DateTime.now();
      _availableFromController.text =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    }
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

  void _handleSubmit() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Process amenities
      List<String> selectedAmenities = amenities.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      // Process lifestyle and preference data only for shared_room and private_room
      Map<String, dynamic>? lifestyleData;
      Map<String, dynamic>? preferenceData;

      if (propertyType == 'shared_room' || propertyType == 'private_room') {
        // Process lifestyle
        lifestyleData = {
          if (smoking.isNotEmpty) 'smoking': smoking,
          if (partying.isNotEmpty) 'partying': partying,
          if (dietary.isNotEmpty) 'dietary': dietary,
          if (nationality.isNotEmpty) 'nationality': nationality,
        };

        // Process preference
        preferenceData = {
          if (genderPreference.isNotEmpty) 'gender_preference': genderPreference,
          if (smokingPreference.isNotEmpty) 'smoking_preference': smokingPreference,
          if (partyingPreference.isNotEmpty) 'partying_preference': partyingPreference,
          if (dietaryPreference.isNotEmpty) 'dietary_preference': dietaryPreference,
          if (nationalityPreference.isNotEmpty) 'nationality_preference': nationalityPreference,
        };
      }

      // Create sublease details object
      Map<String, dynamic> subleaseDetails = {
        'available_from': _availableFromController.text,
        if (_availableTillController.text.isNotEmpty) 'available_to': _availableTillController.text,
        if (selectedSchoolIds.isNotEmpty) 'school_ids': selectedSchoolIds,
        'shared_room': false,
      };

      // Create property data map
      Map<String, dynamic> propertyData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'address': _addressController.text,
        if (_unitController.text.isNotEmpty) 'unit': _unitController.text,
        if (_latitudeController.text.isNotEmpty) 'latitude': double.tryParse(_latitudeController.text),
        if (_longitudeController.text.isNotEmpty) 'longitude': double.tryParse(_longitudeController.text),
        if (_pincode != null) 'pincode': _pincode,
        if (_city != null) 'city': _city,
        if (_state != null) 'state': _state,
        if (_country != null) 'country': _country,
        'rent': double.tryParse(_rentController.text) ?? 0.0,
        'rent_frequency': rentFrequency,
        'property_type': propertyType,
        'listing_type': listingType,
        'furnished': furnished,
        if (_bedroomsController.text.isNotEmpty) 'bedrooms': int.tryParse(_bedroomsController.text),
        if (_bathroomsController.text.isNotEmpty) 'bathrooms': int.tryParse(_bathroomsController.text),
        if (_squareFootageController.text.isNotEmpty) 'square_footage': int.tryParse(_squareFootageController.text),
        'hide_address': _hideAddress,
        'sublease_details': subleaseDetails,
        if (selectedAmenities.isNotEmpty) 'amenities': selectedAmenities,
        if (lifestyleData?.isNotEmpty ?? false) 'lifestyle': lifestyleData,
        if (preferenceData?.isNotEmpty ?? false) 'preference': preferenceData,
      };

      if (widget.isEditing && widget.propertyId != null) {
        // For editing, the PropertyServiceV2 will handle image uploads and deletions
        try {
          // Get the access token
          String? accessToken = Storage().getString('accessToken');
          if (accessToken == null) {
            throw Exception("User not authenticated");
          }

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

          // Update property using PropertyServiceV2
          await PropertyServiceV2.updateProperty(
            propertyId: widget.propertyId!,
            propertyData: propertyData,
            images: _images,
            userId: userId,
            deletedImages: _deletedImages.isNotEmpty ? _deletedImages : null,
            onProgress: (progress) {
              debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
            },
          ).then((result) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Property updated successfully!")),
              );
              context.pop();
              context.read<PropertyNotifier>().fetchProperties();
            }
          }).catchError((error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed to update property: $error")),
              );
            }
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to update property: $e")),
            );
          }
        }
      } else {
        // Create new property using Google Cloud Storage
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
        await PropertyServiceV2.createProperty(
          propertyData: propertyData,
          images: _images,
          userId: userId,
          onProgress: (progress) {
            debugPrint('Upload progress: \\${(progress * 100).toStringAsFixed(1)}%');
          },
        ).then((result) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Property created successfully!")),
            );
            context.pop();
            context.read<PropertyNotifier>().fetchProperties();
          }
        }).catchError((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to create property: $error")),
            );
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          text: widget.isEditing ? "Edit Property" : AppText.kCreateListing,
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
                existingImages: _existingImages,
                onPickImage: _pickImage,
                onRemoveImage: _removeImage,
                onRemoveExistingImage: _removeExistingImage,
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _titleController,
                labelText: "Title",
                isRequired: true,
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

              CustomTextField(
                controller: _descriptionController,
                labelText: "Description",
                isRequired: true,
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

              CustomTextField(
                controller: _unitController,
                labelText: "Unit / Apartment",
                maxLines: 1,
                hintText: "Enter Unit / Apartment",
                keyboardType: TextInputType.name,
                prefixIcon: const Icon(
                  CupertinoIcons.building_2_fill,
                  size: 20,
                  color: Kolors.kGray,
                ),
              ),

              const SizedBox(height: 16),

              CustomCheckbox(
                value: _hideAddress,
                onChanged: (bool? value) {
                  setState(() {
                    _hideAddress = value ?? false;
                  });
                },
                label: "Hide Address",
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

              CustomDropdown<String>(
                value: propertyType,
                items: const [
                  DropdownMenuItem(value: 'private_room', child: Text("Private Room")),
                  DropdownMenuItem(value: 'shared_room', child: Text("Shared Room")),
                  DropdownMenuItem(value: 'apartment', child: Text("Apartment")),
                ],
                onChanged: (value) {
                  setState(() {
                    propertyType = value!;
                  });
                },
                labelText: "Property Type",
                isRequired: true,
              ),

              const SizedBox(height: 16),

              CustomDropdown<String>(
                value: listingType,
                items: const [
                  DropdownMenuItem(value: 'sublease', child: Text("Sublease")),
                  DropdownMenuItem(value: 'rent', child: Text("Rent")),
                ],
                onChanged: (value) {
                  setState(() {
                    listingType = value!;
                  });
                },
                labelText: "Listing Type",
                isRequired: true,
              ),

              const SizedBox(height: 16),

              // Available From Date Picker
              Row(
                children: [
                  Expanded(
                    child: CustomDatePicker(
                      controller: _availableFromController,
                      labelText: "Available From",
                      isRequired: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Available From is required.";
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomDatePicker(
                      controller: _availableTillController,
                      labelText: "Available Till",
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
                        CustomTextField(
                          controller: _rentController,
                          labelText: "Rent",
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
                          isRequired: true,
                        ),
                      ]
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomDropdown<String>(
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
                          labelText: "Rent Frequency",
                          isRequired: true,
                        ),
                      ]
                    ),
                  )
                ]
              ),

              const SizedBox(height: 16),

              // Furnished Checkbox
              CustomSwitch(
                value: furnished,
                onChanged: (bool value) {
                  setState(() {
                    furnished = value;
                  });
                },
                label: "Furnished",
              ),

              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: _squareFootageController,
                    labelText: "Square Footage Area",
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
                        CustomTextField(
                          controller: _bedroomsController,
                          labelText: "Bedrooms",
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
                        CustomTextField(
                          controller: _bathroomsController,
                          labelText: "Bathrooms",
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

              CustomDivider(
                height: 1,
                thickness: 0.5.h,
                color: Kolors.kGrayLight,
              ),

              const SizedBox(height: 16),

              const SectionTitle(
                title: "Amenities (Optional)",
              ),

              const SizedBox(height: 16),

              amenities.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: amenities.keys.map((String key) {
                      bool isSelected = amenities[key]!;
                                              return AmenityChip(
                          label: key,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              amenities[key] = !isSelected;
                            });
                          },
                        );
                    }).toList(),
                  ),

              const SizedBox(height: 16),

              CustomDivider(
                height: 1,
                thickness: 0.5.h,
                color: Kolors.kGrayLight,
              ),

              // Only show Lifestyle and Preference sections for shared_room and private_room
              if (propertyType == 'shared_room' || propertyType == 'private_room') ...[
                const SizedBox(height: 16),

                const SectionTitle(
                  title: "Lifestyle (Optional)",
                ),

                const SizedBox(height: 16),

                CustomDropdown<String>(
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
                          const Icon(Icons.smoking_rooms, color: Colors.black, size: 16)
                        ],
                      )
                    ),
                    const DropdownMenuItem(value: 'never', child: Text("Never")),
                    const DropdownMenuItem(value: 'rarely', child: Text("Rarely")),
                    const DropdownMenuItem(value: 'occasionally', child: Text("Occasionally")),
                    const DropdownMenuItem(value: 'regularly', child: Text("Regularly")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      smoking = value!;
                    });
                  },
                  labelText: "Smoking",
                ),

                const SizedBox(height: 8),

                CustomDropdown<String>(
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
                          const Icon(Icons.wine_bar, color: Colors.black, size: 16)
                        ],
                      )
                    ),
                    const DropdownMenuItem(value: 'never', child: Text("Never")),
                    const DropdownMenuItem(value: 'rarely', child: Text("Rarely")),
                    const DropdownMenuItem(value: 'occasionally', child: Text("Occasionally")),
                    const DropdownMenuItem(value: 'regularly', child: Text("Regularly")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      partying = value!;
                    });
                  },
                  labelText: "Partying",
                ),

                const SizedBox(height: 8),

                CustomDropdown<String>(
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
                          const Icon(Icons.lunch_dining, color: Colors.black, size: 16)
                        ],
                      )
                    ),
                    const DropdownMenuItem(value: 'veg', child: Text("Vegetarian")),
                    const DropdownMenuItem(value: 'non_veg', child: Text("Non Vegetarian")),
                    const DropdownMenuItem(value: 'vegan', child: Text("Vegan")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      dietary = value!;
                    });
                  },
                  labelText: "Dietary",
                ),

                const SizedBox(height: 8),

                CustomDropdown<String>(
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
                          const Icon(Icons.groups_3_sharp, color: Colors.black, size: 16)
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
                  onChanged: (value) {
                    setState(() {
                      nationality = value!;
                    });
                  },
                  labelText: "Nationality",
                ),

                const SizedBox(height: 16),

                CustomDivider(
                  height: 1,
                  thickness: 0.5.h,
                  color: Kolors.kGrayLight,
                ),

                const SizedBox(height: 16),

                const SectionTitle(
                  title: "Preference (Optional)",
                ),

                const SizedBox(height: 16),

                CustomDropdown<String>(
                  value: genderPreference,
                  items: [
                    DropdownMenuItem(
                      value: 'any',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "Any",
                            style: appStyle(14, Kolors.kPrimary, FontWeight.normal)
                          ),
                          SizedBox(width: 8.w),
                          const Icon(Icons.people, color: Colors.black, size: 16)
                        ],
                      )
                    ),
                    const DropdownMenuItem(value: 'boys', child: Text("Boys Only")),
                    const DropdownMenuItem(value: 'girls', child: Text("Girls Only")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      genderPreference = value!;
                    });
                  },
                  labelText: "Gender Preference",
                ),

                const SizedBox(height: 8),

                CustomDropdown<String>(
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
                          const Icon(Icons.smoking_rooms, color: Colors.black, size: 16)
                        ],
                      )
                    ),
                    const DropdownMenuItem(value: 'never', child: Text("Never")),
                    const DropdownMenuItem(value: 'rarely', child: Text("Rarely")),
                    const DropdownMenuItem(value: 'occasionally', child: Text("Occasionally")),
                    const DropdownMenuItem(value: 'regularly', child: Text("Regularly")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      smokingPreference = value!;
                    });
                  },
                  labelText: "Smoking Preference",
                ),

                const SizedBox(height: 8),

                CustomDropdown<String>(
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
                          const Icon(Icons.wine_bar, color: Colors.black, size: 16)
                        ],
                      )
                    ),
                    const DropdownMenuItem(value: 'never', child: Text("Never")),
                    const DropdownMenuItem(value: 'rarely', child: Text("Rarely")),
                    const DropdownMenuItem(value: 'occasionally', child: Text("Occasionally")),
                    const DropdownMenuItem(value: 'regularly', child: Text("Regularly")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      partyingPreference = value!;
                    });
                  },
                  labelText: "Partying Preference",
                ),

                const SizedBox(height: 8),

                CustomDropdown<String>(
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
                          const Icon(Icons.lunch_dining, color: Colors.black, size: 16)
                        ],
                      )
                    ),
                    const DropdownMenuItem(value: 'veg', child: Text("Vegetarian")),
                    const DropdownMenuItem(value: 'non_veg', child: Text("Non Vegetarian")),
                    const DropdownMenuItem(value: 'vegan', child: Text("Vegan")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      dietaryPreference = value!;
                    });
                  },
                  labelText: "Dietary Preference",
                ),

                const SizedBox(height: 8),

                CustomDropdown<String>(
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
                          const Icon(Icons.groups_3_sharp, color: Colors.black, size: 16)
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
                  onChanged: (value) {
                    setState(() {
                      nationalityPreference = value!;
                    });
                  },
                  labelText: "Nationality Preference",
                ),
              ],

              const SizedBox(height: 32),

              // Info box about furniture attachment
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Kolors.kPrimaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Kolors.kPrimaryLight.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Kolors.kPrimary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "💡 Pro Tip: Sell Furniture with Your Property",
                            style: appStyle(13, Kolors.kPrimary, FontWeight.w600),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            "Want to include furniture with your property? Simply list your furniture items in the Marketplace and link them to this property during the listing process. This helps tenants see exactly what's included!",
                            style: appStyle(12, Kolors.kGray, FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              CustomButton(
                onTap: _isLoading ? null : _handleSubmit,
                text: widget.isEditing ? "Update Property" : "Create Listing",
                btnWidth: ScreenUtil().screenWidth,
                btnHeight: 40,
                radius: 20,
                isLoading: _isLoading,
              )
            ],
          ),
        ),
      ),
    );
  }
}