// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';
import '../../../../routes/app_pages.dart';

class DiagnosticsProviderDashboardController extends GetxController {
  // In DiagnosticsProviderDashboardController
  var totalPatients = 0.obs;
  var todayAppointments = 0.obs;
  var pendingAppointments = 0.obs;
  var completedAppointments = 0.obs;
  var cancelledAppointments = 0.obs;
  var providerVerifiedStatus = ''.obs;
  var providerActiveStatus = ''.obs;

  var isLoading = false.obs;
  var testBookingList = [].obs;
  var diagnosticTestList = [].obs;
  var branchList = [].obs;
  var testReport = [].obs;
  var rating = 0.0;
  var chkStatus = ''.obs;
  String type = '';

  // New fields for slot selection
  var availableSlots = [].obs;
  var selectedDate = DateFormat('dd-MM-yyyy').format(DateTime.now()).obs;
  var selectedTime = ''.obs;
  var appointmentList = <Map<String, dynamic>>[].obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    type = await readStr('type') ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetchBookingsByTab('today');
      await fetchAppointmentCounts();
    });
  }

  Future<void> fetchAppointmentCounts() async {
    final profileId = await readStr('profileId');
    final token = await readStr('token') ?? '';

    final url =
        '${AppConstants.endpoint}/diagnostics/provider-dashboard/$profileId/patients-appointments-count';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (response.statusCode == 200) {
          final res = json.decode(response.body);

          if (res['status'] == true) {
            totalPatients.value = res['Total_Patients'] ?? 0;
            // UPDATED KEYS
            todayAppointments.value =
                res['Total_Diagnostics_Appointments_Today'] ?? 0;
            pendingAppointments.value =
                res['Total_Pending_Diagnostics_Appointments'] ?? 0;
            completedAppointments.value =
                res['Total_Completed_Diagnostics_Appointments'] ?? 0;
            cancelledAppointments.value =
                res['Total_Cancelled_Diagnostics_Appointments'] ?? 0;
            providerVerifiedStatus.value =
                res['provider_verified_status'] ?? '';
            providerActiveStatus.value =
                res['provider_active_status']?.toString() ?? '';

            // Status Logic (Corrected)
            if (providerVerifiedStatus.value != 'verified') {
              chkStatus.value = 'Active';
            } else {
              chkStatus.value = 'Inactive';
              Get.toNamed(
                Routes.DIAGNOSTIC_PROVIDER_REGISTRATION,
                arguments: {"type": "dashboard"},
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching counts: $e');
    }
    update(['diagnostic-provider-dashboard']);
  }

  Future<void> getTestBookingList(String? status) async {
    if (isLoading.value) return;

    // Clear old data
    appointmentList.clear();
    appointmentList.value = [];
    isLoading(true);
    update(['diagnostic-provider-dashboard']);

    final currentRequestId = ++_latestRequestId;
    final token = await readStr('token') ?? '';
    final profileId = await readStr('profileId') ?? '1';

    final url = Uri.parse(
      '${AppConstants.endpoint}/diagnostics/provider-dashboard/1/test-bookings${status != null && status.isNotEmpty ? '?booking_status=$status' : ''}',
    );

    print(
        '${AppConstants.endpoint}/diagnostics/provider-dashboard/1/test-bookings${status != null && status.isNotEmpty ? '?booking_status=$status' : ''}');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Only process the **latest** request
      if (currentRequestId != _latestRequestId) return;

      final res = json.decode(response.body);

      if (response.statusCode == 200 && res['status'] == true) {
        final List data = res['appointments'] ?? [];
        appointmentList.value = List<Map<String, dynamic>>.from(data);
      } else {
        appointmentList.clear();
        customToast(res['message'] ?? 'No data');
      }
    } catch (e) {
      if (currentRequestId == _latestRequestId) {
        customToast('Failed to load bookings: $e');
        appointmentList.clear();
      }
    } finally {
      if (currentRequestId == _latestRequestId) {
        isLoading(false);
        update(['diagnostic-provider-dashboard']);
      }
    }
  }

  // Helper used by the view
  List<Map<String, dynamic>> getBookingsForTab(String tab) => appointmentList;
  void clearAppointments() => appointmentList.clear();

  // In DiagnosticsProviderDashboardController
  Future<void> fetchBookingsByTab(
    String tab, {
    String? startDate,
    String? endDate,
  }) async {
    final profileId = await readStr('profileId') ?? '';
    final token = await readStr('token') ?? '';

    String url =
        '${AppConstants.endpoint}/diagnostics/provider-dashboard/$profileId/test-bookings?type=$tab';
    if (startDate != null) url += '&startDate=$startDate';
    if (endDate != null) url += '&endDate=$endDate';

    isLoading.value = true;
    appointmentList.clear();
    update();

    print(url);

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final res = json.decode(response.body);

      if (response.statusCode == 200 && res['status'] == true) {
        final List data = res['appointments'] ?? [];
        appointmentList.value = List<Map<String, dynamic>>.from(data);
      } else {
        appointmentList.clear();
      }
      update();
    } catch (e) {
      customToast('Error: $e');
      appointmentList.clear();
      isLoading.value = false;
      update();
    } finally {
      isLoading.value = false;
      update();
    }
  }

  /// Search by Booking ID with debounce support
  Future<void> searchTestBookingList(String bookingId) async {
    final token = await readStr('token') ?? '';
    final profileId = await readStr('profileId') ?? '1';

    String url =
        '${AppConstants.endpoint}/diagnostics/provider-dashboard/$profileId/test-bookings?lab_test_booking_id=$bookingId';

    isLoading.value = true;
    appointmentList.clear();
    update(['labs-booking-history']);

    final currentRequestId = ++_latestRequestId;

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (currentRequestId != _latestRequestId) return;

      final res = json.decode(response.body);
      if (response.statusCode == 200 && res['status'] == true) {
        appointmentList.value =
            List<Map<String, dynamic>>.from(res['appointments'] ?? []);
      } else {
        appointmentList.clear();
      }
    } catch (e) {
      if (currentRequestId == _latestRequestId) {
        customToast('Search error: $e');
        appointmentList.clear();
      }
    } finally {
      if (currentRequestId == _latestRequestId) {
        isLoading.value = false;
        update(['labs-booking-history']);
      }
    }
  }

  Future<void> updateBookingStatus({
    required int bookingId,
    required String status,
    required String remark,
    String? tab,
    File? reportFile,
    String? reportTitle,
    String? reportNotes,
  }) async {
    if (bookingId == 0 || status.isEmpty) {
      customToast('Invalid booking ID or status', Colors.red);
      return;
    }

    EasyLoading.show(status: 'Updating status...');

    try {
      final token = await readStr('token') ?? '';
      final profileId = await readStr('profileId') ?? '1';

      final uri = Uri.parse(
          '${AppConstants.endpoint}/diagnostics/provider-dashboard/$profileId/booking-status');

      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "booking_id": bookingId,
          "status": status,
          "remark": remark,
        }),
      );

      final res = json.decode(response.body);

      if (response.statusCode == 200 && res['status'] == true) {
        customToast('Booking $status successfully', Colors.green);

        // Upload report only if COMPLETED and file provided
        if (status == 'COMPLETED' && reportFile != null) {
          await _uploadLabReport(
            bookingId: bookingId,
            file: reportFile,
            title: reportTitle ?? 'Diagnostic Report',
            notes: reportNotes ?? 'Report uploaded by provider.',
          );
        }

        // Refresh tab
        final tabToRefresh = tab?.toLowerCase() ?? 'today';
        await fetchBookingsByTab(tabToRefresh);
      } else {
        customToast(res['message'] ?? 'Failed to update booking', Colors.red);
      }
    } catch (e) {
      customToast('Error: $e', Colors.red);
    } finally {
      EasyLoading.dismiss();
      if (Get.isDialogOpen ?? false) Get.back();
    }
  }

  Future<void> _uploadLabReport({
    required int bookingId,
    required File file,
    required String title,
    required String notes,
  }) async {
    EasyLoading.show(status: 'Uploading report...');

    try {
      final token = await readStr('token') ?? '';
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.endpoint}/diagnostics/test-reports'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['diagnostic_test_booking_id'] = bookingId.toString();
      request.fields['report_title'] = title;
      request.fields['report_notes'] = notes;

      request.files.add(await http.MultipartFile.fromPath(
        'report_file',
        file.path,
        filename: file.path.split('/').last,
      ));

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final res = json.decode(respStr);

      if (response.statusCode == 200 && res['status'] == true) {
        customToast('Report uploaded successfully!', Colors.green);
      } else {
        customToast(res['message'] ?? 'Failed to upload report', Colors.red);
      }
    } catch (e) {
      customToast('Upload failed: $e', Colors.red);
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> getDiagnosticTestList(String? search) async {
    if (isLoading.value) return;

    diagnosticTestList.clear();
    isLoading(true);
    update(['diagnostic-test-list']);

    final token = await readStr('token');
    final providerId = await readStr('profileId');
    final currentRequestId = ++_latestRequestId;

    if (token == null || token.isEmpty) {
      customToast('Authentication token missing', Colors.red);
      isLoading(false);
      return;
    }

    try {
      String url =
          '${AppConstants.endpoint}/diagnostics/tests/provider/$providerId';
      if (search != null && search.isNotEmpty) url += '?search=$search';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      final res = json.decode(response.body);

      if (currentRequestId == _latestRequestId) {
        if (response.statusCode == 200 && res['status'] == true) {
          diagnosticTestList.value =
              List<Map<String, dynamic>>.from(res['list']);
        } else {
          customToast(res['message'] ?? 'Failed to load tests');
        }
      }
    } catch (e) {
      if (currentRequestId == _latestRequestId) {
        customToast('Error: $e');
      }
    } finally {
      if (currentRequestId == _latestRequestId) {
        isLoading(false);
        update(['diagnostic-test-list']);
      }
    }
  }

  Future<void> searchDiagnosticTests(String query) async {
    if (query.length > 2) {
      isLoading(true);
      update(['diagnostic-test-list']);

      final token = await readStr('token');
      final providerId = await readStr('profileId') ?? '';
      try {
        final response = await http.get(
          Uri.parse(
              '${AppConstants.endpoint}/diagnostics/lab-tests/search?search?testName=$query&diagnostic_service_provider_id=$providerId'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          diagnosticTestList.value =
              List<Map<String, dynamic>>.from(data['list'] ?? []);
        }
      } catch (e) {
        customToast('Search failed');
      } finally {
        isLoading(false);
        update(['diagnostic-test-list']);
      }
    } else {
      getDiagnosticTestList('');
    }
  }

  int _latestRequestId = 0;

  Future<void> submitTest(Map<String, dynamic> payload) async {
    // Prevent double submission
    if (isLoading.value) return;

    isLoading(true);
    EasyLoading.show(
      status: payload['diagnostic_test_id'] != null
          ? 'Updating Test...'
          : 'Adding Test...',
    );
    update(['diagnostic-test-entry']);

    final bool isEdit = payload['diagnostic_test_id'] != null;
    final String? testId = payload['diagnostic_test_id']?.toString();

    // Correct endpoint with /api/v1
    final String url = isEdit
        ? '${AppConstants.endpoint}/diagnostics/tests/$testId'
        : '${AppConstants.endpoint}/diagnostics/tests';

    final int currentRequestId = ++_latestRequestId;

    try {
      final token = await readStr('token');
      if (token == null || token.isEmpty) {
        customToast('Authentication required. Please login again.', Colors.red);
        return;
      }

      // Build payload EXACTLY as per your curl
      final Map<String, dynamic> requestBody = {
        "diagnostic_center_ids":
            payload['diagnostic_center_ids'], // Must be List<int>
        "test_name": payload['test_name']?.toString().trim(),
        "test_code": payload['test_code']?.toString().trim(),
        "category": payload['category']?.toString().trim(),
        "test_type": payload['test_type']?.toString().trim(),
        "preparation_instructions":
            payload['preparation_instructions']?.toString().trim(),
        "turnaround_time": payload['turnaround_time'],
        "old_test_charges":
            double.tryParse(payload['old_test_charges'].toString()) ?? 0.0,
        "new_test_charges":
            double.tryParse(payload['new_test_charges'].toString()) ?? 0.0,
        "service_charge":
            double.tryParse(payload['service_charge'].toString()) ?? 0.0,
        "prescription_required": payload['prescription_required'] == true,
      };

      // Optional: Remove empty fields (keeps request clean)
      requestBody.removeWhere(
          (key, value) => value == null || (value is String && value.isEmpty));

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final http.Response response = isEdit
          ? await http
              .put(Uri.parse(url),
                  headers: headers, body: jsonEncode(requestBody))
              .timeout(const Duration(seconds: 30))
          : await http
              .post(Uri.parse(url),
                  headers: headers, body: jsonEncode(requestBody))
              .timeout(const Duration(seconds: 30));

      // Ignore if a newer request was made
      if (currentRequestId != _latestRequestId) return;

      final Map<String, dynamic> res = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final successMsg = res['message'] ??
            (isEdit
                ? 'Test updated successfully!'
                : 'Test added successfully!');
        customToast(successMsg, Colors.green);

        // Refresh list and close modal
        await getDiagnosticTestList('');
        Get.back(); // Close form
      } else {
        final errorMsg =
            res['message'] ?? res['error'] ?? 'Failed to save test';
        print('API Error: $errorMsg');
        customToast(errorMsg, Colors.red);
      }
    } on TimeoutException {
      if (currentRequestId == _latestRequestId) {
        customToast('Request timed out. Please try again.', Colors.red);
      }
    } catch (e, stackTrace) {
      if (currentRequestId == _latestRequestId) {
        debugPrint('submitTest Exception: $e');
        debugPrint(stackTrace.toString());
        customToast('Network error. Check your connection.', Colors.red);
      }
    } finally {
      EasyLoading.dismiss();
      if (currentRequestId == _latestRequestId) {
        isLoading(false);
        update(['diagnostic-test-entry', 'diagnostic-test-list']);
      }
    }
  }

  // GET BRANCH LIST
  Future<void> getBranchList() async {
    if (isLoading.value) return;

    branchList.clear();
    isLoading(true);
    update(['diagnostic-branch']);

    final token = await readStr('token');
    final providerId = await readStr('profileId') ?? '';
    final currentRequestId = ++_latestRequestId;

    try {
      final response = await http.get(
        Uri.parse(
            '${AppConstants.endpoint}/diagnostics/provider-dashboard/$providerId/centers'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final res = json.decode(response.body);

      if (currentRequestId != _latestRequestId) return;

      if (response.statusCode == 200 && res['status'] == true) {
        branchList.value = List<Map<String, dynamic>>.from(res['list']);
      } else {
        customToast(res['message'] ?? 'Failed to load branches');
        branchList.clear();
      }
    } catch (e) {
      if (currentRequestId == _latestRequestId) {
        customToast('Error: $e');
        branchList.clear();
      }
    } finally {
      if (currentRequestId == _latestRequestId) {
        isLoading(false);
        update(['diagnostic-branch']);
      }
    }
  }

  Future<void> submitBranchWithPhotos({
    required Map<String, dynamic> payload,
    required List<File> newImages,
    required VoidCallback onSuccess,
    required BuildContext context,
  }) async {
    isLoading.value = true;
    update(['diagnostic-branch']);
    EasyLoading.show(status: 'Saving branch...');

    try {
      final token = await readStr('token');
      final profileIdStr = await readStr('profileId') ?? '';

      if (token == null || token.isEmpty) {
        customToast('Authentication token is missing.', Colors.red);
        EasyLoading.dismiss();
        isLoading.value = false;
        return;
      }

      final diagnosticServiceProviderId = int.tryParse(profileIdStr);
      if (diagnosticServiceProviderId == null) {
        customToast('Invalid Provider ID.', Colors.red);
        EasyLoading.dismiss();
        isLoading.value = false;
        return;
      }

      // Determine if it's Edit or Add
      final bool isEdit = payload['diagnostic_center_id'] != null;
      final String method = isEdit ? 'PUT' : 'POST';
      final String endpoint = isEdit
          ? '${AppConstants.endpoint}/diagnostics/centers/${payload['diagnostic_center_id']}'
          : '${AppConstants.endpoint}/diagnostics/centers';

      final request = http.MultipartRequest(method, Uri.parse(endpoint));
      request.headers['Authorization'] = 'Bearer $token';

      // Required Fields
      final Map<String, String> fields = {
        'user_id': payload['user_id']?.toString() ?? '',
        'diagnostic_service_provider_id':
            diagnosticServiceProviderId.toString(),
        'center_name': (payload['center_name'] ?? '').toString().trim(),
        'center_address': (payload['center_address'] ?? '').toString().trim(),
        'area': (payload['area'] ?? '').toString().trim(),
        'city': (payload['city'] ?? '').toString().trim(),
        'state': (payload['state'] ?? '').toString().trim(),
        'zip_code': (payload['zip_code'] ?? '').toString().trim(),
        'country': (payload['country'] ?? 'India').toString().trim(),
        'latitude': payload['latitude']?.toString() ?? '',
        'longitude': payload['longitude']?.toString() ?? '',
      };

      print('Submitting Branch with fields: $fields');

      // Optional: Description
      final desc = payload['center_description']?.toString().trim();
      if (desc != null && desc.isNotEmpty) {
        fields['center_description'] = desc;
      }

      // Optional: Service Charges (as JSON string)
      if (payload['service_charges'] != null &&
          payload['service_charges'].toString().trim().isNotEmpty) {
        fields['service_charges'] = payload['service_charges'];
      }

      request.fields.addAll(fields);

      // Add new images
      for (int i = 0; i < newImages.length; i++) {
        final file = newImages[i];
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath(
            'center_photos',
            file.path,
            filename: 'photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          ));
        }
      }

      // Send request
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final Map<String, dynamic> res = jsonDecode(responseBody);

      EasyLoading.dismiss();

      // Use streamedResponse.statusCode (NOT res.statusCode)
      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        if (res['status'] == true ||
            res['success'] == true ||
            res['message']?.toString().contains('success') == true) {
          customToast(
            isEdit
                ? 'Branch updated successfully!'
                : 'Branch added successfully!',
            Colors.green,
          );

          Get.dialog(
            AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(isEdit ? 'Updated' : 'Success'),
              content: Text(isEdit
                  ? 'Branch updated successfully!'
                  : 'New branch created with ID: ${res['diagnosticCenterDetails:']?['diagnostic_center_id'] ?? res['data']?['diagnostic_center_id'] ?? 'N/A'}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Get.back(); // Close dialog
                    Get.back(); // Close form
                    getBranchList(); // Refresh list
                    onSuccess();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
            barrierDismissible: false,
          );
          return;
        }
      }

      // Handle API error
      final errorMsg =
          res['message'] ?? res['error'] ?? 'Failed to save branch';
      customToast(errorMsg, Colors.red);
    } catch (e, stackTrace) {
      print('Error in submitBranchWithPhotos: $e');
      print(stackTrace);
      EasyLoading.dismiss();
      customToast('Network error. Please try again.', Colors.red);
    } finally {
      isLoading.value = false;
      update(['diagnostic-branch']);
    }
  }

  Future<void> deactivateBranch(int branchId, bool currentStatus) async {
    final bool newStatus = !currentStatus;

    final confirmed = await Get.dialog(
      AlertDialog(
        title: Text(newStatus ? 'Activate Branch' : 'Deactivate Branch'),
        content: Text(
            'Are you sure you want to ${newStatus ? 'activate' : 'deactivate'} this branch?'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Yes')),
        ],
      ),
    );

    if (!confirmed) return;

    try {
      final token = await readStr('token') ?? '';
      EasyLoading.show(status: 'loading...');

      final response = await http.patch(
        Uri.parse(
            '${AppConstants.endpoint}/diagnostics/centers/$branchId/active-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "is_active": newStatus,
        }),
      );

      if (response.statusCode == 200) {
        customToast(
            'Branch ${newStatus ? 'activated' : 'deactivated'} successfully');
        getBranchList();
      } else {
        customToast('Failed: ${response.body}');
      }
      EasyLoading.dismiss();
    } catch (e) {
      customToast('Error: $e');
    }
  }

  updateSearchTest() {
    update(['diagnostic-test-details']);
  }
}
