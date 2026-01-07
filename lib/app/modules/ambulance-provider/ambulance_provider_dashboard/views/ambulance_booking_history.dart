// screens/ambulance/ambulance_booking_history.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:custom_date_range_picker/custom_date_range_picker.dart';
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';
import '../../../../routes/app_pages.dart';
import '../../component/ambulance_bottom_navbar.dart';
import '../controllers/ambulance_controller.dart';

class AmbulanceBookingHistory extends StatefulWidget {
  const AmbulanceBookingHistory({super.key});

  @override
  State<AmbulanceBookingHistory> createState() =>
      _AmbulanceBookingHistoryState();
}

class _AmbulanceBookingHistoryState extends State<AmbulanceBookingHistory> {
  final AmbulanceController ctrl = Get.put(AmbulanceController());
  final TextEditingController _searchController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    ctrl.fetchBookingHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDateRangePicker() {
    showCustomDateRangePicker(
      context,
      dismissible: true,
      minimumDate: DateTime(2020),
      maximumDate: DateTime.now().add(const Duration(days: 365)),
      startDate: _startDate,
      endDate: _endDate,
      backgroundColor: Colors.white,
      primaryColor: AppConstants.appPrimaryColor,
      onApplyClick: (start, end) {
        setState(() {
          _startDate = start;
          _endDate = end;
        });
        // Call API with date filter
        ctrl.fetchBookingHistory(startDate: start, endDate: end);
      },
      onCancelClick: () {
        setState(() {
          _startDate = null;
          _endDate = null;
        });
        // Reload without date filter
        ctrl.fetchBookingHistory();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.toNamed(Routes.AMBULANCE_PROVIDER_DASHBOARD);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: AppConstants.appPrimaryColor,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text(
            "Booking History",
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
        floatingActionButton: FloatingActionButton(
          mini: true,
          backgroundColor: AppConstants.appPrimaryColor,
          onPressed: _showDateRangePicker,
          child: const Icon(Icons.filter_alt, color: Colors.white),
        ),
        body: Column(
          children: [
            // Search Bar (Client-side search by Booking ID)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Search by Booking ID...",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            // Reload current filtered list (with or without date)
                            ctrl.fetchBookingHistory(
                              startDate: _startDate,
                              endDate: _endDate,
                            );
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                        color: AppConstants.appPrimaryColor, width: 2),
                  ),
                ),
                onChanged: (value) {
                  final query = value.trim();
                  ctrl.fetchBookingHistory(bookingId: query.toString());
                },
              ),
            ),

            // Booking List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ctrl.fetchBookingHistory(
                    startDate: _startDate,
                    endDate: _endDate,
                  );
                },
                child: Obx(() {
                  final bookings = ctrl.filteredBookings;

                  if (ctrl.isLoading.value) {
                    return Center(child: loading);
                  }

                  if (bookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history,
                              size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text("No booking history",
                              style: TextStyle(fontSize: 18)),
                          const SizedBox(height: 8),
                          Text("Pull down to refresh",
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      return _buildBookingCard(bookings[index]);
                    },
                  );
                }),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const AmbulanceProviderBottomNavBar(index: 1),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    // Patient Name
    String patientName = "Patient #${booking['patient_id']}";
    if (booking['ambulance_booking_for'] == "others" &&
        booking['others_person_details'] != null) {
      patientName = booking['others_person_details']['name'] ?? patientName;
    }

    // Formatting
    final id = booking['ambulance_booking_id'].toString().padLeft(5, '0');
    final date = DateFormat('dd MMM yyyy')
        .format(DateTime.parse(booking['ambulance_booking_date']));
    final time = _formatTime(booking['ambulance_booking_time']);
    final pickup =
        booking['pickup_location'].toString().split(',').first.trim();
    final drop = booking['drop_location'].toString().split(',').first.trim();
    final amount = booking['amount_charged'];
    final type = booking['ambulance_details']['ambulance_type'] ?? "Unknown";
    final isPaid = booking['payment_id'] != null;
    final status = booking['booking_status'] != null;

    return InkWell(
      onTap: () {
        Get.toNamed(Routes.AMBULANCE_BOOKING_DETAILS, arguments: booking);
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    backgroundColor:
                        isPaid ? Colors.green.shade100 : Colors.orange.shade100,
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
              Text("#AMB$id",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text("$date • $time", style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 8),
              Text("Type: $type", style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.arrow_upward, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(pickup)),
              ]),
              Row(children: [
                const Icon(Icons.arrow_downward, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(drop)),
              ]),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "₹$amount",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                  Text(
                    booking['booking_status'].toString(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color:
                          getStatusColor(booking['booking_status'].toString()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$hour:$minute $period';
    } catch (e) {
      return timeStr;
    }
  }
}
