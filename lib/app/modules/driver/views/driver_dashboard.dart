// views/driver_dashboard.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../constants/app_constants.dart';
import '../../../../utils/helper.dart';
import '../../../routes/app_pages.dart';
import '../controllers/driver_controller.dart';

class DriverDashboard extends GetView<DriverController> {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => DriverController());

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: AppConstants.appPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: loading);
        }

        if (controller.driverData.isEmpty) {
          return const Center(child: Text('No driver data found'));
        }

        return PageView(
          controller: controller.pageController,
          onPageChanged: (index) => controller.currentIndex.value = index,
          children: [
            _buildBookingsTab(),
            _buildProfileTab(),
          ],
        );
      }),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: controller.currentIndex.value,
          onTap: (index) {
            controller.currentIndex.value = index;
            controller.pageController.animateToPage(index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease);
          },
          selectedItemColor: AppConstants.appPrimaryColor,
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: Colors.white,
          elevation: 12,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.list_alt), label: 'Bookings'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsTab() {
    return Obx(() {
      if (controller.isLoadingBookings.value) {
        return Center(child: loading);
      }

      if (controller.bookings.isEmpty) {
        return RefreshIndicator(
          onRefresh: controller.fetchDriverDetails,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: Get.height * 0.7,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy,
                        size: 90, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('No bookings yet',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Your trips will appear here',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.fetchDriverDetails,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.bookings.length,
          itemBuilder: (context, index) {
            final booking = controller.bookings[index];
            final tracking =
                booking['ambulance_tracking_details'] as List<dynamic>?;
            final latestStatus = tracking?.isNotEmpty == true
                ? tracking!.last['status']
                : 'pending';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= STATUS ROW =================
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getTrackingStatusColor(latestStatus)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            latestStatus.toUpperCase(),
                            style: TextStyle(
                              color: _getTrackingStatusColor(latestStatus),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => _showStatusChangeDialog(
                              booking['ambulance_booking_id'], latestStatus),
                          child: const Icon(Icons.more_vert),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ================= BOOKING INFO =================
                    Text(
                      'Booking #${booking['ambulance_booking_id']}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${convertDate(booking['ambulance_booking_date'])} • ${booking['ambulance_booking_time']}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 18),

                    // ================= ROUTE =================
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.circle,
                                size: 12, color: AppConstants.appPrimaryColor),
                            Container(
                              height: 40,
                              width: 2,
                              color: Colors.grey.shade300,
                            ),
                            const Icon(Icons.location_on,
                                size: 18, color: Colors.red),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking['pickup_location'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                booking['drop_location'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ================= INFO CHIPS =================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _infoChip(Icons.route, '${booking['distance_km']} km'),
                        _infoChip(
                          Icons.person,
                          booking['ambulance_booking_for'] == 'self'
                              ? 'Self'
                              : 'Others',
                        ),
                        _infoChip(
                          Icons.currency_rupee,
                          booking['amount_charged'].toString(),
                        ),
                      ],
                    ),

                    if (booking['remark'] != null &&
                        booking['remark'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Note: ${booking['remark']}',
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic),
                        ),
                      ),

                    const SizedBox(height: 18),

                    // ================= TRACK BUTTON =================
                    if (latestStatus != 'completed' && latestStatus != 'cancel')
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.toNamed(Routes.DRIVER_TRACKING,
                                arguments: booking);
                          },
                          icon:
                              const Icon(Icons.navigation, color: Colors.white),
                          label: const Text(
                            'Track Trip',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.appPrimaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showStatusChangeDialog(int bookingId, String currentStatus) {
    final List<Map<String, dynamic>> statuses = [
      {'value': 'pending', 'label': 'Pending', 'color': Colors.amber.shade700},
      {'value': 'start', 'label': 'Start Trip', 'color': Colors.green},
      {'value': 'enroute', 'label': 'Enroute', 'color': Colors.blue},
      {'value': 'stop', 'label': 'Stop', 'color': Colors.orange},
      {'value': 'cancel', 'label': 'Cancel Trip', 'color': Colors.red},
      {'value': 'completed', 'label': 'Completed', 'color': Colors.teal},
    ];

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Update Trip Status',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) {
            final isSelected = status['value'] == currentStatus;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: isSelected
                    ? null
                    : () {
                        Get.back();
                        controller.updateTrackingStatus(
                            bookingId, status['value']);
                      },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (status['color'] as Color).withOpacity(0.15)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color:
                            isSelected ? status['color'] : Colors.grey.shade300,
                        width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: status['color']),
                      const SizedBox(width: 16),
                      Text(status['label'],
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500)),
                      if (isSelected)
                        const Spacer()
                      else
                        const SizedBox(width: 8),
                      if (isSelected)
                        Icon(Icons.check_circle, color: status['color']),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel', style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final driver = controller.driverData;
    final user = driver['user'] ?? {};
    final ambulance = driver['ambulance_details'] ?? {};
    final provider = driver['ambulance_service_providers'] ?? {};

    return RefreshIndicator(
      onRefresh: controller.fetchDriverDetails,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 20, bottom: 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppConstants.appPrimaryColor,
                  AppConstants.appPrimaryColor.withOpacity(0.9)
                ]),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                          radius: 57,
                          backgroundImage: user['profile_image_name'] != null
                              ? NetworkImage(user['profile_image_name'])
                              : null,
                          child: user['profile_image_name'] == null
                              ? const Icon(Icons.person,
                                  size: 80, color: Colors.grey)
                              : null)),
                  const SizedBox(height: 16),
                  Text('${user['first_name'] ?? ''} ${user['last_name'] ?? ''}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(user['phone_number'] ?? '',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 16),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                          color: _getStatusColor(driver['current_status']),
                          borderRadius: BorderRadius.circular(30)),
                      child: Text(driver['current_status'] ?? 'UNKNOWN',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16))),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _modernSectionCard(
                      title: 'My Ambulance',
                      icon: Icons.track_changes_outlined,
                      items: {
                        'Name': ambulance['ambulance_name'] ?? 'N/A',
                        'Type': ambulance['ambulance_type'] ?? 'N/A',
                        'Vehicle No': ambulance['vehicle_number'] ?? 'N/A',
                        'Shift': ambulance['driver_shift_time'] ?? 'N/A',
                        'Base Fare':
                            '₹${ambulance['transport_charges']?['baseFare'] ?? '--'}',
                        'Per KM':
                            '₹${ambulance['transport_charges']?['perKm'] ?? '--'}',
                      }),
                  const SizedBox(height: 20),
                  _modernSectionCard(
                      title: 'Service Provider',
                      icon: Icons.business,
                      logoUrl: provider['amb_provider_logo'],
                      items: {
                        'Name': provider['registered_name'] ?? 'N/A',
                        'License': provider['license_number'] ?? 'N/A',
                        'Contact': provider['emergency_contact_phone'] ?? 'N/A',
                        'Total Ambulances':
                            '${provider['total_ambulances'] ?? '--'}',
                      }),
                  const SizedBox(height: 30),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                          onPressed: () async {
                            Get.defaultDialog(
                              title: "Logout",
                              titleStyle:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              middleText: "Are you sure you want to logout?",
                              textCancel: "Cancel",
                              textConfirm: "Logout",
                              confirmTextColor: Colors.white,
                              contentPadding: const EdgeInsets.all(15),
                              buttonColor: Colors.redAccent,
                              cancelTextColor: Colors.black54,
                              radius: 16,
                              onConfirm: () async {
                                await clearAllStore();
                                Get.offAllNamed(Routes.ONBOARDING);
                              },
                            );
                          },
                          label: const Text('Logout',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 16)),
                          icon: const Icon(Icons.logout, color: Colors.black),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                              elevation: 3))),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modernSectionCard(
      {required String title,
      required IconData icon,
      required Map<String, String> items,
      String? logoUrl}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 30, color: AppConstants.appPrimaryColor),
            const SizedBox(width: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
          ]),
          if (logoUrl != null && logoUrl.isNotEmpty) ...[
            const SizedBox(height: 16),
            Center(
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(logoUrl,
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.business, size: 60))))
          ],
          const SizedBox(height: 16),
          ...items.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Expanded(
                    flex: 4,
                    child: Text(e.key,
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500))),
                Expanded(
                    flex: 6,
                    child: Text(e.value,
                        style: const TextStyle(fontWeight: FontWeight.w600)))
              ]))),
        ],
      ),
    );
  }

  Widget _compactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppConstants.appPrimaryColor),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text(value,
                    style: TextStyle(fontSize: 15, color: Colors.grey[800]))
              ])),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'on_trip':
        return Colors.orange;
      case 'off_duty':
        return Colors.blue;
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getTrackingStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'start':
        return Colors.green;
      case 'enroute':
        return Colors.blue;
      case 'stop':
        return Colors.orange;
      case 'completed':
        return Colors.teal;
      case 'cancel':
        return Colors.red;
      case 'pending':
        return Colors.amber.shade700;
      default:
        return Colors.grey.shade600;
    }
  }
}
