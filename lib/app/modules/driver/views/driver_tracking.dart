// screens/driver/driver_tracking.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';

class DriverTracking extends StatefulWidget {
  const DriverTracking({Key? key}) : super(key: key);

  @override
  State<DriverTracking> createState() => _DriverTrackingState();
}

class _DriverTrackingState extends State<DriverTracking> {
  GoogleMapController? _mapController;
  Timer? _locationTimer;

  // Booking Data
  late Map<String, dynamic> bookingData;
  late Map<String, dynamic> patientDetails;
  late Map<String, dynamic> patientUser;

  late int bookingId;
  late double pickupLat, pickupLng, dropLat, dropLng;
  late String pickupAddress, dropAddress;
  late String patientName, patientPhone;

  String? patientPhotoUrl;

  // Live Tracking
  LatLng? currentAmbulanceLatLng;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  bool isLoadingLocation = true;
  String statusMessage = "Sending location...";

  @override
  void initState() {
    super.initState();
    _extractArguments();
    _startLiveLocationPolling();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _extractArguments() {
    if (Get.arguments == null || Get.arguments is! Map) {
      Get.back();
      customToast("Invalid booking data", Colors.red);
      return;
    }

    bookingData = Map<String, dynamic>.from(Get.arguments);
    patientDetails = bookingData["patient_details"] ?? {};
    patientUser = patientDetails["user"] ?? {};

    bookingId = bookingData["ambulance_booking_id"] ?? 0;

    // Coordinates
    pickupLat = (bookingData["pickup_latitude"] ?? 18.5204).toDouble();
    pickupLng = (bookingData["pickup_longitude"] ?? 73.8567).toDouble();
    dropLat = (bookingData["drop_latitude"] ?? 18.5303).toDouble();
    dropLng = (bookingData["drop_longitude"] ?? 73.8768).toDouble();

    pickupAddress = bookingData["pickup_location"] ?? "Pickup Location";
    dropAddress = bookingData["drop_location"] ?? "Drop Location";

    // Patient Info
    patientName =
        '${patientUser["first_name"] ?? ''} ${patientUser["last_name"] ?? ''}'
            .trim();
    if (patientName.isEmpty) patientName = "Patient";

    patientPhone = patientUser["phone_number"] ?? "Unknown";

    patientPhotoUrl = patientUser["profile_image_name"];

    // Initial tracking position
    final tracking =
        bookingData["ambulance_tracking_details"] as List<dynamic>?;
    if (tracking != null && tracking.isNotEmpty) {
      final last = tracking.last;
      final lat = double.tryParse(last["current_lat"]?.toString() ?? "");
      final lng = double.tryParse(last["current_long"]?.toString() ?? "");
      if (lat != null && lng != null && lat != 0 && lng != 0) {
        currentAmbulanceLatLng = LatLng(lat, lng);
        isLoadingLocation = false;
        statusMessage = "Live • ${last['status'].toUpperCase()}";
      }
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        customToast("Please enable location services", Colors.red);
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        customToast("Location permission denied permanently", Colors.red);
        return null;
      }

      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      debugPrint("Location error: $e");
      return null;
    }
  }

  void _startLiveLocationPolling() {
    _sendCurrentLocation();
    _locationTimer = Timer.periodic(
        const Duration(seconds: 8), (_) => _sendCurrentLocation());
  }

  /// Send current location to server (Driver side)
  Future<void> _sendCurrentLocation() async {
    final position = await _getCurrentLocation();
    if (position == null) {
      setState(() => statusMessage = "Location unavailable");
      return;
    }

    try {
      final token = await readStr('token');

      final response = await http.post(
        Uri.parse("${AppConstants.endpoint}/ambulances/tracking"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "ambulance_booking_id": bookingId,
          "current_lat": position.latitude,
          "current_long": position.longitude,
          "status": "enroute",
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body["status"] == true) {
          setState(() {
            currentAmbulanceLatLng =
                LatLng(position.latitude, position.longitude);
            isLoadingLocation = false;
            statusMessage = "Live • ENROUTE";
          });
          _updateMap();
        }
      }
    } catch (e) {
      debugPrint("Send location error: $e");
      setState(() => statusMessage = "Sending location...");
    }
  }

  Future<void> _updateMap() async {
    if (currentAmbulanceLatLng == null) return;

    final ambulanceIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(100, 100)),
      'assets/image/ambulance.png',
    );

    final hospitalIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(100, 100)),
      'assets/image/hospital.png',
    );

    setState(() {
      markers = {
        Marker(
          markerId: const MarkerId("ambulance"),
          position: currentAmbulanceLatLng!,
          icon: ambulanceIcon,
          infoWindow: const InfoWindow(
              title: "Your Ambulance", snippet: "Live Location"),
          zIndex: 10,
        ),
        Marker(
          markerId: const MarkerId("pickup"),
          position: LatLng(pickupLat, pickupLng),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: "Pickup", snippet: pickupAddress),
        ),
        Marker(
          markerId: const MarkerId("drop"),
          position: LatLng(dropLat, dropLng),
          icon: hospitalIcon,
          infoWindow: InfoWindow(title: "Hospital", snippet: dropAddress),
        ),
      };
    });

    polylines.clear();

    await _drawRoute(currentAmbulanceLatLng!, LatLng(pickupLat, pickupLng),
        Colors.red.shade600, 8, "current_to_pickup");
    await _drawRoute(LatLng(pickupLat, pickupLng), LatLng(dropLat, dropLng),
        AppConstants.appPrimaryColor, 7, "pickup_to_drop");

    _fitCameraToBounds();
  }

  Future<void> _drawRoute(LatLng origin, LatLng destination, Color color,
      int width, String id) async {
    final url = "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${origin.latitude},${origin.longitude}"
        "&destination=${destination.latitude},${destination.longitude}"
        "&key=${AppConstants.googleApiKey}";

    try {
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);
      if (data["status"] == "OK") {
        final points = data["routes"][0]["overview_polyline"]["points"];
        final List<LatLng> polyPoints = _decodePolyline(points);

        setState(() {
          polylines.add(Polyline(
            polylineId: PolylineId(id),
            color: color,
            width: width,
            points: polyPoints,
            jointType: JointType.round,
          ));
        });
      }
    } catch (e) {
      debugPrint("Route error: $e");
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  void _fitCameraToBounds() async {
    if (_mapController == null || currentAmbulanceLatLng == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        [currentAmbulanceLatLng!.latitude, pickupLat, dropLat].reduce(min),
        [currentAmbulanceLatLng!.longitude, pickupLng, dropLng].reduce(min),
      ),
      northeast: LatLng(
        [currentAmbulanceLatLng!.latitude, pickupLat, dropLat].reduce(max),
        [currentAmbulanceLatLng!.longitude, pickupLng, dropLng].reduce(max),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 400));
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  Widget _patientImageWidget() {
    if (patientPhotoUrl == null || patientPhotoUrl!.isEmpty) {
      return Container(
        width: 90,
        height: 90,
        decoration:
            BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
        child: const Icon(Icons.person, size: 50, color: Colors.grey),
      );
    }

    return ClipOval(
      child: Image.network(
        patientPhotoUrl!,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator())),
        errorBuilder: (_, __, ___) => Container(
            width: 90,
            height: 90,
            decoration:
                BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
            child: const Icon(Icons.person, size: 50)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                  target:
                      currentAmbulanceLatLng ?? LatLng(pickupLat, pickupLng),
                  zoom: 13),
              onMapCreated: (c) => _mapController = c,
              markers: markers,
              polylines: polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
            ),

            // Top Buttons
            Positioned(
              top: MediaQuery.of(context).padding.top - 15,
              left: 20,
              right: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circleButton(
                      Icons.arrow_back, Colors.black87, () => Get.back()),
                  _circleButton(Icons.phone, Colors.green,
                      () => launchPhoneCall(patientPhone)),
                ],
              ),
            ),

            // Status Banner
            Positioned(
              top: MediaQuery.of(context).padding.top + 35,
              left: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2), blurRadius: 12)
                    ]),
                child: Row(
                  children: [
                    Icon(
                        isLoadingLocation
                            ? Icons.hourglass_empty
                            : Icons.circle,
                        color: isLoadingLocation ? Colors.orange : Colors.green,
                        size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Text(statusMessage,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15))),
                    Text("ID #$bookingId",
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
            ),

            // Bottom Patient Card
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _patientImageWidget(),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(patientName,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text("Phone: $patientPhone",
                                    style: const TextStyle(fontSize: 15)),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(30)),
                                  child: const Text("LIVE TRACKING ACTIVE",
                                      style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30, thickness: 1),
                      _locationInfo(
                          Icons.my_location, "Pickup From", pickupAddress),
                      const SizedBox(height: 16),
                      _locationInfo(Icons.flag, "Drop Off At", dropAddress),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationInfo(IconData icon, String title, String address) {
    return Row(
      children: [
        Icon(icon, color: AppConstants.appPrimaryColor, size: 30),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const SizedBox(height: 6),
              Text(address,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      height: 40,
      width: 40,
      decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
          ]),
      child: IconButton(
          icon: Icon(icon, color: color, size: 24), onPressed: onTap),
    );
  }
}
