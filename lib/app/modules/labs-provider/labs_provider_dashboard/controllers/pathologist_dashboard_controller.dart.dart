// File: lib/app/modules/labs-provider/controllers/pathologist_dashboard_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';

class PathologistDashboardController extends GetxController {
  var isLoading = true.obs;
  var labList = <Map<String, dynamic>>[].obs;
  var userData = <String, dynamic>{}.obs;
  var selectedDate = DateFormat('dd-MM-yyyy').format(DateTime.now()).obs;
  var appointmentList = <Map<String, dynamic>>[].obs;

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
        Uri.parse('${AppConstants.endpoint}/labs/details?user_id=$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true) {
          final List list = json['list'] ?? [];
          labList.assignAll(list.cast<Map<String, dynamic>>());

          if (labList.isNotEmpty && labList[0]['user'] != null) {
            userData.assignAll(labList[0]['user']);
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
}
