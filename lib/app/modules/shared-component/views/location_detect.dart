// ignore_for_file: must_be_immutable, non_constant_identifier_names, deprecated_member_use, unnecessary_null_comparison
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../constants/app_constants.dart';
import '../../../../utils/helper.dart';
import '../controllers/location_controller.dart';

class LocationDetectView extends GetView {
  LocationDetectView({Key? key}) : super(key: key);
  final LocationController locationController = Get.put(LocationController());

  Future<Position> _getGeoLocationPosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _getAddressFromLatLong(Position position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String address =
            '${placemark.subLocality ?? ''}, ${placemark.locality ?? ''}, ${placemark.administrativeArea ?? ''}, ${placemark.postalCode ?? ''}, ${placemark.country ?? ''}'
                .replaceAll(', ,', ',')
                .trim();
        locationController.updateLocation(
          address: address,
          city: placemark.locality ?? '',
          state: placemark.administrativeArea ?? '',
          latitude: position.latitude.toString(),
          longitude: position.longitude.toString(),
        );
        Get.back(result: {
          'address': address,
          'city': placemark.locality ?? '',
          'state': placemark.administrativeArea ?? '',
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
        });
      }
    } catch (e) {
      customToast('Failed to search location: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.appScaffoldBgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppConstants.appPrimaryColor.withOpacity(0.9),
                AppConstants.appPrimaryColor.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        elevation: 0,
        toolbarHeight: 120,
        centerTitle: false,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(5, 10, 0, 10),
              child: Text('Enter your search location'),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  locationController.searchLocation(value);
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14.0, horizontal: 16.0),
                  hintText: 'Search your location...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: AppConstants.appPrimaryColor,
                    size: 24,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide(
                      color: AppConstants.appPrimaryColor.withOpacity(0.8),
                      width: 2,
                    ),
                  ),
                ),
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          ],
        ),
        actions: [
          Transform.translate(
            offset: const Offset(0, 20),
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Obx(() => locationController.loading.value
                      ? const CircularProgressIndicator(
                          color: Colors.white70,
                          strokeWidth: 2,
                        )
                      : const SizedBox()),
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    elevation: 5,
                    onPressed: () async {
                      locationController.resetLocationList();
                      locationController.loading.value = true;
                      try {
                        Position position = await _getGeoLocationPosition();
                        await _getAddressFromLatLong(position);
                      } catch (e) {
                        customToast(
                            'Failed to search location: $e', Colors.red);
                      } finally {
                        locationController.loading.value = false;
                      }
                    },
                    child: Icon(
                      Icons.gps_fixed_rounded,
                      color: AppConstants.appPrimaryColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: GetBuilder<LocationController>(
        id: 'location-search',
        init: LocationController(),
        builder: (ctrl) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: ctrl.loading.isTrue
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 85,
                              height: 85,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppConstants.appPrimaryColor),
                                strokeWidth: 6,
                              ),
                            ),
                            Icon(
                              Icons.location_searching,
                              size: 50,
                              color:
                                  AppConstants.appPrimaryColor.withOpacity(0.7),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Searching for your location...',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ctrl.predictionList.isEmpty
                    ? const Center(
                        child: Text(
                          'No locations found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: ctrl.predictionList.length,
                        itemBuilder: (context, index) {
                          final prediction = ctrl.predictionList[index];
                          final description = prediction['description'] ?? '';
                          final city = prediction['structured_formatting']
                                      ?['secondary_text']
                                  ?.split(', ')[0] ??
                              '';
                          final state = prediction['structured_formatting']
                                      ?['secondary_text']
                                  ?.split(', ')[1] ??
                              '';
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 5.0),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(6.0),
                                decoration: BoxDecoration(
                                  color: AppConstants.appPrimaryColor
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: AppConstants.appPrimaryColor,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                description,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                '$city, $state',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              onTap: () async {
                                try {
                                  await ctrl.getPlaceDetails(
                                    prediction['place_id'],
                                    description: description,
                                  );
                                } catch (e) {
                                  customToast('Failed to search location: $e',
                                      Colors.red);
                                }
                              },
                              tileColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
          );
        },
      ),
    );
  }
}
