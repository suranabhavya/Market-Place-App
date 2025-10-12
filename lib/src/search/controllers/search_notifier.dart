import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/src/properties/models/property_list_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchNotifier with ChangeNotifier {
  bool _isLoading = false;
  bool _isAutocompleteLoading = false;
  Map<String, List<String>> _autocompleteResults = {};

  bool get isLoading => _isLoading;
  bool get isAutocompleteLoading => _isAutocompleteLoading;
  Map<String, List<String>> get autocompleteResults => _autocompleteResults;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void setAutocompleteLoading(bool value) {
    _isAutocompleteLoading = value;
    notifyListeners();
  }
  
  void setAutocompleteResults(Map<String, List<String>> results) {
    _autocompleteResults = results;
    notifyListeners();
  }
  
  void clearAutocompleteResults() {
    _autocompleteResults = {};
    notifyListeners();
  }

  List<PropertyListModel> _results = [];

  List<PropertyListModel> get results => _results;

  void setResults(List<PropertyListModel> value) {
    _results = value;
    notifyListeners();
  }

  void clearResults() {
    _results = [];
    notifyListeners();
  }

  String _searchKey = '';

  String get searchKey => _searchKey;

  void setSearchKey(String value) {
    _searchKey = value;
    notifyListeners();
  }

  String? _error;

  String get error => _error??'';

  void setError(String value) {
    _error = value;
    notifyListeners();
  }

  // Fetch autocomplete suggestions
  Future<void> fetchAutocomplete(String query) async {
    if (query.isEmpty) {
      clearAutocompleteResults();
      return;
    }
    
    setAutocompleteLoading(true);
    debugPrint('Fetching autocomplete for query: $query');
    
    try {
      final url = '${Environment.baseUrl}/api/autocomplete/?q=$query';
      debugPrint('Autocomplete URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
      );
      
      if (response.statusCode == 200) {
        debugPrint('Autocomplete response: ${response.body}');
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Convert the dynamic values to List<String>
        Map<String, List<String>> results = {};
        data.forEach((key, value) {
          if (value is List) {
            // Filter out null values and convert everything to strings
            results[key] = value
                .where((item) => item != null)
                .map<String>((item) => item?.toString() ?? '')
                .where((item) => item.isNotEmpty)
                .toList();
            
            debugPrint('Category $key has ${results[key]?.length ?? 0} items');
          }
        });
        
        setAutocompleteResults(results);
      } else {
        debugPrint('Failed to fetch autocomplete: ${response.statusCode} - ${response.body}');
        setError('Failed to fetch autocomplete results');
      }
    } catch (e) {
      debugPrint('Error fetching autocomplete: $e');
      setError(e.toString());
    } finally {
      setAutocompleteLoading(false);
    }
  }

  void searchFunction(String searchKey, BuildContext context) async {
    setLoading(true);
    setSearchKey(searchKey);
    clearAutocompleteResults(); // Clear autocomplete when performing search

    Uri url = Uri.parse('${Environment.baseUrl}/api/properties/?search=$searchKey');

    try {
      var response = await http.get(url);

      if(response.statusCode == 200) {
        var searchProperties = propertyListModelFromJson(response.body);
        notifyListeners();
        if (context.mounted) {
          context.go('/home', extra: searchProperties);
        }
        setResults(searchProperties);
        setLoading(false);
      }
    } catch(e) {
      setError(e.toString());
      setLoading(false);
    }
  }
}