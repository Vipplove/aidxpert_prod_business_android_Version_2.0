// ignore_for_file: avoid_print, invalid_use_of_protected_member, prefer_interpolation_to_compose_strings, deprecated_member_use, use_build_context_synchronously, prefer_typing_uninitialized_variables
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
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';
import '../../../../../utils/pdf_invoice_generate.dart';
import '../controllers/diagnostics_provider_dashboard_controller.dart';

class DiagnosticsTestDetails extends StatelessWidget {
  const DiagnosticsTestDetails({Key? key}) : super(key: key);

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

    // Updated keys for new API
    final RxList<Map<String, dynamic>> labTestDetails =
        (bookingData['diagnostic_test_detail'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .obs;

    final Map<String, dynamic> patientInfo =
        bookingData['patient_info'] as Map<String, dynamic>? ?? {};

    // Handle patient_address (can be list or map)
    dynamic patientAddressRaw = bookingData['patient_address'];
    Map<String, dynamic> patientAddress = {};
    if (patientAddressRaw is List && patientAddressRaw.isNotEmpty) {
      patientAddress = patientAddressRaw[0] as Map<String, dynamic>;
    } else if (patientAddressRaw is Map) {
      patientAddress = patientAddressRaw.cast<String, dynamic>();
    }

    final Map<String, dynamic> labDetails =
        bookingData['diagnostic_center_details'] as Map<String, dynamic>? ?? {};

    final String? prescriptionImageUrl = bookingData['prescription_image_url'];
    final String providerId =
        labDetails['diagnostic_center_id']?.toString() ?? '1';

    final String bookingIdStr =
        bookingData['diagnostic_test_booking_id']?.toString() ?? '0';
    final int bookingId = int.tryParse(bookingIdStr) ?? 0;

    final bookingDate = bookingData['booking_date'] != null
        ? DateTime.parse(bookingData['booking_date']).toLocal()
        : DateTime.now();

    final formattedDate =
        "${bookingDate.day} ${DateFormat('MMM yyyy').format(bookingDate)}, ${bookingData['booking_time'] ?? 'N/A'}";

    // Reactive Totals
    final RxDouble totalTestFees = 0.0.obs;
    final RxDouble serviceCharge =
        ((bookingData['service_charge'] as num?)?.toDouble() ?? 0.0).obs;
    final RxDouble discount =
        ((bookingData['discount'] as num?)?.toDouble() ?? 0.0).obs;
    final RxDouble totalPayable = 0.0.obs;

    void updateTotal() {
      double sum = 0.0;
      for (var test in labTestDetails) {
        final qty = (test['qty'] as num?)?.toDouble() ?? 1.0;
        final price = (test['new_test_charges'] as num?)?.toDouble() ?? 0.0;
        sum += qty * price;
      }
      totalTestFees.value = sum;
      totalPayable.value = sum + serviceCharge.value - discount.value;
    }

    ever(labTestDetails, (_) => updateTotal());
    ever(serviceCharge, (_) => updateTotal());
    ever(discount, (_) => updateTotal());
    updateTotal();

    return Scaffold(
      backgroundColor: AppConstants.appScaffoldBgColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- DIAGNOSTIC TESTS ----------
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
                        Text(
                          'Diagnostic Tests',
                          style: TextStyle(
                              color: AppConstants.appPrimaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
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
                          final testId =
                              test['diagnostic_test_id']?.toString() ??
                                  index.toString();

                          return Dismissible(
                            key: Key('test_$testId'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 10),
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
                              elevation: 1,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 0),
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
                                                color: AppConstants.appPg2Color,
                                                decoration:
                                                    TextDecoration.lineThrough),
                                          ),
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
                    if (prescriptionImageUrl != null &&
                        prescriptionImageUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(prescriptionImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.error)),
                              ),
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
                        padding: EdgeInsets.all(16.0),
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
                        bookingData['diagnostic_test_booking_id'] ?? 'N/A'),
                    _buildDetailRow('Reference ID',
                        bookingData['booking_reference_no'] ?? 'N/A'),
                    _buildDetailRow(
                        'Patient Name', patientInfo['name'] ?? 'N/A'),
                    _buildDetailRow('Booking Date', formattedDate),
                    _buildDetailRow('Booking Type',
                        bookingData['test_booking_type'] ?? 'N/A'),
                    _buildDetailRow(
                      'Pickup Address',
                      patientAddress.isEmpty
                          ? 'At Center Visit'
                          : '${patientAddress['address'] ?? ''}, ${patientAddress['city'] ?? ''}, ${patientAddress['state'] ?? ''}, ${patientAddress['pincode'] ?? ''}',
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
                      _buildDetailRow('Service Charge',
                          '₹${serviceCharge.value.toStringAsFixed(2)}'),
                      _buildDetailRow(
                          'Discount', '-₹${discount.value.toStringAsFixed(2)}'),
                      _buildDetailRow('Payment Mode', 'Online'),
                      _buildDetailRow('Transaction ID',
                          bookingData!['payment_id']?.toString() ?? 'N/A'),
                      _buildDetailRow(
                        'Total Payable',
                        '₹${totalPayable.value.toStringAsFixed(2)}',
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
                  color: bookingData['booking_status'] == 'PENDING'
                      ? Colors.orange.shade50
                      : bookingData['booking_status'] == 'PAID' ||
                              bookingData['booking_status'] == 'COMPLETED'
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
                                'Status: ${bookingData['booking_status'] ?? 'PENDING'}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      bookingData['booking_status'] == 'PENDING'
                                          ? Colors.orange
                                          : bookingData['booking_status'] ==
                                                  'COMPLETED'
                                              ? Colors.green
                                              : Colors.red,
                                ),
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

      // Update Status Button (Only if not completed/cancelled)
      persistentFooterButtons: [
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
                        smartDownloadInvoice(context, bookingData!),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (bookingData['booking_status'] != 'CANCELLED' &&
                bookingData['booking_status'] != 'COMPLETED')
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: PopupMenuButton<String>(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
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
                        child: Row(children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text("Mark as Confirmed")
                        ])),
                    PopupMenuItem(
                        value: "IN_PROGRESS",
                        child: Row(children: [
                          Icon(Icons.work_history, color: Colors.orange),
                          SizedBox(width: 8),
                          Text("Mark as In Progress")
                        ])),
                    PopupMenuItem(
                        value: "COMPLETED",
                        child: Row(children: [
                          Icon(Icons.task_alt, color: Colors.blue),
                          SizedBox(width: 8),
                          Text("Mark as Completed")
                        ])),
                    PopupMenuItem(
                        value: "CANCELLED",
                        child: Row(children: [
                          Icon(Icons.cancel, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Mark as Cancelled")
                        ])),
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
                        Text("Update Status",
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
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

  // ====================== HELPER WIDGETS ======================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppConstants.appPrimaryColor,
      title: const Text('Diagnostic Booking Details'),
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
            child: Text(
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

  // ====================== DIALOGS ======================
  void _showReportUploadDialog(
      BuildContext context, int bookingId, String status, String message) {
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
                GestureDetector(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                    );
                    if (result != null && result.files.isNotEmpty) {
                      final file = File(result.files.single.path!);
                      final name = result.files.single.name;
                      setState(() {
                        selectedFile = file;
                        fileName = name;
                      });
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
                            onPressed: () =>
                                setState(() => selectedFile = null),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                Row(
                  children: [
                    Expanded(
                        child: TextButton(
                            onPressed: () => Get.back(),
                            child: const Text('Cancel',
                                style: TextStyle(color: Colors.grey)))),
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
              final ctrl = Get.find<DiagnosticsProviderDashboardController>();
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
              final ctrl = Get.find<DiagnosticsProviderDashboardController>();
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

  Future<void> smartDownloadInvoice(
      BuildContext context, Map<String, dynamic> bookingData) async {
    final bookingId =
        bookingData['diagnostic_test_booking_id']?.toString() ?? '0';
    EasyLoading.show(status: 'Generating invoice...');

    try {
      final token = await readStr('token') ?? '';
      final profileId = await readStr('profileId') ?? '1';

      print(
          '${AppConstants.endpoint}/diagnostics/provider-dashboard/$profileId/invoices?search=$bookingId');

      // Build API URL
      final uri = Uri.parse(
        '${AppConstants.endpoint}/diagnostics/provider-dashboard/$profileId/invoices?search=1',
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

      await generatePerfectInvoicePDF(context, invoiceData, 'diagnostic');
    } catch (e) {
      EasyLoading.showError("Failed to generate invoice");
    } finally {
      EasyLoading.dismiss();
    }
  }
}
