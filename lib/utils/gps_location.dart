import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

Future<Map<String, String>> getCurrentLocation() async {
  try {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return {"location": "Permission Denied", "latitude": "", "longitude": ""};
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      String address =
          "${place.name}, ${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country} - ${place.postalCode}";

      return {
        "location": address,
        "latitude": position.latitude.toString(),
        "longitude": position.longitude.toString(),
      };
    }
  } catch (e) {
    print("Error fetching location: $e");
  }

  return {"location": "Unknown Location", "latitude": "", "longitude": ""};
}
