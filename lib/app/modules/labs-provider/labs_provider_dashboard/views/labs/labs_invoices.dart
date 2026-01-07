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
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import '../../../../../../constants/app_constants.dart';
import '../../../../../../utils/helper.dart';
import '../../../../../../utils/pdf_invoice_generate.dart';

class LabsInvoices extends StatefulWidget {
  const LabsInvoices({super.key});

  @override
  State<LabsInvoices> createState() => _LabsInvoicesState();
}

class _LabsInvoicesState extends State<LabsInvoices> {
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
    _debounce = Timer(const Duration(milliseconds: 300), () {
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
        '${AppConstants.endpoint}/labs/provider-dashboard/1/invoices',
      ).replace(queryParameters: query.isEmpty ? {} : {'search': query});

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          invoices.value = data['invoices'] ?? [];
        } else {
          errorMessage.value = 'No invoices found';
        }
      } else {
        errorMessage.value = 'Failed to load invoices';
      }
    } catch (e) {
      errorMessage.value = 'Network error. Please try again.';
    } finally {
      isLoading.value = false;
      _refreshController.refreshCompleted();
    }
  }

  Future<void> _downloadAndShareInvoice(
      Map<String, dynamic> invoiceData) async {
    await generatePerfectInvoicePDF(context, invoiceData, 'labs');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: _buildAppBar(),
      body: SmartRefresher(
        controller: _refreshController,
        header: const WaterDropHeader(),
        onRefresh: () async {
          _searchController.clear();
          await _loadInvoices();
        },
        child: Column(
          children: [
            _buildSearchBar(),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No invoices found',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppConstants.appPrimaryColor,
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
      centerTitle: true,
      title: const Text('Lab Invoices',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by ID, Name, Phone...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final booking = invoice['lab_test_booking'];
    final patient = booking['patient_details']?['user'] ?? {};
    final payment = booking['payment_details'] ?? {};
    final tests = List.from(booking['lab_test_details'] ?? []);

    final name =
        '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}'.trim();
    final phone = patient['phone_number'] ?? '-';
    final bookingId = booking['booking_reference_no'] ?? '-';
    final invoiceId = 'INV${invoice['invoice_id']}'.padLeft(6, '0');
    final issuedDate = DateFormat('dd MMM yyyy')
        .format(DateTime.parse(invoice['issued_date']).toLocal());
    final totalAmount = payment['totalAmount'] ?? '0.00';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: patient['profile_image_name'] != null
                      ? NetworkImage(patient['profile_image_name'])
                      : null,
                  child: patient['profile_image_name'] == null
                      ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'P',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.isEmpty ? 'Unknown Patient' : name,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600)),
                      Text(phone,
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('Paid',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800])),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(
                        text: 'Invoice ID: ',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13)),
                    TextSpan(
                        text: invoiceId,
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ]),
                ),
                Text('₹$totalAmount',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Booking: $bookingId • Issued: $issuedDate',
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(invoice['description'] ?? 'Lab Test Invoice',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tests.take(3).map((t) {
                return Chip(
                  label: Text(t['test_name'] ?? 'Test',
                      style: const TextStyle(fontSize: 11)),
                  backgroundColor:
                      AppConstants.appPrimaryColor.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
            if (tests.length > 3)
              Text('+${tests.length - 3} more',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 16),

            // SINGLE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _downloadAndShareInvoice(invoice),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Download & Share',
                    style: TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
