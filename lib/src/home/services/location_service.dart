import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Function to request permission
  Future<bool> _requestPermission() async {
    PermissionStatus status = await Permission.location.request();
    if (status == PermissionStatus.granted) {
      return true;
    } else if (status == PermissionStatus.denied) {
      return false;
    } else if (status == PermissionStatus.permanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return false;
  }

  // Function to get current location
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return Future.error('Location services are disabled. Please enable them.');
    }

    bool permissionGranted = await _requestPermission();
    if (!permissionGranted) {
      return Future.error('Location permissions are denied.');
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      return Future.error('Error getting location: $e');
    }
  }
}