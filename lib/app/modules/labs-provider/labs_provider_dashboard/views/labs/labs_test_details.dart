// ignore_for_file: avoid_print, invalid_use_of_protected_member, prefer_interpolation_to_compose_strings, deprecated_member_use, use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../../../constants/app_constants.dart';
import '../../../../../../utils/helper.dart';
import '../../../../../../utils/pdf_invoice_generate.dart';
import '../../controllers/labs_provider_dashboard_controller.dart';

class LabsTestDetails extends StatelessWidget {
  const LabsTestDetails({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dynamic arguments = Get.arguments;

    Map<String, dynamic>? bookingData;
    if (arguments is Map<String, dynamic>) {
      bookingData = arguments;
    } else if (arguments is List<dynamic> && arguments.isNotEmpty) {
      bookingData = arguments[0] as Map<String, dynamic>;
    }
    if (bookingData == null) return _buildNoDataScaffold();

    final RxList<Map<String, dynamic>> labTestDetails =
        (bookingData['lab_test_details'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .obs;
    final Map<String, dynamic> patientInfo =
        bookingData['patient_info'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> patientAddress =
        bookingData['patient_address'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> labDetails =
        bookingData['lab_details'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> paymentDetails =
        bookingData['payment_details'] as Map<String, dynamic>? ?? {};
    final String? prescriptionImageUrl = bookingData['prescription_image_url'];
    final String providerId = labDetails['provider_id']?.toString() ?? '1';
    final bookingDate = bookingData['booking_date'] != null
        ? DateTime.parse(bookingData['booking_date']).toLocal()
        : DateTime.now();
    final formattedDate =
        "${bookingDate.day} ${DateFormat('MMM yyyy').format(bookingDate)}, ${bookingData['booking_time'] ?? 'N/A'}";

    // REACTIVE TOTAL
    final RxDouble totalTestFees = 0.0.obs;
    final RxDouble serviceCharge = 0.0.obs;
    final RxDouble totalPayable = 0.0.obs;

    void updateTotal() {
      double sum = 0.0;
      for (var test in labTestDetails) {
        final qty = (test['qty'] as num?)?.toDouble() ?? 1.0;
        final price = (test['new_test_charges'] as num?)?.toDouble() ?? 0.0;
        sum += qty * price;
      }
      totalTestFees.value = sum;
      totalPayable.value = sum + serviceCharge.value;
    }

    ever(labTestDetails, (_) => updateTotal());
    ever(serviceCharge, (_) => updateTotal());
    updateTotal();

    // LAB SELECTION CONTROLLER
    final LabSelectionController labController =
        Get.put(LabSelectionController(providerId, serviceCharge));

    return Scaffold(
      backgroundColor: AppConstants.appScaffoldBgColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- LAB TESTS ----------
            AdjustableCard(
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Lab Tests',
                            style: TextStyle(
                                color: AppConstants.appPrimaryColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        labTestDetails.isEmpty
                            ? TextButton.icon(
                                onPressed: () => _showAddTestsBottomSheet(
                                    context, providerId, labTestDetails),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Tests'),
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.green),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Obx(() {
                      if (labTestDetails.isEmpty) {
                        return _buildEmptyTestsState(
                            context, providerId, labTestDetails);
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: labTestDetails.length,
                        itemBuilder: (context, index) {
                          final test = labTestDetails[index];
                          final testId = test['lab_test_id']?.toString() ??
                              index.toString();
                          return Dismissible(
                            key: Key('test_$testId'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (_) => _showRemoveConfirmation(
                                context, test['test_name'] ?? 'Test'),
                            onDismissed: (_) {
                              labTestDetails.removeAt(index);
                              customToast('Test removed');
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: Image.asset(
                                    'assets/image/blood-test.png',
                                    width: 40,
                                    height: 40),
                                title: Text(test['test_name'] ?? 'N/A',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Row(
                                    children: [
                                      Text('₹${test['new_test_charges'] ?? 0}',
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold)),
                                      if (test['old_test_charges'] != null &&
                                          test['old_test_charges'] !=
                                              test['new_test_charges'])
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 8),
                                          child: Text(
                                              '₹${test['old_test_charges']}',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color:
                                                      AppConstants.appPg2Color,
                                                  decoration: TextDecoration
                                                      .lineThrough)),
                                        ),
                                    ],
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Qty: ${test['qty'] ?? 1}',
                                        style: const TextStyle(
                                            fontSize: 14, color: Colors.grey)),
                                    bookingData!['lab_test_details'] == null
                                        ? IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red),
                                            onPressed: () async {
                                              final confirm =
                                                  await _showRemoveConfirmation(
                                                      context,
                                                      test['test_name'] ??
                                                          'Test');
                                              if (confirm == true) {
                                                labTestDetails.removeAt(index);
                                                customToast('Test removed');
                                              }
                                            },
                                          )
                                        : const SizedBox.shrink(),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            // ---------- PRESCRIPTION ----------
            AdjustableCard(
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upload Prescriptions',
                        style: TextStyle(
                            color: AppConstants.appPrimaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    if (prescriptionImageUrl != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: Image.network(prescriptionImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.error)),
                            ),
                            ElevatedButton(
                              onPressed: () => _showPrescriptionFullScreen(
                                  prescriptionImageUrl),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.appPrimaryColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8))),
                              child: const Text('Preview',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No prescription uploaded.',
                            style: TextStyle(fontSize: 16)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            // ---------- BOOKING DETAILS ----------
            AdjustableCard(
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Booking Details',
                        style: TextStyle(
                            color: AppConstants.appPrimaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    _buildDetailRow('Booking ID',
                        bookingData['lab_test_booking_id'] ?? 'N/A'),
                    _buildDetailRow('Reference ID',
                        bookingData['booking_reference_no'] ?? 'N/A'),
                    _buildDetailRow(
                        'Patient Name', patientInfo['name'] ?? 'N/A'),
                    _buildDetailRow('Booking Date', formattedDate),
                    labTestDetails.isEmpty
                        ? Obx(() {
                            final defaultLabName =
                                labDetails['lab_name'] ?? 'Select Lab';
                            final selectedLabName =
                                labController.selectedLabName.value;
                            final displayName = selectedLabName.isNotEmpty
                                ? selectedLabName
                                : defaultLabName;
                            return _buildDetailRow(
                              'Lab Selected',
                              TextButton(
                                onPressed: () => labController
                                    .showLabBranchesBottomSheet(context),
                                child: Text(displayName,
                                    style: const TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                        fontSize: 16)),
                              ),
                            );
                          })
                        : const SizedBox.shrink(),
                    labTestDetails.isEmpty
                        ? Obx(() {
                            final slot = labController.selectedTime.value;
                            return _buildDetailRow(
                              'Slot Booked',
                              slot.isNotEmpty ? slot : 'Not selected',
                            );
                          })
                        : const SizedBox.shrink(),
                    _buildDetailRow('Booking Type',
                        bookingData['test_booking_type'] ?? 'N/A'),
                    _buildDetailRow(
                      'Pickup Address',
                      '${patientAddress['address'] ?? ''}, ${patientAddress['city'] ?? ''}, ${patientAddress['state'] ?? ''}, ${patientAddress['pincode'] ?? ''}',
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            // ---------- PAYMENT DETAILS ----------
            AdjustableCard(
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Obx(() {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment Details',
                          style: TextStyle(
                              color: AppConstants.appPrimaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      _buildDetailRow('Total Test Fees',
                          '₹${totalTestFees.value.toStringAsFixed(2)}'),
                      _buildDetailRow(
                        'Service Charge',
                        '₹${(() {
                          final value = bookingData!['service_charge'];

                          if (value == null) {
                            return serviceCharge.value.toStringAsFixed(2);
                          }

                          if (value is num) {
                            return value.toStringAsFixed(2);
                          }

                          final parsed = num.tryParse(value.toString());
                          if (parsed != null) {
                            return parsed.toStringAsFixed(2);
                          }

                          return serviceCharge.value.toStringAsFixed(2);
                        })()}',
                      ),
                      _buildDetailRow('Discount',
                          '-₹' + bookingData!['discount'].toString()),
                      _buildDetailRow('Payment Mode',
                          paymentDetails['paymentStatus'] ?? 'N/A'),
                      _buildDetailRow('Transaction ID',
                          paymentDetails['transactionId'] ?? 'N/A'),
                      _buildDetailRow(
                        'Total Payable',
                        '₹${(() {
                          final value = bookingData!['final_charges'];

                          if (value == null) {
                            return totalPayable.value.toStringAsFixed(2);
                          }

                          if (value is num) {
                            return value.toStringAsFixed(2);
                          }

                          final parsed = num.tryParse(value.toString());
                          if (parsed != null) {
                            return parsed.toStringAsFixed(2);
                          }

                          return totalPayable.value.toStringAsFixed(2);
                        })()}',
                        isLast: true,
                      ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 5),
            // ---------- STATUS + SUBMIT ----------
            Column(
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  color: paymentDetails['paymentStatus'] == 'Pending'
                      ? Colors.orange.shade50
                      : paymentDetails['paymentStatus'] == 'Paid'
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: bookingData['booking_status'] == 'CANCELLED'
                        ? const Text(
                            'Booking has been canceled. Your amount will be refunded within 72 working days.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Status: ${paymentDetails['paymentStatus'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: paymentDetails['paymentStatus'] ==
                                          'Pending'
                                      ? Colors.orange
                                      : paymentDetails['paymentStatus'] ==
                                              'Paid'
                                          ? Colors.green
                                          : Colors.red,
                                ),
                              ),
                              if (paymentDetails['paymentStatus'] == 'Pending')
                                ElevatedButton(
                                  onPressed: () => customToast(
                                      'Payment initiated', Colors.blue),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppConstants.appPrimaryColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8))),
                                  child: const Text('Pay Now',
                                      style: TextStyle(color: Colors.white)),
                                ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      persistentFooterButtons: [
        // ===============================
        // SHOW DOWNLOAD BUTTONS IF COMPLETED
        // ===============================

        if ((bookingData['booking_status']?.toString() ?? '') == 'COMPLETED')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadReport(bookingData!),
                    icon: const Icon(Icons.description, size: 22),
                    label: const Text('Download Report',
                        style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _smartDownloadInvoice(context, bookingData!),
                    icon: const Icon(Icons.receipt_long, size: 22),
                    label: const Text('Download Invoice',
                        style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ===============================
        // OTHER BUTTONS
        // ===============================
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ---------------------------
            // SHOW SUBMIT & REQUEST BUTTON
            // ---------------------------
            if (labTestDetails.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 10),
                child: ElevatedButton(
                  onPressed: () async {
                    // VALIDATIONS
                    if (labTestDetails.isEmpty) {
                      customToast('Please add at least one test', Colors.red);
                      return;
                    }
                    if (labController.selectedLabId.value.isEmpty) {
                      customToast('Please select a lab', Colors.red);
                      return;
                    }
                    if (labController.selectedTime.value.isEmpty) {
                      customToast('Please select a time slot', Colors.red);
                      return;
                    }

                    final bookingId = bookingData!['lab_test_booking_id'];
                    final token = await readStr('token') ?? '';

                    final request = http.MultipartRequest(
                      'PUT',
                      Uri.parse(
                        '${AppConstants.endpoint}/labs/lab-test-bookings/$bookingId',
                      ),
                    );

                    request.headers['Authorization'] = 'Bearer $token';

                    request.fields.addAll({
                      'lab_id': labController.selectedLabId.value,
                      'patient_id': bookingData['patient_id'].toString(),
                      'booking_date': DateFormat('yyyy-MM-dd').format(
                          DateTime.parse(labController.selectedDate.value)),
                      'booking_time': labController.selectedTime.value,
                      'service_charge': serviceCharge.value.toStringAsFixed(2),
                      'test_fees': totalTestFees.value.toStringAsFixed(2),
                      'final_charges': totalPayable.value.toStringAsFixed(2),
                      'booking_status': 'IN_PROGRESS',
                      'lab_test_details': jsonEncode(labTestDetails.value),
                    });

                    try {
                      EasyLoading.show(status: 'Updating status...');
                      final streamedResponse = await request
                          .send()
                          .timeout(const Duration(seconds: 30));
                      final response =
                          await http.Response.fromStream(streamedResponse);

                      print("STATUS CODE: ${response.statusCode}");
                      print("RESPONSE BODY: ${response.body}");

                      if (response.statusCode == 200) {
                        final json = jsonDecode(response.body);
                        if (json['status'] == true) {
                          customToast(
                              'Booking updated successfully!', Colors.green);
                        } else {
                          customToast(json['message'] ?? 'Failed', Colors.red);
                        }
                      } else {
                        customToast(
                            'Error: ${response.statusCode}', Colors.red);
                      }
                    } catch (e) {
                      customToast('Network error: $e', Colors.red);
                    } finally {
                      EasyLoading.dismiss();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(160, 45),
                  ),
                  child: const Text(
                    'Submit & Request',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

            // ---------------------------
            // UPDATE STATUS POPUP
            // ---------------------------
            if (bookingData['booking_status'] != 'CANCELLED' &&
                bookingData['booking_status'] != 'COMPLETED')
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: PopupMenuButton<String>(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    final bookingId = bookingData!['lab_test_booking_id'];
                    final message =
                        "Are you sure you want to mark this booking as $value?";

                    if (value == 'COMPLETED') {
                      _showReportUploadDialog(
                          context, bookingId, value, message);
                    } else {
                      _showStatusConfirmationDialog(
                          context, bookingId, value, message);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: "CONFIRMED",
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text("Mark as Confirmed"),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "IN_PROGRESS",
                      child: Row(
                        children: [
                          Icon(Icons.work_history, color: Colors.orange),
                          SizedBox(width: 8),
                          Text("Mark as In Progress"),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "COMPLETED",
                      child: Row(
                        children: [
                          Icon(Icons.task_alt, color: Colors.blue),
                          SizedBox(width: 8),
                          Text("Mark as Completed"),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "CANCELLED",
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Mark as Cancelled"),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppConstants.appPrimaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.more_vert, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          "Update Status",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ==============================================================
  // ====================== REPORT UPLOAD DIALOG ==================
  // ==============================================================
  void _showReportUploadDialog(
    BuildContext context,
    int bookingId,
    String status,
    String message,
  ) {
    final TextEditingController titleCtrl = TextEditingController();
    final TextEditingController notesCtrl = TextEditingController();
    File? selectedFile;
    String? fileName;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: StatefulBuilder(
          builder: (context, setState) => Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxHeight: 700),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.file_download_done_outlined,
                        color: AppConstants.appPrimaryColor, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Upload Lab Report',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.appPrimaryColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(message,
                    style: const TextStyle(fontSize: 15),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                // ---------- FILE PICKER ----------
                GestureDetector(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                    );
                    if (result != null && result.files.isNotEmpty) {
                      final file = File(result.files.single.path!);
                      final name = result.files.single.name;
                      final ext = name.split('.').last.toLowerCase();
                      setState(() {
                        selectedFile = file;
                        fileName = name;
                      });

                      // Only show preview for images
                      if (ext == 'jpg' || ext == 'jpeg' || ext == 'png') {
                        setState(() {});
                      } else {
                        setState(() {});
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                      color: selectedFile == null
                          ? Colors.grey[50]
                          : Colors.green[50],
                    ),
                    child: Row(
                      children: [
                        Icon(
                            selectedFile == null
                                ? Icons.attach_file
                                : Icons.check_circle,
                            color: selectedFile == null
                                ? Colors.grey
                                : Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedFile == null
                                ? 'Tap to select report (PDF/Image)'
                                : fileName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: selectedFile == null
                                  ? Colors.grey[700]
                                  : Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (selectedFile != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() {
                              selectedFile = null;
                              fileName = null;
                            }),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ---------- TITLE ----------
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Report Title',
                    hintText: 'e.g., CBC Report',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                // ---------- NOTES ----------
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Any remarks about the report',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.note),
                  ),
                ),
                const SizedBox(height: 20),
                // ---------- BUTTONS ----------
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Cancel',
                              style: TextStyle(color: Colors.grey))),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selectedFile == null
                            ? null
                            : () {
                                Get.back();
                                _confirmStatusUpdate(
                                    context,
                                    bookingId,
                                    status,
                                    "Mark as Completed & Upload Report?",
                                    selectedFile!,
                                    title: titleCtrl.text.isEmpty
                                        ? null
                                        : titleCtrl.text,
                                    notes: notesCtrl.text);
                              },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.appPrimaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: const Text('Upload Report',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // --------------------------------------------------------------
  // ------------------- STATUS CONFIRMATION --------------------
  // --------------------------------------------------------------
  void _showStatusConfirmationDialog(
      BuildContext context, int bookingId, String status, String message) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Action'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final ctrl = Get.find<LabsProviderDashboardController>();
              await ctrl.updateBookingStatus(
                bookingId: bookingId,
                status: status,
                remark:
                    "Booking marked as ${status.replaceAll('_', ' ').toLowerCase()} by lab provider",
                tab: Get.currentRoute.contains('today')
                    ? 'today'
                    : Get.currentRoute.contains('upcoming')
                        ? 'upcoming'
                        : 'completed',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  // ------------------- FINAL CONFIRM + UPLOAD ------------------
  // --------------------------------------------------------------
  void _confirmStatusUpdate(
    BuildContext context,
    int bookingId,
    String status,
    String message,
    File reportFile, {
    String? title,
    String? notes,
  }) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final ctrl = Get.find<LabsProviderDashboardController>();
              await ctrl.updateBookingStatus(
                bookingId: bookingId,
                status: status,
                remark:
                    "Booking marked as ${status.replaceAll('_', ' ').toLowerCase()} by lab provider",
                tab: Get.currentRoute.contains('today')
                    ? 'today'
                    : Get.currentRoute.contains('upcoming')
                        ? 'upcoming'
                        : 'completed',
                reportFile: reportFile,
                reportTitle: title,
                reportNotes: notes,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // ====================== HELPER WIDGETS ========================
  // ==============================================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppConstants.appPrimaryColor,
      title: const Text('Lab Booking Details'),
      centerTitle: true,
      foregroundColor: Colors.white,
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
      ),
    );
  }

  Widget _buildNoDataScaffold() {
    return Scaffold(
      backgroundColor: AppConstants.appScaffoldBgColor,
      appBar: AppBar(
        backgroundColor: AppConstants.appPrimaryColor,
        title: const Text('Order Details'),
        centerTitle: true,
        foregroundColor: Colors.white,
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50)),
        ),
      ),
      body: const Center(child: Text('No order data available')),
    );
  }

  Widget _buildEmptyTestsState(BuildContext context, String providerId,
      RxList<Map<String, dynamic>> labTestDetails) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.assignment_late_outlined,
              size: 60, color: Colors.grey[400]),
          const SizedBox(height: 10),
          const Text('No tests added yet',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, dynamic value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 15),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold))),
          Expanded(
            flex: 3,
            child: value is Widget
                ? Align(alignment: Alignment.centerRight, child: value)
                : Text(
                    value.toString(),
                    style: const TextStyle(fontSize: 15),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showRemoveConfirmation(BuildContext context, String testName) {
    return Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 50, color: Colors.orange),
              const SizedBox(height: 16),
              Text('Remove Test',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.appPrimaryColor)),
              const SizedBox(height: 8),
              Text(
                  'Are you sure you want to remove "$testName" from this booking?',
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                      onPressed: () => Get.back(result: false),
                      child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () => Get.back(result: true),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Remove',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrescriptionFullScreen(String url) {
    Get.to(() => Scaffold(
          appBar: AppBar(
            foregroundColor: Colors.white,
            title: const Text('Prescription'),
            backgroundColor: AppConstants.appPrimaryColor,
          ),
          body: Center(
            child: PhotoView(
              imageProvider: NetworkImage(url),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              heroAttributes:
                  const PhotoViewHeroAttributes(tag: "prescription"),
            ),
          ),
        ));
  }

  // --------------------------------------------------------------
  // ------------------- ADD TESTS BOTTOM SHEET -------------------
  // --------------------------------------------------------------
  void _showAddTestsBottomSheet(BuildContext context, String providerId,
      RxList<Map<String, dynamic>> labTestDetails) {
    final controllerTag = 'add_tests_$providerId';
    Get.put(AddTestsController(providerId), tag: controllerTag);
    Get.bottomSheet(
      Container(
        height: Get.height * 0.95,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: GetX<AddTestsController>(
          tag: controllerTag,
          builder: (ctrl) => Column(
            children: [
              Row(
                children: [
                  const Text('Add Lab Tests',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              TextField(
                controller: ctrl.searchController,
                decoration: InputDecoration(
                  hintText: 'Search tests... (min 3 chars)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) => ctrl.debounceSearch(val.trim()),
              ),
              const SizedBox(height: 10),
              if (ctrl.cart.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Added to Cart',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      ...ctrl.cart.entries.map((e) {
                        final test = ctrl.allTests.firstWhere(
                            (t) => t['lab_test_id'].toString() == e.key,
                            orElse: () => {
                                  'test_name': 'Unknown',
                                  'new_test_charges': 0
                                });
                        final price =
                            (test['new_test_charges'] ?? 0).toDouble();
                        final lineTotal = price * e.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Text(
                                      '• ${test['test_name']} × ${e.value}',
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis)),
                              Text('₹${lineTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        );
                      }).toList(),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Obx(() => Text(
                              '₹${ctrl.totalPrice.value.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green))),
                        ],
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ctrl.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : ctrl.filteredTests.isEmpty
                        ? const Center(child: Text('No tests found'))
                        : ListView.builder(
                            itemCount: ctrl.filteredTests.length,
                            itemBuilder: (ctx, i) {
                              final test = ctrl.filteredTests[i];
                              final id = test['lab_test_id'].toString();
                              final qty = ctrl.cart[id] ?? 0;
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // ---------- Left side: Test name & price ----------
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              test['test_name'] ?? 'N/A',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '₹${test['new_test_charges'] ?? 0}',
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // ---------- Right side: Quantity controls ----------
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: qty > 0
                                                ? () {
                                                    ctrl.cart[id] = qty - 1;
                                                    if (ctrl.cart[id] == 0) {
                                                      ctrl.cart.remove(id);
                                                    }
                                                    ctrl.cart.refresh();
                                                  }
                                                : null,
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                              size: 22,
                                            ),
                                          ),
                                          Text(
                                            '$qty',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              ctrl.cart[id] = qty + 1;
                                              ctrl.cart.refresh();
                                            },
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                              size: 22,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              if (ctrl.cart.isNotEmpty)
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        final addedTests = ctrl.cart.entries.map((e) {
                          final test = ctrl.allTests.firstWhere(
                              (t) => t['lab_test_id'].toString() == e.key,
                              orElse: () => {});
                          return {
                            "qty": e.value,
                            "lab_ids": [int.parse(providerId)],
                            "subtotal":
                                (test['new_test_charges'] ?? 0) * e.value,
                            "test_code": test['test_code'] ?? '',
                            "test_name": test['test_name'] ?? 'Unknown',
                            "test_type": test['test_type'] ?? '',
                            "lab_test_id": test['lab_test_id'],
                            "organ_system": test['organ_system'] ?? '',
                            "sample_required": test['sample_required'] ?? '',
                            "turnaround_time": test['turnaround_time'] ?? '',
                            "new_test_charges": test['new_test_charges'],
                            "old_test_charges": test['old_test_charges'],
                            "test_description": test['test_description'] ?? '',
                            "prescription_required":
                                test['prescription_required'] ?? false,
                            "preparation_instructions":
                                test['preparation_instructions'] ?? '',
                          };
                        }).toList();
                        labTestDetails.addAll(addedTests);
                        labTestDetails.refresh();
                        Get.back();
                        Get.delete<AddTestsController>(
                            tag: controllerTag, force: true);
                        customToast('${addedTests.length} test(s) added!');
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 50)),
                      child: const Text('Add to Booking',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  // Request storage permission
  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) await openAppSettings();
    }
    return true;
  }

  // DOWNLOAD REPORT
  void _downloadReport(Map<String, dynamic> bookingData) async {
    try {
      // Validate reports list
      final reports = bookingData['lab_reports'];
      if (reports == null || reports.isEmpty) {
        customToast('Report not uploaded yet', Colors.orange);
        return;
      }

      final report = reports[0];

      // Extract booking & patient
      final booking = report['lab_test_booking'] ?? {};
      final patient = booking['patient_details']?['user'] ?? {};

      final reportUrl = report['report_file_path'] ?? '';
      final reportTitle = (report['report_title'] ?? 'Report')
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

      final bookingId = booking['booking_reference_no'] ?? 'Unknown';

      final name =
          '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}'.trim();

      if (reportUrl.isEmpty) {
        customToast('Report URL not available', Colors.red);
        return;
      }

      customToast('Downloading report...');

      // Download report
      final response = await http
          .get(Uri.parse(reportUrl))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        customToast('Failed to download report', Colors.red);
        return;
      }

      final bytes = response.bodyBytes;

      // Choose directory
      Directory? directory;

      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final safeTitle = reportTitle.replaceAll(' ', '_');
      final fileName = '$bookingId-$safeTitle.pdf';

      final filePath = '${directory!.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Permissions
      if (await _requestPermission()) {
        customToast('Report saved & ready to share');

        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(content: Text('Saved: $filePath')),
        );

        // Share file
        await Share.shareXFiles(
          [XFile(filePath)],
          text:
              'Lab Report\nPatient: $name\nBooking: $bookingId\nTitle: $reportTitle',
          subject: 'Lab Report - $bookingId',
        );
      }
    } catch (e) {
      customToast('Failed to save/share report', Colors.red);
      print('Error downloading report: $e');
    }
  }

  Future<void> _smartDownloadInvoice(
      BuildContext context, Map<String, dynamic> bookingData) async {
    final bookingId = bookingData['lab_test_booking_id']?.toString() ?? '0';
    EasyLoading.show(status: 'Generating invoice...');

    try {
      final token = await readStr('token') ?? '';
      final profileId = await readStr('profileId') ?? '1';

      // Build API URL
      final uri = Uri.parse(
        '${AppConstants.endpoint}/labs/provider-dashboard/$profileId/invoices?search=$bookingId',
      );

      // GET request
      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 15));

      var invoiceData;

      if (res.statusCode == 200) {
        final body = json.decode(res.body);

        if (body['status'] == true &&
            body['invoices'] != null &&
            body['invoices'].isNotEmpty) {
          invoiceData = body['invoices'][0];
        }
      }

      print('invoiceData: $invoiceData');

      await generatePerfectInvoicePDF(context, invoiceData, 'labs');
    } catch (e) {
      EasyLoading.showError("Failed to generate invoice");
    } finally {
      EasyLoading.dismiss();
    }
  }
}

// ==============================================================
// ====================== LAB SELECTION CONTROLLER =============
// ==============================================================
class LabSelectionController extends GetxController {
  final String providerId;
  final RxDouble serviceCharge;
  final RxList<Map<String, dynamic>> branchList = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedLabId = ''.obs;
  final RxString selectedLabName = ''.obs;
  final RxList<Map<String, dynamic>> schedule = <Map<String, dynamic>>[].obs;
  final RxString selectedDate =
      DateFormat('yyyy-MM-dd').format(DateTime.now()).obs;
  final RxString selectedTime = ''.obs;
  Position? _userPosition;
  final Map<String, RxString> _distanceMap = {};
  final Map<String, String> _distanceCache = {};
  int _latestRequestId = 0;

  LabSelectionController(this.providerId, this.serviceCharge);

  @override
  void onInit() {
    super.onInit();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      await _ensureLocationPermission();
      _userPosition ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      customToast('Location unavailable');
    }
  }

  Future<void> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      customToast('Please enable location services');
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        customToast('Location permission required');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      customToast('Enable location in settings');
      return;
    }
  }

  Future<String> _calculateDistanceRobust(Map<String, dynamic> branch) async {
    final labId = branch['lab_id'].toString();
    if (_distanceCache.containsKey(labId)) return _distanceCache[labId]!;
    try {
      double? lat = double.tryParse(branch['latitude']?.toString() ?? '');
      double? lng = double.tryParse(branch['longitude']?.toString() ?? '');
      if (lat == null || lng == null || lat == 0 || lng == 0) {
        final address =
            '${branch['lab_address'] ?? ''}, ${branch['area'] ?? ''}, ${branch['city'] ?? ''}';
        if (address.trim().length > 5) {
          try {
            final locations =
                await locationFromAddress(address, localeIdentifier: "en");
            if (locations.isNotEmpty) {
              final loc = locations.first;
              lat = loc.latitude;
              lng = loc.longitude;
            }
          } catch (e) {}
        }
      }
      if (lat == null || lng == null || _userPosition == null) {
        return 'N/A';
      }
      final distanceInMeters = Geolocator.distanceBetween(
        _userPosition!.latitude,
        _userPosition!.longitude,
        lat,
        lng,
      );
      final distanceInKm = distanceInMeters / 1000;
      final formatted = distanceInKm < 1
          ? '${(distanceInKm * 1000).toStringAsFixed(0)} m'
          : '${distanceInKm.toStringAsFixed(1)} km';
      _distanceCache[labId] = formatted;
      return formatted;
    } catch (e) {
      return 'N/A';
    }
  }

  void showLabBranchesBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Select Lab Branch',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    onPressed: () => Get.back(), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(),
            Expanded(
              child: Obx(() {
                if (isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (branchList.isEmpty) {
                  return const Center(child: Text('No branches found'));
                }
                return ListView.builder(
                  itemCount: branchList.length,
                  itemBuilder: (ctx, i) {
                    final branch = branchList[i];
                    final labName = branch['lab_name'] ?? 'Unknown Lab';
                    final address =
                        '${branch['lab_address'] ?? ''}, ${branch['area'] ?? ''}, ${branch['city'] ?? ''}';
                    final photo =
                        (branch['lab_photos'] as List?)?.isNotEmpty == true
                            ? branch['lab_photos'][0]
                            : null;
                    final labId = branch['lab_id'].toString();
                    if (!_distanceMap.containsKey(labId)) {
                      _distanceMap[labId] = 'Calculating...'.obs;
                      _calculateDistanceRobust(branch).then((dist) {
                        if (_distanceMap.containsKey(labId)) {
                          _distanceMap[labId]!.value = dist;
                        }
                      });
                    }
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          selectedLabId.value = labId;
                          selectedLabName.value = labName;
                          Get.back();
                          showSlotPickerBottomSheet(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: photo != null
                                    ? Image.network(photo,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[300],
                                            child: const Icon(
                                                Icons.local_hospital)))
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.local_hospital,
                                            color: Colors.grey)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(labName,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(address,
                                        style: const TextStyle(
                                            fontSize: 13, color: Colors.grey),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 6),
                                    Obx(() {
                                      final dist = _distanceMap[labId]?.value ??
                                          'Calculating...';
                                      return Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 14, color: Colors.red),
                                          const SizedBox(width: 4),
                                          Text(
                                            dist,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: dist == 'N/A' ||
                                                      dist == 'Calculating...'
                                                  ? Colors.grey
                                                  : Colors.red,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
    loadBranches();
  }

  Future<void> loadBranches() async {
    branchList.clear();
    isLoading.value = true;
    final currentRequestId = ++_latestRequestId;
    try {
      final uri = Uri.parse(
          '${AppConstants.endpoint}/labs/provider-dashboard/$providerId/lab-branches');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      final res = json.decode(response.body);
      if (currentRequestId != _latestRequestId) return;
      if (response.statusCode == 200 && res['status'] == true) {
        branchList.value = List<Map<String, dynamic>>.from(res['list']);
      } else {
        customToast(res['message'] ?? 'Failed to load branches');
        branchList.clear();
      }
    } catch (e) {
      print(e);
    } finally {
      if (currentRequestId == _latestRequestId) isLoading.value = false;
    }
  }

  void showSlotPickerBottomSheet(BuildContext context) {
    fetchSchedule(selectedLabId.value, selectedDate.value);
    Get.bottomSheet(
      Container(
        height: Get.height * 0.85,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: Text('Select Time Slot - $selectedLabName',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(
                    onPressed: () => Get.back(), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.parse(selectedDate.value),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) {
                      selectedDate.value =
                          DateFormat('yyyy-MM-dd').format(date);
                      fetchSchedule(selectedLabId.value, selectedDate.value);
                    }
                  },
                  child: Text(selectedDate.value,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                if (isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (schedule.isEmpty) {
                  return const Center(child: Text('No slots available'));
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: schedule.length,
                  itemBuilder: (ctx, i) {
                    final slot = schedule[i];
                    final time = slot['slot'] ?? '';
                    final priceStr = slot['price']?.toString() ?? '0';
                    final price =
                        double.tryParse(priceStr.replaceAll(',', '')) ?? 0.0;
                    final available =
                        (slot['available_slot'] as num?)?.toInt() ?? 0;
                    final isAvailable = available > 0;
                    return ElevatedButton(
                      onPressed: isAvailable
                          ? () {
                              serviceCharge.value = price;
                              selectedTime.value = '$time';
                              customToast('Slot selected: $time');
                              Get.back();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isAvailable ? Colors.green : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        elevation: isAvailable ? 4 : 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(time,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Center(
                                child: Text('₹$price',
                                    style: const TextStyle(fontSize: 14)),
                              ),
                              Center(
                                child: Text('$available slots',
                                    style: const TextStyle(fontSize: 14)),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> fetchSchedule(String labId, String date) async {
    isLoading.value = true;
    schedule.clear();
    try {
      final token = await readStr('token') ?? '';
      final url =
          '${AppConstants.endpoint}/labs/$labId/schedule-pricing?date=$date';
      final response = await http
          .get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['status'] == true) {
          schedule.value = List<Map<String, dynamic>>.from(res['data'] ?? []);
        }
      } else {
        customToast("No schedule found");
      }
    } catch (e) {
      customToast("Error loading schedule: $e");
    } finally {
      isLoading.value = false;
    }
  }
}

// ==============================================================
// ====================== ADD TESTS CONTROLLER =================
// ==============================================================
class AddTestsController extends GetxController {
  final String providerId;
  final TextEditingController searchController = TextEditingController();
  final RxList<Map<String, dynamic>> allTests = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredTests =
      <Map<String, dynamic>>[].obs;
  final RxMap<String, int> cart = <String, int>{}.obs;
  final RxBool isLoading = true.obs;
  final RxDouble totalPrice = 0.0.obs;
  int latestRequestId = 0;
  Timer? debounce;

  AddTestsController(this.providerId);

  @override
  void onInit() {
    super.onInit();
    loadTests();
    ever(cart, (_) => _calculateTotalPrice());
  }

  void _calculateTotalPrice() {
    double total = 0.0;
    for (var entry in cart.entries) {
      final test = allTests.firstWhere(
          (t) => t['lab_test_id'].toString() == entry.key,
          orElse: () => {});
      final price = (test['new_test_charges'] ?? 0).toDouble();
      total += price * entry.value;
    }
    totalPrice.value = total;
  }

  void debounceSearch(String query) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.length > 2) {
        searchTests(query);
      } else {
        filteredTests.value = allTests;
      }
    });
  }

  Future<void> loadTests() async {
    final current = ++latestRequestId;
    isLoading.value = true;
    try {
      final token = await readStr('token');
      final url =
          '${AppConstants.endpoint}/labs/lab-tests/provider/$providerId';
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }).timeout(const Duration(seconds: 10));
      if (current != latestRequestId) return;
      final res = json.decode(response.body);
      if (response.statusCode == 200 && res['status'] == true) {
        allTests.value = List<Map<String, dynamic>>.from(res['list']);
        filteredTests.value = allTests;
      } else {
        customToast(res['message'] ?? 'Failed to load');
      }
    } catch (e) {
      if (current == latestRequestId) customToast('Error: $e');
    } finally {
      if (current == latestRequestId) isLoading.value = false;
    }
  }

  Future<void> searchTests(String query) async {
    final current = ++latestRequestId;
    isLoading.value = true;
    try {
      final token = await readStr('token');
      final profileId = await readStr('profileId') ?? providerId;
      final url =
          '${AppConstants.endpoint}/labs/lab-tests/search?testName=$query&lab_service_provider_id=$profileId';
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 10));
      if (current != latestRequestId) return;
      final res = json.decode(response.body);
      if (response.statusCode == 200 && res['status'] == true) {
        filteredTests.value =
            List<Map<String, dynamic>>.from(res['list'] ?? []);
      } else {
        customToast(res['message'] ?? 'No results');
        filteredTests.value = [];
      }
    } catch (e) {
      if (current == latestRequestId) {
        customToast('Search failed');
        filteredTests.value = [];
      }
    } finally {
      if (current == latestRequestId) isLoading.value = false;
    }
  }

  @override
  void onClose() {
    debounce?.cancel();
    searchController.dispose();
    super.onClose();
  }
}
