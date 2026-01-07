// screens/ambulance/ambulance_booking_details.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:http/http.dart' as http;
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';
import '../../../../routes/app_pages.dart';
import '../controllers/ambulance_controller.dart';

class AmbulanceBookingDetails extends StatefulWidget {
  const AmbulanceBookingDetails({Key? key}) : super(key: key);

  @override
  State<AmbulanceBookingDetails> createState() =>
      _AmbulanceBookingDetailsState();
}

class _AmbulanceBookingDetailsState extends State<AmbulanceBookingDetails> {
  late Map<String, dynamic> bookingData;
  bool isUpdating = false;
  String selectedStatus = 'pending';

  final List<String> statusList = [
    "pending",
    "confirmed",
    "inprocess",
    "completed",
    "failed",
    "cancelled"
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

    selectedStatus =
        (bookingData['booking_status'] ?? 'pending').toString().toLowerCase();
  }

  Widget _buildCard({
    required String title,
    required List<Widget> children,
    Map<String, dynamic>? data,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppConstants.appPrimaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (title == 'Trip Route')
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.toNamed(Routes.AMBULANCE_TRACK,
                          arguments: bookingData);
                    },
                    icon: const Icon(Icons.location_on_outlined, size: 18),
                    label: const Text(
                      'Tracking',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.appPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                    ),
                  ),
              ],
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
      case 'COMPLETED':
      case 'CONFIRMED':
        return Colors.green.shade50;
      case 'INPROCESS':
      case 'PENDING':
        return Colors.orange.shade50;
      case 'CANCELLED':
      case 'FAILED':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'CONFIRMED':
        return Colors.green.shade800;
      case 'INPROCESS':
      case 'PENDING':
        return Colors.orange.shade800;
      case 'CANCELLED':
      case 'FAILED':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  void _openPhotoGallery(
      BuildContext context, List<String> images, int initialIndex) {
    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Get.back(),
          ),
        ),
        body: PhotoViewGallery.builder(
          itemCount: images.length,
          builder: (context, index) {
            return PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(images[index]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              heroAttributes: PhotoViewHeroAttributes(tag: "photo$index"),
            );
          },
          scrollPhysics: const BouncingScrollPhysics(),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          pageController: PageController(initialPage: initialIndex),
          loadingBuilder: (context, event) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Future<void> updateBookingStatus(String status) async {
    if (isUpdating) return;

    setState(() => isUpdating = true);

    try {
      final token = await readStr('token');
      final int bookingId = bookingData['ambulance_booking_id'] ?? 0;

      final response = await http.put(
        Uri.parse(
            '${AppConstants.endpoint}/ambulances/dashboard/booking-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "ambulance_booking_id": bookingId,
          "booking_status": status,
        }),
      );

      final res = jsonDecode(response.body);

      if (res['success']) {
        setState(() {
          selectedStatus = status;
          bookingData['booking_status'] = status;
        });
        customToast('Status updated successfully', Colors.green);
        Get.put(AmbulanceController()).fetchBookingHistory();
      } else {
        throw Exception(res['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      customToast('Failed to update status ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() => isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (bookingData.isEmpty || bookingData['ambulance_booking_id'] == null) {
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

    // Extract data safely
    final int bookingId = bookingData['ambulance_booking_id'] ?? 0;
    final String bookingDateStr = bookingData['ambulance_booking_date'] ?? '';
    final String bookingTimeStr = bookingData['ambulance_booking_time'] ?? '';
    final String pickupLocation = bookingData['pickup_location'] ?? 'N/A';
    final String dropLocation = bookingData['drop_location'] ?? 'N/A';
    final String amountCharged =
        bookingData['amount_charged']?.toString() ?? '0.00';
    final String currentStatus =
        (bookingData['booking_status'] ?? 'pending').toString();
    final String actionByProvider =
        (bookingData['action_by_provider'] ?? 'pending')
            .toString()
            .toLowerCase();
    final bool isPaid = bookingData['payment_id'] != null;

    // Patient Name
    String patientName = "Patient #${bookingData['patient_id'] ?? 'Unknown'}";
    if (bookingData['ambulance_booking_for'] == "others" &&
        bookingData['others_person_details'] != null) {
      patientName = bookingData['others_person_details']['name'] ?? patientName;
    }

    // Ambulance Details
    final Map<String, dynamic> ambulanceDetails =
        bookingData['ambulance_details'] ?? {};

    final String ambulanceName = ambulanceDetails['ambulance_name'] ?? 'N/A';
    final String ambulanceType = ambulanceDetails['ambulance_type'] ?? 'N/A';
    final String vehicleNumber = ambulanceDetails['vehicle_number'] ?? 'N/A';
    final String description =
        ambulanceDetails['description'] ?? 'No description available';
    final String driverName = ambulanceDetails['driver_name'] ?? 'N/A';
    final String driverContact = ambulanceDetails['driver_contact'] ?? 'N/A';
    final String locationName = ambulanceDetails['location_name'] ?? 'N/A';
    final String availabilityStatus =
        ambulanceDetails['availability_status'] ?? 'UNKNOWN';

    // Transport Charges
    final Map<String, dynamic> charges =
        ambulanceDetails['transport_charges'] ?? {};
    final double baseFare = (charges['baseFare'] as num?)?.toDouble() ?? 0.0;
    final double perKm = (charges['perKm'] as num?)?.toDouble() ?? 0.0;
    final double waitingPerMin =
        (charges['waitingChargePerMin'] as num?)?.toDouble() ?? 0.0;

    // === FIXED: Photos handling (supports both JSON string and direct List) ===
    List<String> photoUrls = [];
    final dynamic photosData = ambulanceDetails['ambulance_photos'];

    if (photosData is String && photosData.isNotEmpty && photosData != 'null') {
      try {
        final decoded = json.decode(photosData);
        if (decoded is List) {
          photoUrls = decoded.whereType<String>().toList();
        }
      } catch (e) {
        debugPrint('Failed to parse ambulance_photos as JSON string: $e');
      }
    } else if (photosData is List) {
      photoUrls = photosData.whereType<String>().toList();
    }

    // === FIXED: Availability Slots handling (supports both JSON string and direct Map) ===
    String availabilitySlots = "24x7 Available";
    final dynamic slotsData = ambulanceDetails['availability_slots'];
    Map<String, dynamic> slotsMap = {};

    if (slotsData is String && slotsData.isNotEmpty && slotsData != 'null') {
      try {
        final decoded = json.decode(slotsData);
        if (decoded is Map) {
          slotsMap = Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        debugPrint('Failed to parse availability_slots as JSON string: $e');
      }
    } else if (slotsData is Map) {
      slotsMap = Map<String, dynamic>.from(slotsData);
    }

    if (slotsMap.isNotEmpty) {
      availabilitySlots = slotsMap.entries.map((e) {
        final days = e.key;
        final times = (e.value as List<dynamic>?)?.join(', ') ?? '';
        return "$days: $times";
      }).join('\n');
    }

    // Format Date & Time
    String formattedDate = 'N/A';
    String formattedTime = bookingTimeStr;
    try {
      if (bookingDateStr.isNotEmpty) {
        final date = DateTime.parse(bookingDateStr);
        formattedDate = DateFormat('dd MMM yyyy').format(date);
      }
      if (bookingTimeStr.isNotEmpty) {
        final parts = bookingTimeStr.split(':');
        if (parts.length >= 2) {
          int hour = int.parse(parts[0]);
          final minute = parts[1].padRight(2, '0').substring(0, 2);
          final period = hour >= 12 ? 'PM' : 'AM';
          hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
          formattedTime = '$hour:$minute $period';
        }
      }
    } catch (e) {
      debugPrint('Date/Time parse error: $e');
    }

    // Show action buttons only if provider action is pending and status is not final
    final bool showActionButtons = actionByProvider == "pending" &&
        !['completed', 'cancelled', 'failed']
            .contains(currentStatus.toLowerCase());

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppConstants.appPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Ambulance Booking Details',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(50),
            bottomRight: Radius.circular(50),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              title: "Patient Information",
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        patientName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Chip(
                      label: Text(isPaid ? "Paid" : "Pending"),
                      backgroundColor: isPaid
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPaid
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDetailRow("Booking ID",
                    "#AMB${bookingId.toString().padLeft(5, '0')}"),
                _buildDetailRow(
                    "Booking Date", "$formattedDate • $formattedTime"),
              ],
            ),
            const SizedBox(height: 12),
            _buildCard(
              title: "Trip Route",
              data: bookingData,
              children: [
                Row(children: [
                  const Icon(Icons.arrow_upward, color: Colors.green, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(pickupLocation,
                          style: const TextStyle(fontSize: 15))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.arrow_downward, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(dropLocation,
                          style: const TextStyle(fontSize: 15))),
                ]),
              ],
            ),
            if (photoUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildCard(
                title: "Ambulance Photos",
                children: [
                  SizedBox(
                    height: 180,
                    child: PageView.builder(
                      itemCount: photoUrls.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () =>
                              _openPhotoGallery(context, photoUrls, index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                photoUrls[index],
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                        child: CircularProgressIndicator()),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.error,
                                      color: Colors.red),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _buildCard(
              title: "Assigned Ambulance",
              children: [
                Text(ambulanceName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(ambulanceType,
                    style: TextStyle(
                        color: Colors.grey[700], fontStyle: FontStyle.italic)),
                const SizedBox(height: 12),
                _buildDetailRow("Vehicle Number", vehicleNumber),
                _buildDetailRow("Depot Location", locationName),
                _buildDetailRow("Availability", availabilityStatus,
                    isBold: true),
                const SizedBox(height: 12),
                const Text("Description",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(description,
                    style: TextStyle(color: Colors.grey[700], height: 1.4)),
                const SizedBox(height: 12),
                const Text("Charges",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                _buildDetailRow("Base Fare", "₹$baseFare"),
                _buildDetailRow("Per KM Charge", "₹$perKm"),
                _buildDetailRow("Waiting Charge", "₹$waitingPerMin / min"),
                const SizedBox(height: 12),
                const Text("Availability Slots",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(availabilitySlots,
                    style: TextStyle(color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 12),
            _buildCard(
              title: "Driver Information",
              children: [
                _buildDetailRow("Name", driverName),
                _buildDetailRow("Contact", driverContact),
              ],
            ),
            const SizedBox(height: 12),
            _buildCard(
              title: "Payment Summary",
              children: [
                _buildDetailRow("Total Amount", "₹$amountCharged",
                    isBold: true),
                _buildDetailRow("Payment Status",
                    isPaid ? "Paid Online" : "Pending Payment"),
                _buildDetailRow("Transaction ID",
                    bookingData['payment_id']?.toString() ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              color: _getStatusColor(currentStatus),
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Center(
                  child: Text(
                    "Current Status: ${currentStatus.toUpperCase()}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getStatusTextColor(currentStatus),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      persistentFooterButtons: showActionButtons
          ? [
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Update Status",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.appPrimaryColor,
                          ),
                        ),
                      ),
                      isUpdating
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedStatus,
                                icon: const Icon(Icons.arrow_drop_down),
                                borderRadius: BorderRadius.circular(14),
                                items: statusList.map((status) {
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Text(
                                      status.toUpperCase(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null &&
                                      value != selectedStatus) {
                                    updateBookingStatus(value);
                                  }
                                },
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ]
          : null,
    );
  }
}
