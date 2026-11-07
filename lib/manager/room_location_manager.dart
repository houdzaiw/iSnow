import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../model/server_response.dart';

typedef RoomLocation = ({double longitude, double latitude, String address});

class RoomLocationManager {
  const RoomLocationManager();

  Future<RoomLocation> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const NadyApiException(
        message: 'Turn on location services to continue',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw const NadyApiException(
        message: 'Allow location access in device Settings to continue',
      );
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 15),
      ),
    );
    // Room location is city-level; never send full GPS precision.
    final latitude = double.parse(position.latitude.toStringAsFixed(2));
    final longitude = double.parse(position.longitude.toStringAsFixed(2));
    var address = '';
    try {
      final marks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 5));
      final place = marks.firstOrNull;
      if (place != null) {
        address = {place.locality, place.administrativeArea, place.country}
            .whereType<String>()
            .where((value) => value.trim().isNotEmpty)
            .join(', ');
      }
    } catch (_) {
      // Coordinates alone are a valid saved location.
    }
    return (longitude: longitude, latitude: latitude, address: address);
  }
}
