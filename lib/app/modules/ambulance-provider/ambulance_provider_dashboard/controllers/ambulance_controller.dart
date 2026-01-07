// controllers/ambulance_controller.dart
// ignore_for_file: unused_field
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';

class AmbulanceController extends GetxController {
  var isLoading = false.obs;

  // Dashboard stats
  var totalServedPatients = 0.obs;
  var totalTodaysBookings = 0.obs;

  // Dashboard bookings (today/past)
  var todayBookings = <Map<String, dynamic>>[].obs;
  var pastBookings = <Map<String, dynamic>>[].obs;

  // Full history
  var allBookings = <Map<String, dynamic>>[].obs;
  var filteredBookings = <Map<String, dynamic>>[].obs;

  // Current filters (for UI sync)
  DateTime? _startDate;
  DateTime? _endDate;
  String? _bookingStatus;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardCounts();
    fetchBookings(type: "today");
    fetchBookings(type: "past");
  }

  // ================== API 1: Dashboard Counts ==================
  Future<void> fetchDashboardCounts() async {
    final profileId = await readStr('profileId');
    final token = await readStr('token') ?? '';

    try {
      final res = await http.get(
        Uri.parse(
            "${AppConstants.endpoint}/ambulances/provider-dashboard/$profileId/patients-bookings-count"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['status'] == true) {
          final data = body['data'];
          totalServedPatients.value = data['totalServedPatients'] ?? 0;
          totalTodaysBookings.value = data['totalTodaysBookings'] ?? 0;
        }
      }
    } catch (e) {
      print("Count API error: $e");
    }
  }

  // ================== API 2: Today / Past Bookings ==================
  Future<void> fetchBookings({required String type}) async {
    final profileId = await readStr('profileId');
    final token = await readStr('token') ?? '';

    try {
      isLoading.value = true;
      final res = await http.get(
        Uri.parse(
            "${AppConstants.endpoint}/ambulances/provider-dashboard/$profileId/bookings?type=$type"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final List list = body['list'] ?? [];

        if (type == "today") {
          todayBookings.assignAll(List<Map<String, dynamic>>.from(list));
        } else {
          pastBookings.assignAll(List<Map<String, dynamic>>.from(list));
        }
      }
    } catch (e) {
      print("Bookings API error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ================== API 3: Full Booking History with Filters ==================
  Future<void> fetchBookingHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? bookingStatus,
    String? bookingId,
  }) async {
    final profileId = await readStr('profileId');
    final token = await readStr('token') ?? '';

    if (profileId == null || token.isEmpty) {
      customToast("Authentication required", Colors.red);
      return;
    }

    try {
      isLoading.value = true;
      update();

      // Build query parameters
      final Map<String, String> queryParams = {};
      if (startDate != null) {
        queryParams['startDate'] = _formatDateForApi(startDate);
      }
      if (endDate != null) {
        queryParams['endDate'] = _formatDateForApi(endDate);
      }
      if (bookingStatus != null && bookingStatus.isNotEmpty) {
        queryParams['booking_status'] = bookingStatus;
      }
      if (bookingId != null && bookingId.isNotEmpty) {
        queryParams['ambulance_booking_id'] = bookingId;
      }

      final uri = Uri.parse(
        "${AppConstants.endpoint}/ambulances/provider-dashboard/$profileId/booking-history",
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(uri.toString()); // Debug: Print the final URL

      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        final List list = body['list'] ?? [];
        allBookings.assignAll(List<Map<String, dynamic>>.from(list));
        filteredBookings.assignAll(List<Map<String, dynamic>>.from(list));
      } else {
        customToast(
            "Failed to load history ${response.statusCode}", Colors.red);
      }
    } catch (e) {
      print("Booking History API Error: $e");
      customToast("Network error. Please try again.", Colors.red);
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Helper: Format DateTime to YYYY-MM-DD for API
  String _formatDateForApi(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Optional: Client-side search by booking ID (if API doesn't support it)
  void searchByBookingId(String query) {
    if (query.isEmpty) {
      filteredBookings.assignAll(allBookings);
    } else {
      final filtered = allBookings.where((booking) {
        return booking['ambulance_booking_id'].toString().contains(query);
      }).toList();
      filteredBookings.assignAll(filtered);
    }
  }

  // Clear all filters and reload fresh data
  Future<void> clearFiltersAndRefresh() async {
    _startDate = null;
    _endDate = null;
    _bookingStatus = null;
    await fetchBookingHistory(); // Reload without filters
  }
}
