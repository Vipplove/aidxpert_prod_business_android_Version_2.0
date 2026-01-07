// screens/caretaker/caretaker_booking_details.dart
// ignore_for_file: empty_catches, deprecated_member_use
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';

class CareTakerBookingDetails extends StatefulWidget {
  const CareTakerBookingDetails({Key? key}) : super(key: key);

  @override
  State<CareTakerBookingDetails> createState() =>
      _CareTakerBookingDetailsState();
}

class _CareTakerBookingDetailsState extends State<CareTakerBookingDetails> {
  late Map<String, dynamic> bookingData;
  bool isUpdating = false;
  String selectedStatus = 'Pending';

  final List<String> statusList = [
    "Pending",
    "Booked",
    "On Duty",
    "Completed",
    "Canceled",
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final dynamic args = Get.arguments;
    if (args is Map<String, dynamic>) {
      bookingData = args;
    } else if (args is List &&
        args.isNotEmpty &&
        args[0] is Map<String, dynamic>) {
      bookingData = args[0];
    } else {
      bookingData = {};
    }

    String apiStatus = (bookingData['caretaker_booking_status'] ?? 'Pending')
        .toString()
        .trim();
    selectedStatus = statusList.firstWhere(
      (s) => s.toLowerCase() == apiStatus.toLowerCase(),
      orElse: () => 'Pending',
    );
  }

  Widget _buildCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppConstants.appPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? const Color(0xFF1E88E5) : Colors.black87,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
      case 'COMPLETED':
      case 'BOOKED':
      case 'ON DUTY':
        return Colors.green.shade50;
      case 'IN PROGRESS':
      case 'PENDING':
        return Colors.orange.shade50;
      case 'CANCELLED':
      case 'CANCELED':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
      case 'COMPLETED':
      case 'BOOKED':
      case 'ON DUTY':
        return Colors.green.shade800;
      case 'IN PROGRESS':
      case 'PENDING':
        return Colors.orange.shade800;
      case 'CANCELLED':
      case 'CANCELED':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  void _openPhotoGallery(
      BuildContext context, List<String> images, int initialIndex) {
    Get.to(() => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            leading: IconButton(
                icon: const Icon(Icons.close), onPressed: () => Get.back()),
          ),
          body: PhotoViewGallery.builder(
            itemCount: images.length,
            builder: (context, index) => PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(images[index]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
            pageController: PageController(initialPage: initialIndex),
            loadingBuilder: (_, __) => const Center(
                child: CircularProgressIndicator(color: Colors.white)),
          ),
        ));
  }

  Future<void> _updateBookingStatus(String newStatus) async {
    if (isUpdating) return;
    setState(() => isUpdating = true);
    try {
      final token = await readStr('token');
      final profileId = await readStr('profileId');
      final int bookingId = bookingData['booking_id'] ?? 0;

      final response = await http.patch(
        Uri.parse(
            '${AppConstants.endpoint}/caretakers/provider-dashboard/$profileId/booking-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "booking_id": bookingId,
          "caretaker_booking_status": newStatus,
        }),
      );

      final res = json.decode(response.body);
      if (response.statusCode == 200 && res['status'] == true) {
        setState(() {
          selectedStatus = newStatus;
          bookingData['caretaker_booking_status'] = newStatus;
        });
        customToast('Status updated to $newStatus', Colors.green);
      } else {
        throw Exception(res['message'] ?? 'Update failed');
      }
    } catch (e) {
      customToast('Failed to update status: $e', Colors.red);
    } finally {
      if (mounted) setState(() => isUpdating = false);
    }
  }

  Future<void> _callPatient(String phone) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      customToast('Could not launch phone dialer', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (bookingData.isEmpty || bookingData['booking_id'] == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppConstants.appPrimaryColor,
          title: const Text('Booking Details'),
          centerTitle: true,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('No booking data available')),
      );
    }

    final int bookingId = bookingData['booking_id'] ?? 0;
    final String dateFrom = bookingData['booking_date_from'] ?? 'N/A';
    final String dateTo = bookingData['booking_date_to'] ?? 'N/A';
    final String timeDuration = bookingData['time_duration'] ?? 'Full Day';
    final String bookingType = bookingData['booking_type'] ?? 'N/A';
    final String slots = bookingData['slots'] ?? 'N/A';
    final double finalCharges =
        (bookingData['final_charges'] ?? bookingData['booking_fee'] ?? 0)
            .toDouble();
    final String currentStatus =
        (bookingData['caretaker_booking_status'] ?? 'Pending').toString();
    final String remark = bookingData['remark'] ?? '';

    String formattedFrom = 'N/A', formattedTo = 'N/A';
    try {
      if (dateFrom != 'N/A') {
        formattedFrom =
            DateFormat('dd MMM yyyy').format(DateTime.parse(dateFrom));
      }
      if (dateTo != 'N/A') {
        formattedTo = DateFormat('dd MMM yyyy').format(DateTime.parse(dateTo));
      }
    } catch (e) {}

    final Map<String, dynamic> caretakerDetails =
        bookingData['caretaker_details'] ?? {};
    final Map<String, dynamic> caretakerUser = caretakerDetails['user'] ?? {};

    print('Caretaker Details: $caretakerUser');

    final String caretakerName =
        "${caretakerUser['first_name'] ?? ''} ${caretakerUser['last_name'] ?? ''}"
                .trim()
                .isNotEmpty
            ? "${caretakerUser['first_name'] ?? ''} ${caretakerUser['last_name'] ?? ''}"
                .trim()
            : "Caretaker #${caretakerDetails['caretaker_id'] ?? '??'}";

    final String caretakerPhone =
        caretakerUser['phone_number']?.toString() ?? 'N/A';
    final String caretakerAddress =
        caretakerUser['address']?.toString() ?? 'N/A';

    final String caretakerDesc =
        caretakerDetails['description']?.toString().split('.').first ??
            'Experienced Caretaker';
    final String location = caretakerDetails['location'] ?? 'N/A';
    final List<String> caretakerTypes =
        List<String>.from(caretakerDetails['caretaker_type'] ?? []);
    final double rating = (caretakerDetails['rating'] ?? 0).toDouble();

    // Patient Profile
    String patientName = "Patient #${bookingData['patient_id'] ?? '??'}";
    String patientPhone = "N/A";
    String patientEmail = "N/A";
    String patientAddress = "N/A";
    final patientDetails =
        bookingData['patient_details']?['user'] as Map<String, dynamic>?;
    if (patientDetails != null) {
      final first = patientDetails['first_name']?.toString() ?? '';
      final last = patientDetails['last_name']?.toString() ?? '';
      final full = '$first $last'.trim();
      if (full.isNotEmpty) patientName = full;
      patientPhone = patientDetails['phone_number']?.toString() ?? 'N/A';
      patientEmail = patientDetails['email']?.toString() ?? 'N/A';
      patientAddress = patientDetails['address']?.toString() ?? 'N/A';
    }
    String avatarLetter =
        patientName.isNotEmpty ? patientName[0].toUpperCase() : "?";

    final bool showActionButtons =
        !['Completed', 'Cancelled', 'Canceled'].contains(currentStatus);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppConstants.appPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Caretaker Booking Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Patient Profile
            _buildCard(
              title: "Patient Profile",
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor:
                          AppConstants.appPrimaryColor.withOpacity(0.2),
                      child: Text(avatarLetter,
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.appPrimaryColor)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patientName,
                              style: const TextStyle(
                                  fontSize: 19, fontWeight: FontWeight.bold)),
                          Text(
                              "#PT${(bookingData['patient_id'] ?? '??').toString().padLeft(4, '0')}",
                              style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone,
                          color: Colors.green, size: 28),
                      onPressed: patientPhone != 'N/A'
                          ? () => _callPatient(patientPhone)
                          : null,
                      tooltip: "Call Patient",
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow("Phone", patientPhone),
                _buildDetailRow("Email", patientEmail),
                _buildDetailRow("Address", patientAddress),
              ],
            ),
            const SizedBox(height: 12),

            // Booking Summary
            _buildCard(
              title: "Booking Summary",
              children: [
                _buildDetailRow(
                    "Booking ID", "#CT${bookingId.toString().padLeft(5, '0')}"),
                _buildDetailRow(
                    "Service Period", "$formattedFrom → $formattedTo"),
                _buildDetailRow("Time Slot", timeDuration),
                _buildDetailRow("Booking Type", bookingType),
                _buildDetailRow("Shift", slots),
                if (remark.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text("Note: $remark",
                        style: TextStyle(
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Caretaker Assigned - WITH NEW FIELDS
            _buildCard(
              title: "Caretaker Assigned",
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor:
                          AppConstants.appPrimaryColor.withOpacity(0.15),
                      child: Text(
                        caretakerName.isNotEmpty
                            ? caretakerName[0].toUpperCase()
                            : "C",
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.appPrimaryColor),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(caretakerName,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(caretakerDesc,
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 14)),
                        ],
                      ),
                    ),
                    if (caretakerPhone != 'N/A')
                      IconButton(
                        icon: const Icon(Icons.phone,
                            color: Colors.green, size: 26),
                        onPressed: () => _callPatient(caretakerPhone),
                        tooltip: "Call Caretaker",
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow("Mobile", caretakerPhone),
                _buildDetailRow("Address", caretakerAddress),
                Row(children: [
                  Icon(Icons.location_on, size: 18, color: Colors.grey[700]),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(location,
                          style: TextStyle(color: Colors.grey[700]))),
                ]),
                if (caretakerTypes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text("Specializes In",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: caretakerTypes
                        .map((t) => Chip(
                            label: Text(t),
                            backgroundColor: Colors.blue.shade50))
                        .toList(),
                  ),
                ],
                if (rating > 0) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 6),
                    Text(rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(" (${caretakerDetails['rating_count'] ?? 0} reviews)",
                        style: TextStyle(color: Colors.grey[600])),
                  ]),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Payment Summary
            _buildCard(
              title: "Payment Summary",
              children: [
                _buildDetailRow("Final Amount", "₹$finalCharges", isBold: true),
                _buildDetailRow(
                    "Service Charge", "₹${bookingData['service_charge'] ?? 0}"),
                _buildDetailRow("Discount", "₹${bookingData['discount'] ?? 0}"),
              ],
            ),
            const SizedBox(height: 12),

            // Status Card
            Card(
              color: _getStatusColor(currentStatus),
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Center(
                  child: Text("Current Status: ${currentStatus.toUpperCase()}",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getStatusTextColor(currentStatus))),
                ),
              ),
            ),
          ],
        ),
      ),

      // Status Update Footer
      persistentFooterButtons: showActionButtons
          ? [
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Text("Update Status",
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      isUpdating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedStatus,
                                icon: const Icon(Icons.keyboard_arrow_down),
                                items: statusList
                                    .map((s) => DropdownMenuItem(
                                        value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null &&
                                      value != selectedStatus) {
                                    _updateBookingStatus(value);
                                  }
                                },
                              ),
                            ),
                    ],
                  ),
                ),
              )
            ]
          : null,
    );
  }
}
