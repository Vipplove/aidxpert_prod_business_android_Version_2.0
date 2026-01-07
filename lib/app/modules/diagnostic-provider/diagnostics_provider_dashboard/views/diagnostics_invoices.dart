// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:http/http.dart' as http;
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';
import '../../../../../utils/pdf_invoice_generate.dart';

class DiagnosticsInvoices extends StatefulWidget {
  const DiagnosticsInvoices({super.key});

  @override
  State<DiagnosticsInvoices> createState() => _DiagnosticsInvoicesState();
}

class _DiagnosticsInvoicesState extends State<DiagnosticsInvoices> {
  final RefreshController _refreshController = RefreshController();
  final TextEditingController _searchController = TextEditingController();
  final RxList<dynamic> invoices = <dynamic>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
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
      _loadInvoices();
    });
  }

  Future<void> _loadInvoices() async {
    isLoading.value = true;
    errorMessage.value = '';
    final token = await readStr('token') ?? '';
    final profileId = await readStr('profileId') ?? '1';

    try {
      final query = _searchController.text.trim();
      final uri = Uri.parse(
        '${AppConstants.endpoint}/diagnostics/provider-dashboard/$profileId/invoices',
      ).replace(queryParameters: query.isEmpty ? {} : {'search': query});

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          invoices.value = List.from(data['invoices'] ?? []);
        } else {
          errorMessage.value = data['message'] ?? 'No invoices found';
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

  Future<void> _downloadAndShareInvoice(
      Map<String, dynamic> invoiceData) async {
    await generatePerfectInvoicePDF(context, invoiceData, 'diagnostic');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: AppConstants.appPrimaryColor,
        foregroundColor: Colors.white,
        title: const Text("Diagnostic Invoices",
            style: TextStyle(fontWeight: FontWeight.bold)),
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
          await _loadInvoices();
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
                            _loadInvoices();
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
                if (isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (errorMessage.value.isNotEmpty) {
                  return Center(
                      child: Text(errorMessage.value,
                          style: const TextStyle(color: Colors.red)));
                }
                if (invoices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text("No invoices found",
                            style: TextStyle(fontSize: 18, color: Colors.grey)),
                        const Text("Pull down to refresh",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: invoices.length,
                  itemBuilder: (ctx, i) => _buildInvoiceCard(invoices[i]),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final booking = invoice['diagnostic_test_booking'] ?? {};
    final patientInfo = booking['patient_info'] ?? {};
    final patientDetails = booking['patient_details']?['user'] ?? {};
    final tests = List.from(booking['diagnostic_test_detail'] ?? []);

    final name = patientInfo['name']?.toString().trim().isNotEmpty == true
        ? patientInfo['name'].toString().trim()
        : '${patientDetails['first_name'] ?? ''} ${patientDetails['last_name'] ?? ''}'
            .trim();

    final phone = patientDetails['phone_number']?.toString() ?? '-';
    final bookingRef = booking['booking_reference_no']?.toString() ?? '-';
    final invoiceId = 'INV${invoice['invoice_id']}'.padLeft(6, '0');
    final date = DateFormat('dd MMM yyyy')
        .format(DateTime.parse(invoice['issued_date']).toLocal());
    final amount = (booking['final_charges'] ?? 0).toString();

    // Generate unique color based on name
    final avatarColor =
        Colors.primaries[name.hashCode.abs() % Colors.primaries.length];
    final initial = name.isNotEmpty ? name[0].toUpperCase() : "P";

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
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.isEmpty ? "Patient" : name,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(phone,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text("₹$amount",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                    Text("Paid",
                        style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text("Invoice: $invoiceId • $date",
                style: TextStyle(color: Colors.grey[700], fontSize: 14)),
            Text("Booking: $bookingRef",
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: tests
                  .take(3)
                  .map((t) => Chip(
                        label: Text(t['test_name']?.toString() ?? 'Test',
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
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadAndShareInvoice(invoice),
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
                    onPressed: () => _downloadAndShareInvoice(invoice),
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
