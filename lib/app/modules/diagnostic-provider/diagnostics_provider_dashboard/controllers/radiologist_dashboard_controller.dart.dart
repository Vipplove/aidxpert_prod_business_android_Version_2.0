// File: lib/app/modules/labs-provider/controllers/pathologist_dashboard_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';

class RadiologistDashboardController extends GetxController {
  var isLoading = true.obs;
  var diagnosticList = <Map<String, dynamic>>[].obs;
  var userData = <String, dynamic>{}.obs;
  var selectedDate = DateFormat('dd-MM-yyyy').format(DateTime.now()).obs;
  var appointmentList = <Map<String, dynamic>>[].obs;
  int _latestRequestId = 0;

  var bookingList = <Map<String, dynamic>>[].obs;
  var filteredList = <Map<String, dynamic>>[].obs;
  var searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLabDetails();
  }

  Future<void> fetchLabDetails() async {
    try {
      isLoading(true);
      final token = await readStr('token');
      final userId = await readStr('user_id') ?? 44;

      final response = await http.get(
        Uri.parse(
            '${AppConstants.endpoint}/diagnostics/centers?user_id=$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true) {
          final List list = json['list'] ?? [];
          diagnosticList.assignAll(list.cast<Map<String, dynamic>>());

          if (diagnosticList.isNotEmpty && diagnosticList[0]['user'] != null) {
            userData.assignAll(diagnosticList[0]['user']);
          }
        }
      }
    } catch (e) {
      print('Error: $e');
      customToast('Failed to load labs', Colors.red);
    } finally {
      isLoading(false);
    }
  }

  Future<void> refreshData() => fetchLabDetails();

  Future<void> fetchBookings(String providerId, String centerId) async {
    await saveStr('profileId', providerId.toString());

    try {
      isLoading(true);
      final token = await readStr('token');

      final url = Uri.parse(
        '${AppConstants.endpoint}/diagnostics/provider-dashboard/$providerId/test-bookings?diagnostic_center_id=$centerId',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true) {
          final List data = json['appointments'] ?? [];
          bookingList.assignAll(data.cast<Map<String, dynamic>>());
          filteredList.assignAll(bookingList); // Initially show all
        } else {
          customToast(json['message'] ?? 'No data', Colors.orange);
        }
      }
    } catch (e) {
      customToast('Failed to load bookings', Colors.red);
    } finally {
      isLoading(false);
    }
  }

  void filterBookings(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredList.assignAll(bookingList);
    } else {
      final lowerQuery = query.toLowerCase();
      filteredList.assignAll(
        bookingList.where((booking) {
          final bookingId =
              booking['diagnostic_test_booking_id']?.toString() ?? '';
          return bookingId.contains(lowerQuery);
        }).toList(),
      );
    }
  }
}
