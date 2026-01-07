// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';
import '../../../../routes/app_pages.dart';
import '../../component/ambulance_bottom_navbar.dart';
import '../controllers/ambulance_controller.dart';

class AmbulanceProviderDashboard extends StatelessWidget {
  AmbulanceProviderDashboard({Key? key}) : super(key: key);

  final AmbulanceController controller = Get.put(AmbulanceController());

  // Function to accept booking
  Future<void> _acceptBooking(int bookingId) async {
    final token = await readStr('token');
    if (token == null || token.isEmpty) {
      customToast("Authentication failed. Please login again.", Colors.red);
      return;
    }

    try {
      final response = await http.put(
        Uri.parse(
            '${AppConstants.endpoint}/ambulances/provider-dashboard/booking-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "ambulance_booking_id": bookingId,
          "booking_status": "confirmed",
        }),
      );

      final res = jsonDecode(response.body);

      if (response.statusCode == 200 && res['status'] == true) {
        customToast("Booking accepted successfully!", Colors.green);

        // Refresh today's bookings
        controller.fetchBookings(type: "today");
      } else {
        customToast(res['message'] ?? "Could not accept booking", Colors.red);
      }
    } catch (e) {
      customToast("Network error: Unable to accept booking", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => await onWillPop(context),
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: AppConstants.appPrimaryColor,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Image.asset(
            'assets/logo/logo.png',
            height: 150,
            width: 150,
            color: Colors.white,
          ),
          shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
          ),
        ),
        bottomNavigationBar: const AmbulanceProviderBottomNavBar(index: 0),
        body: Obx(() {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stat Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: "Total Served Patients",
                        value: controller.totalServedPatients.value.toString(),
                        subtitle: "Since Joining",
                        icon: Icons.person_search,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        title: "Today's Bookings",
                        value: controller.totalTodaysBookings.value.toString(),
                        subtitle: "Bookings Today",
                        icon: Icons.local_hospital,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // Bookings Header
                const Text(
                  "Bookings",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Tabs + Booking List
                Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          TabBar(
                            labelColor: AppConstants.appPrimaryColor,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: AppConstants.appPrimaryColor,
                            labelStyle: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                            tabs: const [
                              Tab(text: "Today"),
                              Tab(text: "Past"),
                            ],
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.65,
                            child: TabBarView(
                              children: [
                                _buildBookingsList(
                                    controller.todayBookings, true),
                                _buildBookingsList(
                                    controller.pastBookings, false),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ================== STAT CARD ==================
  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
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

  // ================== BOOKINGS LIST ==================
  Widget _buildBookingsList(RxList<dynamic> bookings, bool isToday) {
    if (controller.isLoading.value && bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bookings.isEmpty) {
      return const Center(
          child: Text("No bookings found", style: TextStyle(fontSize: 16)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final b = bookings[index];

        // Extract patient name
        String patientName = "Patient #${b['patient_id']}";
        if (b['ambulance_booking_for'] == "others" &&
            b['others_person_details'] != null) {
          patientName = b['others_person_details']['name'] ?? patientName;
        }

        // Format date & time
        String formattedDate = _formatDate(b['ambulance_booking_date']);
        String formattedTime = _formatTime(b['ambulance_booking_time']);

        // Shorten locations
        String pickup = _shortenLocation(b['pickup_location']);
        String drop = _shortenLocation(b['drop_location']);

        // Ambulance type
        String ambulanceType =
            b['ambulance_details']['ambulance_type'] ?? "Unknown";

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top: Avatar + Name + Chip
              InkWell(
                onTap: () {
                  Get.toNamed(Routes.AMBULANCE_BOOKING_DETAILS, arguments: b);
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.grey.shade300,
                        child: Text(
                          patientName[0].toUpperCase(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patientName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text("#PT00${b['patient_id']}",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(isToday ? "Today" : "Past"),
                        backgroundColor: isToday
                            ? Colors.green.shade50
                            : Colors.grey.shade200,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isToday ? Colors.green : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),

              // Middle: Details
              InkWell(
                onTap: () {
                  Get.toNamed(Routes.AMBULANCE_BOOKING_DETAILS, arguments: b);
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "#AMB${b['ambulance_booking_id'].toString().padLeft(4, '0')}",
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text("$formattedDate • $formattedTime"),
                      const SizedBox(height: 6),
                      Text("Type: $ambulanceType"),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.arrow_upward,
                              size: 16, color: Colors.green),
                          const SizedBox(width: 6),
                          Expanded(child: Text(pickup)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.arrow_downward,
                              size: 16, color: Colors.red),
                          const SizedBox(width: 6),
                          Expanded(child: Text(drop)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom: Amount + Buttons
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₹${b['amount_charged']}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                    if (isToday)
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              await _acceptBooking(b['ambulance_booking_id']);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Accept",
                                style: TextStyle(
                                    fontSize: 13, color: Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              customToast("Booking rejected", Colors.red);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Reject",
                                style: TextStyle(fontSize: 13)),
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

  // Helper: Format date to "16 Dec 2025"
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  // Helper: Format time to "12:30 PM"
  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      hour = hour == 0
          ? 12
          : hour > 12
              ? hour - 12
              : hour;
      return '$hour:$minute $period';
    } catch (e) {
      return timeStr;
    }
  }

  // Helper: Shorten location (first part before comma)
  String _shortenLocation(String location) {
    return location.split(',').first.trim();
  }
}
