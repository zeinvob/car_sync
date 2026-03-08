import 'package:geolocator/geolocator.dart';

/// GLOBAL LOCATION SERVICE
class LocationService {
  Future<bool> _ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    final allowed = await _ensurePermission();
    if (!allowed) return null;

    return await Geolocator.getCurrentPosition();
  }
}