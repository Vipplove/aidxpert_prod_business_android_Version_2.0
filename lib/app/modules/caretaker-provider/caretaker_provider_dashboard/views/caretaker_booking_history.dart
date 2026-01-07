// screens/caretaker/caretaker_booking_history.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:intl/intl.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';
import '../../../../routes/app_pages.dart';
import '../../component/caretaker_bottom_navbar.dart';
import '../controllers/caretaker_controller.dart';

class CareTakerBookingHistory extends StatelessWidget {
  const CareTakerBookingHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CaretakerController());
    controller.fetchBookingHistory();

    return WillPopScope(
      onWillPop: () async {
        Get.offAllNamed(Routes.CARETAKER_PROVIDER_DASHBOARD);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: AppConstants.appPrimaryColor,
          automaticallyImplyLeading: false,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Booking History',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50)),
          ),
        ),
        bottomNavigationBar: const CaretakerProviderBottomNavBar(index: 1),
        body: Obx(() {
          if (controller.isLoading.value) {
            return Center(child: loading);
          }

          if (controller.bookingHistory.isEmpty) {
            return RefreshIndicator(
              onRefresh: controller.fetchBookingHistory,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history,
                            size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text('No booking history yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.fetchBookingHistory,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.bookingHistory.length,
              itemBuilder: (context, index) {
                final booking = controller.bookingHistory[index];

                // Patient Name
                String patientName =
                    "Patient #${booking['patient_id'] ?? '??'}";
                final patientDetails = booking['patient_details']?['user']
                    as Map<String, dynamic>?;
                if (patientDetails != null) {
                  final first = patientDetails['first_name']?.toString() ?? '';
                  final last = patientDetails['last_name']?.toString() ?? '';
                  final full = '$first $last'.trim();
                  if (full.isNotEmpty) patientName = full;
                }

                // Dates
                String dateRange = "N/A";
                try {
                  final from = DateTime.parse(booking['booking_date_from']);
                  final to = DateTime.parse(booking['booking_date_to']);
                  dateRange =
                      "${DateFormat('dd MMM').format(from)} - ${DateFormat('dd MMM yyyy').format(to)}";
                } catch (e) {}

                // Amount & Payment
                final double amount =
                    (booking['final_charges'] ?? booking['booking_fee'] ?? 0)
                        .toDouble();
                final bool isPaid = booking['payment_id'] != null;

                // Status
                String status =
                    (booking['caretaker_booking_status'] ?? 'Pending')
                        .toString();
                final statusStyle = _getStatusStyle(status);
                final Color statusColor = statusStyle['color'] as Color;
                final Color statusTextColor = statusStyle['textColor'] as Color;

                // Caretaker Type
                String caretakerType =
                    booking['caretaker_type'] ?? 'General Care';
                if (caretakerType == 'null' || caretakerType.isEmpty) {
                  caretakerType = 'General Care';
                }

                // Shift & Time
                String shift = (booking['slots'] ?? 'Day').toUpperCase();
                String timeSlot = booking['time_duration'] ?? 'Full Day';

                // Remark
                String remark = booking['remark'] ?? '';
                bool hasRemark = remark.isNotEmpty && remark != 'null';

                String avatarLetter =
                    patientName.isNotEmpty ? patientName[0].toUpperCase() : "?";

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Get.toNamed(Routes.CARETAKER_BOOKING_DETAILS,
                          arguments: booking);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppConstants.appPrimaryColor
                                    .withOpacity(0.15),
                                child: Text(
                                  avatarLetter,
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.appPrimaryColor),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(patientName,
                                        style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                        "#BK${(booking['booking_id'] ?? '??').toString().padLeft(4, '0')}",
                                        style: TextStyle(
                                            color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                        color: statusColor,
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Text(status.toUpperCase(),
                                        style: TextStyle(
                                            color: statusTextColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.medical_services,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 10),
                              Text("Type: $caretakerType",
                                  style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(dateRange,
                                      style: const TextStyle(fontSize: 15))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 10),
                              Text("$timeSlot • $shift Shift",
                                  style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                          if (hasRemark) ...[
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.note_alt,
                                    size: 18, color: Colors.grey),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text("Note: $remark",
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                          fontStyle: FontStyle.italic)),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Total Amount",
                                      style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 14)),
                                  Text(isPaid ? "Paid" : "Pending",
                                      style: TextStyle(
                                          color: isPaid
                                              ? Colors.green
                                              : Colors.orange,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                              Text("₹$amount",
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.appPrimaryColor)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Map<String, Color> _getStatusStyle(String status) {
    final upper = status.toUpperCase();
    if (upper.contains('COMPLETED') ||
        upper.contains('BOOKED') ||
        upper.contains('CONFIRMED')) {
      return {'color': Colors.green, 'textColor': Colors.white};
    } else if (upper.contains('PROGRESS') || upper.contains('ON DUTY')) {
      return {'color': Colors.blue, 'textColor': Colors.white};
    } else if (upper.contains('PENDING')) {
      return {'color': Colors.orange, 'textColor': Colors.white};
    } else if (upper.contains('CANCEL')) {
      return {'color': Colors.red, 'textColor': Colors.white};
    }
    return {'color': Colors.grey, 'textColor': Colors.white};
  }
}
