// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';

class DiagnosticsReports extends StatefulWidget {
  const DiagnosticsReports({super.key});

  @override
  State<DiagnosticsReports> createState() => _DiagnosticsReportsState();
}

class _DiagnosticsReportsState extends State<DiagnosticsReports> {
  final RefreshController _refreshController = RefreshController();
  final TextEditingController _searchController = TextEditingController();
  final RxList<dynamic> reports = <dynamic>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadReports();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadReports();
    });
  }

  Future<void> _loadReports() async {
    isLoading.value = true;
    errorMessage.value = '';
    final token = await readStr('token') ?? '';
    final profileId = await readStr('profileId') ?? '1';

    try {
      final query = _searchController.text.trim();
      final uri = Uri.parse(
        '${AppConstants.endpoint}/diagnostics/provider-dashboard/$profileId/test-reports',
      ).replace(queryParameters: query.isEmpty ? {} : {'search': query});

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          reports.value = List.from(data['diagnosticReports'] ?? []);
        } else {
          errorMessage.value = data['message'] ?? 'No reports found';
        }
      } else {
        errorMessage.value = 'Server error. Please try again.';
      }
    } catch (e) {
      errorMessage.value = 'Network error. Check connection.';
    } finally {
      isLoading.value = false;
      _refreshController.refreshCompleted();
    }
  }

  Future<File?> _downloadReportFile(String url, String fileName) async {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 40));
      if (response.statusCode == 200) {
        Directory? directory;
        if (Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        final safeFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
        final file = File('${directory!.path}/$safeFileName.pdf');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      print("Download error: $e");
    }
    return null;
  }

  Future<void> _downloadAndShareReport(Map<String, dynamic> report) async {
    final booking = report['diagnostic_test_booking'] ?? {};
    final patientInfo = booking['patient_info'] ?? {};
    final patientDetails = booking['patient_details']?['user'] ?? {};
    final reportUrl = report['report_file_path']?.toString() ?? '';
    final reportTitle =
        (report['report_title'] ?? 'Diagnostic Report').toString();
    final bookingId = booking['booking_reference_no']?.toString() ?? 'Unknown';

    final patientName = patientInfo['name']?.toString().trim().isNotEmpty ==
            true
        ? patientInfo['name'].toString().trim()
        : '${patientDetails['first_name'] ?? ''} ${patientDetails['last_name'] ?? ''}'
            .trim();

    if (reportUrl.isEmpty) {
      customToast('Report not available', Colors.red);
      return;
    }

    customToast('Downloading report...', Colors.orange);

    final fileName = '$bookingId - $reportTitle';
    final file = await _downloadReportFile(reportUrl, fileName);

    if (file != null && await file.exists()) {
      customToast('Report ready!', Colors.green);
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Diagnostic Report\nPatient: $patientName\nBooking: $bookingId\nTitle: $reportTitle',
        subject: 'Diagnostic Report - $bookingId',
      );
    } else {
      customToast('Failed to download report', Colors.red);
    }
  }

  Future<void> _shareViaWhatsApp(Map<String, dynamic> report) async {
    final booking = report['diagnostic_test_booking'] ?? {};
    final patientInfo = booking['patient_info'] ?? {};
    final patientDetails = booking['patient_details']?['user'] ?? {};
    final reportUrl = report['report_file_path']?.toString() ?? '';
    final reportTitle =
        (report['report_title'] ?? 'Diagnostic Report').toString();
    final bookingId = booking['booking_reference_no']?.toString() ?? 'Unknown';

    final patientName = patientInfo['name']?.toString().trim().isNotEmpty ==
            true
        ? patientInfo['name'].toString().trim()
        : '${patientDetails['first_name'] ?? ''} ${patientDetails['last_name'] ?? ''}'
            .trim();

    if (reportUrl.isEmpty) {
      customToast('Report not available', Colors.red);
      return;
    }

    customToast('Preparing for WhatsApp...', Colors.green);

    final fileName = '$bookingId - $reportTitle';
    final file = await _downloadReportFile(reportUrl, fileName);

    if (file != null && await file.exists()) {
      final text = Uri.encodeComponent(
          "Diagnostic Report Ready!\n\nPatient: $patientName\nBooking ID: $bookingId\nReport: $reportTitle\n\nPlease find the report attached.");

      final uri = Uri.parse("whatsapp://send?text=$text");
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        await Future.delayed(const Duration(seconds: 2));
        await Share.shareXFiles([XFile(file.path)]);
      } else {
        customToast("WhatsApp not installed", Colors.orange);
        await Share.shareXFiles([XFile(file.path)],
            text: "Diagnostic Report - $patientName");
      }
    } else {
      customToast('Failed to download report', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: AppConstants.appPrimaryColor,
        foregroundColor: Colors.white,
        title: const Text("Diagnostic Reports",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50)),
        ),
      ),
      body: SmartRefresher(
        controller: _refreshController,
        header: WaterDropHeader(waterDropColor: AppConstants.appPrimaryColor),
        onRefresh: () async {
          _searchController.clear();
          await _loadReports();
        },
        child: Column(
          children: [
            // Search Bar
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10)
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search by Name, Phone, Booking ID...",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _loadReports();
                          })
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),

            // List
            Expanded(
              child: Obx(() {
                if (isLoading.value)
                  return const Center(child: CircularProgressIndicator());
                if (errorMessage.value.isNotEmpty) {
                  return Center(
                      child: Text(errorMessage.value,
                          style: const TextStyle(color: Colors.red)));
                }
                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text("No reports found",
                            style: TextStyle(fontSize: 18, color: Colors.grey)),
                        const Text("Pull down to refresh",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: reports.length,
                  itemBuilder: (ctx, i) => _buildReportCard(reports[i]),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final booking = report['diagnostic_test_booking'] ?? {};
    final patientInfo = booking['patient_info'] ?? {};
    final patientDetails = booking['patient_details']?['user'] ?? {};
    final tests = List.from(booking['diagnostic_test_detail'] ?? []);

    final patientName = patientInfo['name']?.toString().trim().isNotEmpty ==
            true
        ? patientInfo['name'].toString().trim()
        : '${patientDetails['first_name'] ?? ''} ${patientDetails['last_name'] ?? ''}'
            .trim();

    final phone = patientDetails['phone_number']?.toString() ?? '-';
    final bookingId = booking['booking_reference_no']?.toString() ?? '-';
    final reportTitle =
        report['report_title']?.toString() ?? 'Diagnostic Report';
    final reportedAt = DateFormat('dd MMM yyyy, hh:mm a')
        .format(DateTime.parse(report['reported_at']).toLocal());

    // Default avatar color based on name
    final avatarColor =
        Colors.primaries[patientName.hashCode.abs() % Colors.primaries.length];
    final initial = patientName.isNotEmpty ? patientName[0].toUpperCase() : "P";

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Beautiful Default Avatar
                CircleAvatar(
                  radius: 26,
                  backgroundColor: avatarColor,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName.isEmpty ? "Unknown Patient" : patientName,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text("Booking ID: $bookingId",
                style: TextStyle(color: Colors.grey[700], fontSize: 14)),
            const SizedBox(height: 4),
            Text("Reported on: $reportedAt",
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 10),
            Text(
              reportTitle,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue),
            ),
            const SizedBox(height: 12),

            // Test Chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: tests
                  .take(3)
                  .map((t) => Chip(
                        label: Text(t['test_name'] ?? 'Test',
                            style: const TextStyle(fontSize: 11)),
                        backgroundColor:
                            AppConstants.appPrimaryColor.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ))
                  .toList(),
            ),
            if (tests.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text("+${tests.length - 3} more tests",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ),

            const SizedBox(height: 18),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareViaWhatsApp(report),
                    icon:
                        const Icon(Icons.wechat, color: Colors.white, size: 26),
                    label: const Text("WhatsApp",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _downloadAndShareReport(report),
                    icon:
                        const Icon(Icons.share_outlined, color: Colors.orange),
                    label: const Text("Share",
                        style: TextStyle(
                            color: Colors.orange, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
