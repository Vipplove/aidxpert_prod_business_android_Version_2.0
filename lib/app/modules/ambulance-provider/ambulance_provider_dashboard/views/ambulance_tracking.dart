// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';

class AmbulanceTracking extends StatefulWidget {
  const AmbulanceTracking({Key? key}) : super(key: key);

  @override
  State<AmbulanceTracking> createState() => _AmbulanceTrackingState();
}

class _AmbulanceTrackingState extends State<AmbulanceTracking> {
  GoogleMapController? _mapController;
  Timer? _locationTimer;

  // Full data
  late Map<String, dynamic> bookingData;
  late Map<String, dynamic> ambulanceDetails;

  late int bookingId;
  late int ambulanceId;

  late double pickupLat, pickupLng, dropLat, dropLng;
  late String pickupAddress, dropAddress;
  late String vehicleNumber, driverName, driverContact;

  String? ambulancePhotoUrl; // <-- Now safely extracted

  // Live tracking
  LatLng? currentAmbulanceLatLng;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  bool isLoadingLocation = true;
  String statusMessage = "Fetching ambulance location...";

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

  // FIXED: Safe extraction for both string and list photos
  void _extractArguments() {
    if (Get.arguments == null || Get.arguments is! Map) {
      Get.back();
      customToast("Invalid booking data", Colors.red);
      return;
    }

    bookingData = Map<String, dynamic>.from(Get.arguments);
    ambulanceDetails = bookingData["ambulance_details"] ?? {};

    bookingId = bookingData["ambulance_booking_id"] ?? 0;
    ambulanceId = bookingData["ambulance_id"] ?? 0;

    pickupLat = (bookingData["pickup_latitude"] ?? 18.5204).toDouble();
    pickupLng = (bookingData["pickup_longitude"] ?? 73.8567).toDouble();
    dropLat = (bookingData["drop_latitude"] ?? 18.5069).toDouble();
    dropLng = (bookingData["drop_longitude"] ?? 73.8998).toDouble();

    pickupAddress = bookingData["pickup_location"] ?? "Pickup Location";
    dropAddress = bookingData["drop_location"] ?? "Drop Location";

    vehicleNumber = ambulanceDetails["vehicle_number"] ?? "MH00AA0000";
    driverName = ambulanceDetails["driver_name"] ?? "Driver";
    driverContact = ambulanceDetails["driver_contact"] ?? "Unknown";

    // THE FIX: Handle both String and List for ambulance_photos
    final photos = ambulanceDetails["ambulance_photos"];
    if (photos != null) {
      if (photos is String) {
        // Old format: JSON string
        try {
          final List<dynamic> list = jsonDecode(photos);
          ambulancePhotoUrl = list.isNotEmpty ? list.first?.toString() : null;
        } catch (e) {
          ambulancePhotoUrl = null;
        }
      } else if (photos is List && photos.isNotEmpty) {
        // New format: Already a List
        ambulancePhotoUrl = photos.first?.toString();
      }
    }
  }

  void _startLiveLocationPolling() {
    _fetchCurrentLocation();
    _locationTimer = Timer.periodic(
        const Duration(seconds: 5), (_) => _fetchCurrentLocation());
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final token = await readStr('token');
      final url = "${AppConstants.endpoint}/ambulances/tracking/$bookingId";
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body is Map && body["status"] == true && body["data"] is Map) {
          final data = body["data"] as Map;

          final lat = double.tryParse(data["current_lat"]?.toString() ?? "");
          final lng = double.tryParse(data["current_long"]?.toString() ?? "");

          if (lat != null && lng != null && lat != 0 && lng != 0) {
            setState(() {
              currentAmbulanceLatLng = LatLng(lat, lng);
              isLoadingLocation = false;
              statusMessage = "Live Tracking • Connected";
            });
            _updateMap();
            return;
          } else {
            setState(() {
              statusMessage = "Ambulance location not updated yet";
            });
          }
        } else {
          setState(() {
            statusMessage =
                body["message"]?.toString() ?? "Unexpected response";
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          statusMessage = "Tracking not started by driver";
        });
      } else {
        setState(() {
          statusMessage = "Server error (${response.statusCode}), retrying...";
        });
      }
    } catch (e) {
      debugPrint("Tracking API Error: $e");
      setState(() {
        statusMessage = "Connecting... (simulated mode)";
      });
    }

    // Optionally fallback to simulation if real location unavailable
    // _simulateMovement();
  }

  void _simulateMovement() {
    final r = Random();
    setState(() {
      currentAmbulanceLatLng = LatLng(
        (currentAmbulanceLatLng?.latitude ?? pickupLat - 0.02) +
            (r.nextDouble() - 0.5) * 0.0015,
        (currentAmbulanceLatLng?.longitude ?? pickupLng - 0.02) +
            (r.nextDouble() - 0.5) * 0.0015,
      );
      isLoadingLocation = false;
      statusMessage = "Simulated Live (Test Mode)";
    });
    _updateMap();
  }

  Future<void> _updateMap() async {
    if (currentAmbulanceLatLng == null) return;

    final ambulanceIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(120, 120)),
      'assets/image/ambulance.png',
    );

    final dropIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(120, 120)),
      'assets/image/hospital.png',
    );

    setState(() {
      markers = {
        Marker(
          markerId: const MarkerId("ambulance"),
          position: currentAmbulanceLatLng!,
          icon: ambulanceIcon,
          infoWindow: InfoWindow(
            title: "Live Ambulance",
            snippet: "$vehicleNumber • $driverName",
          ),
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
          icon: dropIcon,
          infoWindow: InfoWindow(title: "Hospital", snippet: dropAddress),
        ),
      };
    });

    polylines.clear();

    await _drawRoute(
      currentAmbulanceLatLng!,
      LatLng(pickupLat, pickupLng),
      Colors.redAccent,
      7,
      "to_pickup",
    );

    await _drawRoute(
      LatLng(pickupLat, pickupLng),
      LatLng(dropLat, dropLng),
      AppConstants.appPrimaryColor,
      6,
      "to_drop",
    );

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
        [currentAmbulanceLatLng!.latitude, pickupLat, dropLat]
            .reduce((a, b) => a < b ? a : b),
        [currentAmbulanceLatLng!.longitude, pickupLng, dropLng]
            .reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        [currentAmbulanceLatLng!.latitude, pickupLat, dropLat]
            .reduce((a, b) => a > b ? a : b),
        [currentAmbulanceLatLng!.longitude, pickupLng, dropLng]
            .reduce((a, b) => a > b ? a : b),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 300));
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  // SAFE IMAGE WIDGET – Azure 409 fixed
  Widget _ambulanceImageWidget() {
    if (ambulancePhotoUrl == null || ambulancePhotoUrl!.isEmpty) {
      return Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
            color: Colors.grey[300], borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.local_hospital, size: 40, color: Colors.grey),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        ambulancePhotoUrl!,
        width: 110,
        height: 90,
        fit: BoxFit.fill,
        headers: const {"User-Agent": "Aidxpert-App"},
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                color: Colors.grey[300],
                child: const CircularProgressIndicator()),
        errorBuilder: (_, __, ___) => Container(
          width: 90,
          height: 90,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, size: 40),
        ),
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
                    currentAmbulanceLatLng ?? const LatLng(18.5204, 73.8567),
                zoom: 14,
              ),
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
                      () => launchPhoneCall(driverContact)),
                ],
              ),
            ),

            // Live Status Indicator
            Positioned(
              top: MediaQuery.of(context).padding.top + 35,
              left: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10)
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      isLoadingLocation ? Icons.hourglass_empty : Icons.circle,
                      color: isLoadingLocation ? Colors.orange : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      statusMessage,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      "Booking #$bookingId",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Card
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Card(
                color: Colors.white,
                elevation: 10,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _ambulanceImageWidget(),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(vehicleNumber,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppConstants.appPrimaryColor)),
                                Text("Driver: $driverName",
                                    style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 5),
                                  decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(30)),
                                  child: const Text("LIVE TRACKING",
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
                      const Divider(height: 20),
                      _locationInfo(
                          Icons.my_location, "Pickup Location", pickupAddress),
                      const SizedBox(height: 12),
                      _locationInfo(
                          Icons.location_on, "Drop Location", dropAddress),
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
        Icon(icon, color: AppConstants.appPrimaryColor, size: 28),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 4),
              Text(address,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)]),
      child: IconButton(
          icon: Icon(icon, color: color, size: 26), onPressed: onTap),
    );
  }
}
