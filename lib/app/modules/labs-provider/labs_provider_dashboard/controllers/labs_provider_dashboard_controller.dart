// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:aidxpert_business/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';

class LabsProviderDashboardController extends GetxController {
  var totalPatients = 0.obs;
  var todayAppointments = 0.obs;
  var pendingAppointments = 0.obs;
  var completedAppointments = 0.obs;
  var cancelledAppointments = 0.obs;
  var providerVerifiedStatus = ''.obs;
  var providerActiveStatus = false.obs;

  var isLoading = false.obs;
  var testBookingList = [].obs;
  var labTestList = [].obs;
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
        '${AppConstants.endpoint}/labs/provider-dashboard/$profileId/patients-appointments-count';

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
        if (res['status'] == true) {
          totalPatients.value = res['Total_Patients'] ?? 0;
          todayAppointments.value =
              res['Total_Lab_Tests_Appointments_Today'] ?? 0;
          pendingAppointments.value =
              res['Total_Pending_Lab_Tests_Appointments'] ?? 0;
          completedAppointments.value =
              res['Total_Completed_Lab_Tests_Appointments'] ?? 0;
          cancelledAppointments.value =
              res['Total_Cancelled_Lab_Tests_Appointments'] ?? 0;
          providerVerifiedStatus.value = res['provider_verified_status'] ?? '';
          providerActiveStatus.value = res['provider_active_status'] ?? '';
          if (res['provider_verified_status'] == 'verified') {
            chkStatus.value = 'Active';
          } else {
            chkStatus.value = 'Inactive';
            Get.toNamed(
              Routes.LABS_PROVIDER_REGISTRATION,
              arguments: {'type': 'dashboard'},
            );
          }
        }
      }
    } catch (e) {
      print('Error fetching counts: $e');
    }
    update(['labs-provider-dashboard']);
  }

  Future<void> getTestBookingList(String? status) async {
    appointmentList.clear();
    appointmentList.value = [];
    isLoading(true);
    update(['labs-provider-dashboard']);

    final currentRequestId = ++_latestRequestId;
    final token = await readStr('token') ?? '';
    final profileId = await readStr('profileId') ?? '1';

    final url = Uri.parse(
      '${AppConstants.endpoint}/labs/provider-dashboard/$profileId/lab-test-bookings${status != null && status.isNotEmpty ? '?booking_status=$status' : ''}',
    );

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
        update(['labs-provider-dashboard']);
      }
    }
  }

  // Helper used by the view
  List<Map<String, dynamic>> getBookingsForTab(String tab) => appointmentList;
  void clearAppointments() => appointmentList.clear();

  // In LabsProviderDashboardController
  Future<void> fetchBookingsByTab(
    String tab, {
    String? startDate,
    String? endDate,
  }) async {
    final profileId = await readStr('profileId') ?? '';
    final token = await readStr('token') ?? '';

    String url =
        '${AppConstants.endpoint}/labs/provider-dashboard/$profileId/lab-test-bookings?type=$tab';
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
    final profileId = await readStr('profileId');

    String url =
        '${AppConstants.endpoint}/labs/provider-dashboard/$profileId/lab-test-bookings?lab_test_booking_id=$bookingId';

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
          '${AppConstants.endpoint}/labs/provider-dashboard/$profileId/booking-status');

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
            title: reportTitle ?? 'Lab Report',
            notes: reportNotes ?? 'Report uploaded by provider.',
          );
        }

        Get.back();
        // Refresh list based on current tab
        if (tab != null && tab.isNotEmpty) {
          await fetchBookingsByTab(tab);
        }
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
        Uri.parse('${AppConstants.endpoint}/labs/reports'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['lab_test_booking_id'] = bookingId.toString();
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

  Future<void> getLabTestList(String? search) async {
    if (isLoading.value) return;

    labTestList.clear();
    isLoading(true);
    update(['labs-test-list']);

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
          '${AppConstants.endpoint}/labs/lab-tests/provider/$providerId';
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
          labTestList.value = List<Map<String, dynamic>>.from(res['list']);
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
        update(['labs-test-list']);
      }
    }
  }

  Future<void> searchLabTests(String query) async {
    if (query.length > 2) {
      isLoading(true);
      update(['labs-test-list']);

      final token = await readStr('token');
      final providerId = await readStr('profileId') ?? '';
      try {
        final response = await http.get(
          Uri.parse(
              '${AppConstants.endpoint}/labs/lab-tests/search?search?testName=$query&lab_service_provider_id=$providerId'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          labTestList.value =
              List<Map<String, dynamic>>.from(data['list'] ?? []);
        }
      } catch (e) {
        customToast('Search failed');
      } finally {
        isLoading(false);
        update(['labs-test-list']);
      }
    } else {
      getLabTestList('');
    }
  }

  int _latestRequestId = 0;

  Future<void> submitTest(Map<String, dynamic> payload) async {
    // Prevent multiple submissions
    if (isLoading.value) return;

    isLoading(true);
    EasyLoading.show(status: 'Saving Test...');
    update(['labs-test-entry']);

    final bool isEdit = payload['lab_test_id'] != null;
    final String? testId = payload['lab_test_id']?.toString();

    final String url = isEdit
        ? '${AppConstants.endpoint}/labs/lab-tests/$testId'
        : '${AppConstants.endpoint}/labs/lab-tests';

    final http.Response response;
    final currentRequestId = ++_latestRequestId;

    try {
      final token = await readStr('token');
      if (token == null) {
        customToast('Authentication required', Colors.red);
        return;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        "lab_ids": payload['lab_ids'],
        "test_name": payload['test_name'],
        "test_code": payload['test_code'],
        "test_type": payload['test_type'],
        "organ_system": payload['organ_system'],
        "sample_required": payload['sample_required'],
        "test_description": payload['test_description'],
        "preparation_instructions": payload['preparation_instructions'],
        "turnaround_time": payload['turnaround_time'],
        "old_test_charges": payload['new_test_charges'],
        "new_test_charges": payload['old_test_charges'],
        "prescription_required": payload['prescription_required'],
      });

      response = isEdit
          ? await http.put(Uri.parse(url), headers: headers, body: body)
          : await http.post(Uri.parse(url), headers: headers, body: body);

      // Only process if this is the latest request
      if (currentRequestId != _latestRequestId) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        customToast(
            data['message'] ?? 'Test saved successfully!', Colors.green);
        getLabTestList('');
        Get.back(); // Close modal
      } else {
        final error = jsonDecode(response.body);
        customToast(error['message'] ?? 'Failed to save test');
      }
    } catch (e) {
      if (currentRequestId == _latestRequestId) {
        customToast('Network error: $e', Colors.red);
      }
    } finally {
      EasyLoading.dismiss();
      if (currentRequestId == _latestRequestId) {
        isLoading(false);
        update(['labs-test-entry', 'labs-test-list']);
      }
    }
  }

  // GET BRANCH LIST
  Future<void> getBranchList() async {
    if (isLoading.value) return;

    branchList.clear();
    isLoading(true);
    update(['labs-branch']);

    final providerId = await readStr('profileId') ?? '';
    final currentRequestId = ++_latestRequestId;

    try {
      final uri = Uri.parse(
          '${AppConstants.endpoint}/labs/provider-dashboard/$providerId/lab-branches');
      final response = await http.get(uri);
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
        update(['labs-branch']);
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
    update(['labs-branch']);
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

      // Convert profileId to int
      final labServiceProviderId = int.tryParse(profileIdStr);
      if (labServiceProviderId == null) {
        customToast('Invalid Lab Service Provider ID.', Colors.red);
        EasyLoading.dismiss();
        isLoading.value = false;
        return;
      }

      // === Determine HTTP Method & Endpoint ===
      final bool isEdit = payload['lab_id'] != null;
      final String method = isEdit ? 'PUT' : 'POST';
      final String endpoint = isEdit
          ? '${AppConstants.endpoint}/labs/details/${payload['lab_id']}'
          : '${AppConstants.endpoint}/labs/details';

      final request = http.MultipartRequest(method, Uri.parse(endpoint));
      request.headers['Authorization'] = 'Bearer $token';

      // === REQUIRED FIELDS ===
      final Map<String, String> requiredFields = {
        'user_id': payload['user_id']?.toString() ?? '',
        'lab_service_provider_id': labServiceProviderId.toString(),
        'lab_name': (payload['lab_name'] ?? '').toString().trim(),
        'lab_address': (payload['lab_address'] ?? '').toString().trim(),
        'area': (payload['area'] ?? '').toString().trim(),
        'city': (payload['city'] ?? '').toString().trim(),
        'state': (payload['state'] ?? '').toString().trim(),
        'zip_code': (payload['zip_code'] ?? '').toString().trim(),
        'country': (payload['country'] ?? 'India').toString().trim(),
      };

      // Validate required fields
      for (var entry in requiredFields.entries) {
        if (entry.value.isEmpty) {
          customToast(
              '${entry.key.replaceAll('_', ' ')} is required.', Colors.red);
          EasyLoading.dismiss();
          isLoading.value = false;
          return;
        }
      }

      request.fields.addAll(requiredFields);

      // === OPTIONAL FIELDS ===
      final desc = payload['lab_description']?.toString().trim();
      if (desc != null && desc.isNotEmpty) {
        request.fields['lab_description'] = desc;
      }

      if (payload['latitude'] != null) {
        request.fields['latitude'] = payload['latitude'].toString();
      }
      if (payload['longitude'] != null) {
        request.fields['longitude'] = payload['longitude'].toString();
      }

      // === PHOTOS (only for edit if new images added) ===
      for (int i = 0; i < newImages.length; i++) {
        final file = newImages[i];
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath(
            'lab_photos',
            file.path,
            filename: 'branch_photo_$i.jpg',
          ));
        }
      }

      // === SEND REQUEST ===
      final response = await request.send();
      final body = await response.stream.bytesToString();
      final res = jsonDecode(body);

      EasyLoading.dismiss();
      print('Response: $res');

      // === SUCCESS ===
      if (response.statusCode == 200 && res['status'] == true) {
        final action = isEdit ? 'updated' : 'added';
        customToast('Branch $action successfully', Colors.green);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: Text(isEdit ? 'Updated!' : 'Success!'),
            content: Text(
                'Branch ${isEdit ? 'updated' : 'ID'}: ${res['data']?['lab_id'] ?? 'Successfully.'}'),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                  getBranchList();
                  onSuccess();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      // === FAILURE ===
      else {
        final msg = res['message'] ?? 'Failed to save branch';
        customToast(msg, Colors.red);
      }
    } catch (e) {
      print('Error: $e');
      EasyLoading.dismiss();
      customToast('Network error: $e', Colors.red);
    } finally {
      isLoading.value = false;
      update(['labs-branch']);
    }
  }

  Future<void> deactivateBranch(int branchId, bool currentStatus) async {
    final bool newStatus = !currentStatus; // Toggle status

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
            '${AppConstants.endpoint}/labs/details/$branchId/active-status'),
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
    update(['lab-test-details']);
  }
}
