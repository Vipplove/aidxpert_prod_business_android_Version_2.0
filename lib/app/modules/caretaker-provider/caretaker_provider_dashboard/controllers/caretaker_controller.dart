// controllers/caretaker_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';

class CaretakerController extends GetxController {
  var isLoading = true.obs;

  // Dashboard Stats
  var totalServedPatients = 0.obs;
  var totalCurrentBookings = 0.obs;

  // Bookings Lists (Today & Past)
  var todayBookings = <Map<String, dynamic>>[].obs;
  var pastBookings = <Map<String, dynamic>>[].obs;

  var bookingHistory = <Map<String, dynamic>>[].obs;
  var caretakerStaff = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardStats();
    fetchTodayBookings();
    fetchPastBookings();
  }

  // API 1: Dashboard Counts
  Future<void> fetchDashboardStats() async {
    final profileId = await readStr('profileId');
    final token = await readStr('token');

    if (profileId == null || token == null) {
      customToast("Please login again", Colors.red);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            '${AppConstants.endpoint}/caretakers/provider-dashboard/$profileId/patients-bookings-count'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['status'] == true) {
          final data = body['data'];
          totalServedPatients.value = data['totalServedPatients'] ?? 0;
          totalCurrentBookings.value = data['totalCurrentBookings'] ?? 0;
        }
      }
    } catch (e) {
      customToast('Failed to load stats', Colors.red);
    }
  }

  // API 2: Today Bookings
  Future<void> fetchTodayBookings() async {
    final profileId = await readStr('profileId');
    final token = await readStr('token');

    if (profileId == null || token == null) return;

    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse(
            '${AppConstants.endpoint}/caretakers/provider-dashboard/$profileId/bookings?type=today'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['status'] == true) {
          final List list = body['list'] ?? [];
          todayBookings.assignAll(List<Map<String, dynamic>>.from(list));
        }
      }
    } catch (e) {
      customToast('Failed to load today\'s bookings', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  // API 3: Past Bookings
  Future<void> fetchPastBookings() async {
    final profileId = await readStr('profileId');
    final token = await readStr('token');

    if (profileId == null || token == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            '${AppConstants.endpoint}/caretakers/provider-dashboard/$profileId/bookings?type=past'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['status'] == true) {
          final List list = body['list'] ?? [];
          pastBookings.assignAll(List<Map<String, dynamic>>.from(list));
        }
      }
    } catch (e) {
      customToast('Failed to load past bookings', Colors.red);
    }
  }

  Future<void> fetchBookingHistory() async {
    final profileId = await readStr('profileId');
    final token = await readStr('token');

    if (profileId == null || token == null) {
      customToast("Please login again", Colors.red);
      return;
    }

    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse(
            '${AppConstants.endpoint}/caretakers/provider-dashboard/$profileId/history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['status'] == true) {
          final List list = body['list'] ?? [];
          bookingHistory.assignAll(List<Map<String, dynamic>>.from(list));
        }
      }
    } catch (e) {
      customToast('Failed to load history', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  // Add this method
  Future<void> fetchCaretakerStaff() async {
    final profileId = await readStr('profileId');
    final token = await readStr('token');

    if (profileId == null || token == null) {
      customToast("Please login again", Colors.red);
      return;
    }

    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse(
            '${AppConstants.endpoint}/caretakers/details/provider/$profileId/all'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['status'] == true) {
          final List list = body['data'] ?? [];
          caretakerStaff.assignAll(List<Map<String, dynamic>>.from(list));
        }
      }
    } catch (e) {
      customToast('Failed to load staff', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh everything
  Future<void> refreshData() async {
    await fetchDashboardStats();
    await fetchTodayBookings();
    await fetchPastBookings();
  }
}
