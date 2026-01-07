// screens/caretaker/caretaker_dashboard.dart
// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';
import '../../../../routes/app_pages.dart';
import '../../component/caretaker_bottom_navbar.dart';
import '../controllers/caretaker_controller.dart';

class CareTakerDashboard extends StatelessWidget {
  CareTakerDashboard({Key? key}) : super(key: key);

  final CaretakerController controller = Get.put(CaretakerController());

  Future<void> _acceptBooking(int bookingId) async {
    final token = await readStr('token');
    final profileId = await readStr('profileId');

    if (token == null || token.isEmpty) {
      customToast("Authentication failed. Please login again.", Colors.red);
      return;
    }

    try {
      EasyLoading.show(status: 'Accepting booking...');
      final response = await http.patch(
        Uri.parse(
          '${AppConstants.endpoint}/caretakers/provider-dashboard/$profileId/booking-status',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "booking_id": bookingId,
          "caretaker_booking_status": "Booked",
        }),
      );

      final res = jsonDecode(response.body);

      if (response.statusCode == 200 && res['status'] == true) {
        customToast("Booking booked successfully!", Colors.green);
        controller.refreshData(); // refresh list
      } else {
        customToast(
          res['message'] ?? "Could not update booking status",
          Colors.red,
        );
      }
    } catch (e) {
      debugPrint("Accept booking error: $e");
      customToast("Network error. Please try again.", Colors.red);
    } finally {
      EasyLoading.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => await onWillPop(context),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: AppConstants.appPrimaryColor,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text(
            "Caretaker Dashboard",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        bottomNavigationBar: const CaretakerProviderBottomNavBar(index: 0),
        body: Obx(() {
          return RefreshIndicator(
            onRefresh: controller.refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: "Total Served Patients",
                          value: controller.totalServedPatients.string,
                          subtitle: "Since Joining",
                          icon: Icons.people_alt,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: "Current Bookings",
                          value: controller.totalCurrentBookings.string,
                          subtitle: "Active Today",
                          icon: Icons.assignment_turned_in,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  const Text(
                    "Service Requests",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          TabBar(
                            labelColor: AppConstants.appPrimaryColor,
                            unselectedLabelColor: Colors.grey.shade600,
                            indicatorColor: AppConstants.appPrimaryColor,
                            indicatorWeight: 3,
                            labelStyle: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                            tabs: const [
                              Tab(text: "Today"),
                              Tab(text: "Past"),
                            ],
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.65,
                            child: TabBarView(
                              children: [
                                _buildBookingList(
                                    controller.todayBookings, true),
                                _buildBookingList(
                                    controller.pastBookings, false),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, size: 26, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                const SizedBox(height: 6),
                Text(value,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList(RxList<dynamic> bookings, bool isToday) {
    if (controller.isLoading.value && bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text("No ${isToday ? 'current' : 'past'} requests",
                style: const TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final b = bookings[index];

        // Safe patient name
        String patientName = "Patient #${b['patient_id'] ?? '??'}";
        final patientDetails =
            b['patient_details']?['user'] as Map<String, dynamic>?;
        if (patientDetails != null) {
          final first = patientDetails['first_name']?.toString() ?? '';
          final last = patientDetails['last_name']?.toString() ?? '';
          final full = '$first $last'.trim();
          if (full.isNotEmpty) patientName = full;
        }

        String avatarLetter =
            patientName.isNotEmpty ? patientName[0].toUpperCase() : "?";

        String dateRange =
            "${_formatDate(b['booking_date_from'])} - ${_formatDate(b['booking_date_to'])}";
        String timeSlot = b['time_duration'] ?? "Full Day";
        String bookingType = b['booking_type'] ?? "Long Term";
        String status =
            (b['caretaker_booking_status'] ?? "Pending").toUpperCase();

        Color statusColor = status == "CONFIRMED"
            ? Colors.green
            : status == "PENDING"
                ? Colors.orange
                : status == "COMPLETED"
                    ? Colors.blue
                    : Colors.grey.shade600;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: () {
                    Get.toNamed(
                      Routes.CARETAKER_BOOKING_DETAILS,
                      arguments: b,
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor:
                            AppConstants.appPrimaryColor.withOpacity(0.2),
                        child: Text(avatarLetter,
                            style: TextStyle(
                                fontSize: 24,
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
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                                "#BK${b['booking_id']?.toString().padLeft(4, '0') ?? '0000'}",
                                style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(status,
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: () {
                    Get.toNamed(
                      Routes.CARETAKER_BOOKING_DETAILS,
                      arguments: b,
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailRow(Icons.calendar_today, "Duration", dateRange),
                      const SizedBox(height: 10),
                      _detailRow(Icons.access_time, "Time Slot", timeSlot),
                      const SizedBox(height: 10),
                      _detailRow(Icons.category, "Type", bookingType),
                      if (b['remark'] != null &&
                          b['remark'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text("Note: ${b['remark']}",
                              style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontStyle: FontStyle.italic)),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Total Amount",
                            style: TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                            "₹${b['final_charges'] ?? b['booking_fee'] ?? '0'}",
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.appPrimaryColor)),
                      ],
                    ),
                    if (isToday && status == "PENDING")
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => _acceptBooking(b['booking_id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Accept",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () =>
                                customToast("Booking rejected", Colors.red),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Reject",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppConstants.appPrimaryColor),
        const SizedBox(width: 12),
        Text("$label:", style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "N/A";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
