// controllers/driver_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';

class DriverController extends GetxController {
  RxMap<String, dynamic> driverData = <String, dynamic>{}.obs;
  RxList<dynamic> bookings = <dynamic>[].obs;
  RxBool isLoading = true.obs;
  RxBool isLoadingBookings = false.obs;
  RxBool isUpdatingStatus = false.obs;

  final PageController pageController = PageController();
  final RxInt currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDriverDetails();
  }

  Future<void> fetchDriverDetails() async {
    try {
      isLoading.value = true;
      final token = await readStr('token');
      final driverId = await readStr('profileId');

      final response = await http.get(
        Uri.parse('${AppConstants.endpoint}/ambulances/drivers/$driverId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          driverData.value = data['driver'];
          fetchBookings(driverId);
        } else {
          customToast(data['message'] ?? 'Failed to load profile', Colors.red);
        }
      } else {
        customToast('Server error: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      customToast('Failed to load profile: ${e.toString()}', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchBookings(driverId) async {
    try {
      isLoadingBookings.value = true;
      final token = await readStr('token');

      final response = await http.get(
        Uri.parse(
            '${AppConstants.endpoint}/ambulances/drivers/$driverId/bookings'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          bookings.assignAll(data['bookings']);
        } else {
          customToast(data['message'] ?? 'No bookings found', Colors.red);
        }
      } else {
        customToast('Failed to load bookings', Colors.red);
      }
    } catch (e) {
      customToast('Failed to load bookings: ${e.toString()}', Colors.red);
    } finally {
      isLoadingBookings.value = false;
    }
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      customToast('Please enable location services', Colors.red);
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        customToast('Location permission required', Colors.red);
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      customToast('Location permission permanently denied', Colors.red);
      return null;
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // Update tracking status with location
  Future<void> updateTrackingStatus(int bookingId, String status) async {
    try {
      EasyLoading.show(status: 'Updating status...');
      isUpdatingStatus.value = true;

      final token = await readStr('token');
      final position = await getCurrentLocation();

      if (position == null) {
        EasyLoading.dismiss();
        customToast('Could not get current location', Colors.red);
        return;
      }

      // ================= TRACKING API =================
      final trackingResponse = await http.post(
        Uri.parse('${AppConstants.endpoint}/ambulances/tracking'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'ambulance_booking_id': bookingId,
          'current_lat': position.latitude,
          'current_long': position.longitude,
          'status': status,
        }),
      );

      if (trackingResponse.statusCode != 200) {
        customToast('Server error: ${trackingResponse.statusCode}', Colors.red);
        return;
      }

      final trackingData = json.decode(trackingResponse.body);

      if (trackingData['status'] != true) {
        customToast(trackingData['message'] ?? 'Update failed', Colors.red);
        return;
      }

      customToast('Status updated to: ${status.toUpperCase()}', Colors.green);

      // ================= BOOKING STATUS API =================
      if (status == 'cancel' || status == 'completed') {
        final bookingStatus = _mapTrackingToBookingStatus(status);

        final bookingResponse = await http.put(
          Uri.parse(
              '${AppConstants.endpoint}/ambulances/dashboard/booking-status'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'ambulance_booking_id': bookingId,
            'booking_status': bookingStatus,
          }),
        );

        if (bookingResponse.statusCode == 200) {
          final bookingData = json.decode(bookingResponse.body);

          if (bookingData['status'] == true) {
            customToast('Booking marked as ${bookingStatus.toUpperCase()}',
                Colors.green);
          } else {
            customToast(
                bookingData['message'] ?? 'Booking update failed', Colors.red);
          }
        } else {
          customToast(
              'Booking API error: ${bookingResponse.statusCode}', Colors.red);
        }
      }

      // Refresh bookings list
      fetchBookings(await readStr('profileId'));
    } catch (e) {
      customToast('Update failed: ${e.toString()}', Colors.red);
    } finally {
      isUpdatingStatus.value = false;
      EasyLoading.dismiss();
    }
  }

  String _mapTrackingToBookingStatus(String status) {
    switch (status) {
      case 'completed':
        return 'completed';
      case 'cancel':
        return 'cancelled';
      case 'start':
        return 'inprocess';
      default:
        return 'pending';
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
