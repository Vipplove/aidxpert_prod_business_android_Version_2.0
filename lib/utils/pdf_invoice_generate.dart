// lib/utils/generate_invoice_pdf.dart
// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:share_plus/share_plus.dart';
import 'helper.dart';

Future<void> generatePerfectInvoicePDF(
    BuildContext context, Map<String, dynamic> invoiceData, String type) async {
  try {
    EasyLoading.show(status: 'Generating invoice...');

    final pdf = pw.Document();

    // Load NotoSans Fonts (Supports ₹, Hindi, English perfectly)
    final regularTtf =
        await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
    final boldTtf = await rootBundle.load("assets/fonts/NotoSans-Bold.ttf");

    final pw.Font regular = pw.Font.ttf(regularTtf);
    final pw.Font bold = pw.Font.ttf(boldTtf);

    // This is the key: Use NotoSans as fallback for every text
    final rupeeStyle = pw.TextStyle(font: regular, fontFallback: [regular]);
    final rupeeStyleBold = pw.TextStyle(font: bold, fontFallback: [bold]);

    // Extract data
    Map<String, dynamic> booking;
    List<dynamic> tests = [];
    String invoiceId = '';
    String refNo = '';
    String bookingDate = '';
    Map<String, dynamic> patient = {};
    Map<String, dynamic> payment = {};
    Map<String, dynamic> centerDetails = {};

    if (type == "diagnostic") {
      booking = invoiceData['diagnostic_test_booking'];
      invoiceId = 'INVDIA${booking['diagnostic_test_booking_id'] ?? ''}';
      tests = booking['diagnostic_test_detail'] ?? [];
      centerDetails = booking['diagnostic_center_details'] ?? {};
    } else {
      booking = invoiceData['lab_test_booking'];
      invoiceId = 'INVLAB${booking['lab_test_booking_id'] ?? ''}';
      tests = booking['lab_test_details'] ?? [];
      centerDetails = booking['lab_details'] ?? {};
    }

    patient = booking['patient_details']?['user'] ?? {};
    payment = booking['payment_details'] ?? {};

    final patientName =
        '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}'.trim();
    final patientPhone = patient['phone_number'] ?? 'N/A';
    refNo = booking['booking_reference_no'] ?? 'N/A';
    bookingDate = booking['booking_date'] != null
        ? DateFormat('dd MMM yyyy')
            .format(DateTime.parse(booking['booking_date']))
        : DateFormat('dd MMM yyyy').format(DateTime.now());

    final double subtotal =
        double.tryParse(payment['amount']?.toString() ?? '0') ?? 0;
    final double serviceCharge =
        double.tryParse(payment['serviceCharge']?.toString() ?? '0') ?? 0;
    final double discount =
        double.tryParse(payment['discount']?.toString() ?? '0') ?? 0;
    final double totalAmount =
        double.tryParse(payment['totalAmount']?.toString() ?? '0') ?? 0;

    // Load Logo
    pw.Widget logoWidget;
    try {
      final resp =
          await http.get(Uri.parse('https://aidxpert.com/assets/img/logo.png'));
      if (resp.statusCode == 200) {
        logoWidget =
            pw.Image(pw.MemoryImage(resp.bodyBytes), width: 90, height: 90);
      } else {
        throw Exception();
      }
    } catch (_) {
      logoWidget = pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: const pw.BoxDecoration(color: PdfColors.blue900),
        child: pw.Text('AIDXPERT',
            style:
                pw.TextStyle(font: bold, fontSize: 26, color: PdfColors.white)),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                logoWidget,
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('TAX INVOICE',
                        style: rupeeStyleBold.copyWith(
                            fontSize: 28, color: PdfColors.blue900)),
                    pw.SizedBox(height: 8),
                    pw.Text('Invoice No: $invoiceId',
                        style: rupeeStyleBold.copyWith(fontSize: 16)),
                    pw.Text('Date: $bookingDate',
                        style: rupeeStyle.copyWith(fontSize: 14)),
                    pw.Text('Ref: $refNo',
                        style: rupeeStyle.copyWith(fontSize: 14)),
                  ],
                ),
              ],
            ),

            pw.Divider(thickness: 2, height: 40),

            // Bill To + Center Info
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Bill To:',
                        style: rupeeStyleBold.copyWith(fontSize: 16)),
                    pw.SizedBox(height: 6),
                    pw.Text(patientName,
                        style: rupeeStyleBold.copyWith(fontSize: 18)),
                    pw.Text(patientPhone, style: rupeeStyle),
                    if (booking['patient_address'] != null) ...[
                      pw.Text(
                        '${booking['patient_address']['flat_no'] ?? ''}, ${booking['patient_address']['street'] ?? ''}',
                        style: rupeeStyle,
                      ),
                      pw.Text(
                        '${booking['patient_address']['city'] ?? ''}, ${booking['patient_address']['state'] ?? ''} - ${booking['patient_address']['pincode'] ?? ''}',
                        style: rupeeStyle,
                      ),
                    ],
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                        type == "diagnostic"
                            ? 'Diagnostic Center'
                            : 'Laboratory',
                        style: rupeeStyleBold.copyWith(fontSize: 16)),
                    pw.SizedBox(height: 6),
                    pw.Text(
                        centerDetails['center_name'] ??
                            centerDetails['lab_name'] ??
                            'N/A',
                        style: rupeeStyleBold.copyWith(fontSize: 16)),
                    pw.Text(centerDetails['area'] ?? '', style: rupeeStyle),
                    pw.Text(
                        '${centerDetails['city'] ?? ''}, ${centerDetails['state'] ?? ''}',
                        style: rupeeStyle),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            // Tests Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('Test Name', isHeader: true, style: rupeeStyleBold),
                    _cell('Type', isHeader: true, style: rupeeStyleBold),
                    _cell('Amount',
                        isHeader: true,
                        style: rupeeStyleBold,
                        align: pw.Alignment.centerRight),
                  ],
                ),
                ...tests.map((test) => pw.TableRow(
                      children: [
                        _cell(test['test_name'] ?? 'Unknown Test',
                            style: rupeeStyle),
                        _cell(test['test_type'] ?? 'Standard',
                            style: rupeeStyle),
                        _cell('₹${test['new_test_charges'] ?? 0}',
                            style: rupeeStyle, align: pw.Alignment.centerRight),
                      ],
                    )),
              ],
            ),

            pw.SizedBox(height: 30),

            // Summary
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.SizedBox(
                  width: 280,
                  child: pw.Column(
                    children: [
                      _summaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}',
                          rupeeStyle, rupeeStyleBold),
                      _summaryRow(
                          'Service Charge',
                          '₹${serviceCharge.toStringAsFixed(2)}',
                          rupeeStyle,
                          rupeeStyleBold),
                      if (discount > 0)
                        _summaryRow(
                            'Discount',
                            '-₹${discount.toStringAsFixed(2)}',
                            rupeeStyle,
                            rupeeStyleBold),
                      pw.Divider(thickness: 2),
                      _summaryRow(
                          'Total Amount',
                          '₹${totalAmount.toStringAsFixed(2)}',
                          rupeeStyle,
                          rupeeStyleBold,
                          isTotal: true),
                    ],
                  ),
                ),
              ],
            ),

            pw.Spacer(),

            // Footer
            pw.Divider(),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('Thank You for Choosing AidXpert!',
                      style: rupeeStyleBold.copyWith(
                          fontSize: 18, color: PdfColors.blue900)),
                  pw.SizedBox(height: 8),
                  pw.Text('Support: support@aidxpert.com | +91-8585056006',
                      style: rupeeStyle.copyWith(fontSize: 12)),
                  pw.SizedBox(height: 4),
                  pw.Text('www.aidxpert.com',
                      style: rupeeStyleBold.copyWith(
                          fontSize: 12, color: PdfColors.blue900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Save & Share
    final bytes = await pdf.save();
    final dir = Platform.isAndroid
        ? Directory('/storage/emulated/0/Download')
        : await getApplicationDocumentsDirectory();

    final downloadDir = Platform.isAndroid && !await dir.exists()
        ? await getExternalStorageDirectory() ?? dir
        : dir;

    final file = File('${downloadDir.path}/$invoiceId.pdf');
    await file.writeAsBytes(bytes);

    EasyLoading.dismiss();
    customToast('Invoice saved successfully!', Colors.green);

    await Share.shareXFiles(
      [XFile(file.path)],
      text:
          'AidXpert Invoice\nPatient: $patientName\nInvoice: $invoiceId\nTotal: ₹${totalAmount.toStringAsFixed(2)}',
      subject: 'Invoice $invoiceId',
    );
  } catch (e) {
    EasyLoading.dismiss();
    customToast('Failed to generate invoice', Colors.red);
    print('PDF Error: $e');
  }
}

// Helper: Table Cell with Rupee Support
pw.Widget _cell(String text,
    {bool isHeader = false,
    required pw.TextStyle style,
    pw.Alignment align = pw.Alignment.centerLeft}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(10),
    child: pw.Text(
      text,
      style: style.copyWith(
        fontSize: isHeader ? 13 : 12,
        fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
      textAlign: align == pw.Alignment.centerRight
          ? pw.TextAlign.right
          : align == pw.Alignment.center
              ? pw.TextAlign.center
              : pw.TextAlign.left,
    ),
  );
}

// Helper: Summary Row
pw.Widget _summaryRow(
    String label, String value, pw.TextStyle regular, pw.TextStyle bold,
    {bool isTotal = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: (isTotal ? bold : regular)
                .copyWith(fontSize: isTotal ? 18 : 14)),
        pw.Text(value,
            style: bold.copyWith(
                fontSize: isTotal ? 20 : 15,
                color: isTotal ? PdfColors.blue900 : PdfColors.black)),
      ],
    ),
  );
}
