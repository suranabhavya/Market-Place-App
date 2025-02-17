import 'package:flutter/material.dart';
import 'package:marketplace_app/common/utils/enums.dart';
import 'package:geolocator/geolocator.dart';
import 'package:marketplace_app/src/properties/controllers/property_notifier.dart';

class HomeTabNotifier with ChangeNotifier {
  QueryType queryType = QueryType.all;
  String _index = 'All';
  double? userLatitude;
  double? userLongitude;

  String get index => _index;

  void setUserLocation(double lat, double lng) {
    userLatitude = lat;
    userLongitude = lng;
  }

  void setIndex(String index, PropertyNotifier propertyNotifier) async {
    _index = index;

    switch(index) {
      case 'All':
        setQueryType(QueryType.all);
        propertyNotifier.fetchProperties();
        break;
      case 'School':
        setQueryType(QueryType.school);
        break;
      case 'Nearby':
        // await _fetchUserLocation();
        setQueryType(QueryType.nearby);
        if (userLatitude != null && userLongitude != null) {
          propertyNotifier.fetchProperties(lat: userLatitude, lng: userLongitude);
        }
        break;
      default:
        setQueryType(QueryType.all);
        propertyNotifier.fetchProperties();
    }

    notifyListeners();
  }

  void setQueryType(QueryType q) {
    queryType = q;
  }

  // Future<void> _fetchUserLocation() async {
  //   try {
  //     Position position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high,
  //     );
  //     userLatitude = position.latitude;
  //     userLongitude = position.longitude;
  //   } catch (e) {
  //     print("Error getting location: $e");
  //   }
  // }
}