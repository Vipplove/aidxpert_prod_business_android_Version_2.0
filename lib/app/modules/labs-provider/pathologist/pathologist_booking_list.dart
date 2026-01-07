// lib/app/modules/labs-provider/views/pathologist_booking_list.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../constants/app_constants.dart';
import '../../../../utils/helper.dart';
import '../../../routes/app_pages.dart';

class PathologistBookingListController extends GetxController {
  var isLoading = true.obs;
  var bookingList = <Map<String, dynamic>>[].obs;
  var filteredList = <Map<String, dynamic>>[].obs;
  var searchQuery = ''.obs;

  Future<void> fetchBookings(String providerId, String labId) async {
    await saveStr('profileId', providerId.toString());

    try {
      isLoading(true);
      final token = await readStr('token');

      final url = Uri.parse(
        '${AppConstants.endpoint}/labs/provider-dashboard/$providerId/lab-test-bookings?lab_id=$labId',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true) {
          final List data = json['appointments'] ?? [];
          bookingList.assignAll(data.cast<Map<String, dynamic>>());
          filteredList.assignAll(bookingList); // Initially show all
        } else {
          customToast(json['message'] ?? 'No data', Colors.orange);
        }
      }
    } catch (e) {
      customToast('Failed to load bookings', Colors.red);
    } finally {
      isLoading(false);
    }
  }

  void filterBookings(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredList.assignAll(bookingList);
    } else {
      final lowerQuery = query.toLowerCase();
      filteredList.assignAll(
        bookingList.where((booking) {
          final bookingId = booking['lab_test_booking_id']?.toString() ?? '';
          return bookingId.contains(lowerQuery);
        }).toList(),
      );
    }
  }
}

class PathologistBookingList extends StatefulWidget {
  final String providerId;
  final String labId;

  const PathologistBookingList({
    super.key,
    required this.providerId,
    required this.labId,
  });

  @override
  State<PathologistBookingList> createState() => _PathologistBookingListState();
}

class _PathologistBookingListState extends State<PathologistBookingList> {
  final TextEditingController _searchController = TextEditingController();
  late final PathologistBookingListController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(PathologistBookingListController());
    controller.fetchBookings(widget.providerId, widget.labId);
  }

  void clearSearch() {
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstants.appPrimaryColor,
        foregroundColor: Colors.white,
        title: const Text('Booking History'),
        centerTitle: true,
        elevation: 0,
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(50),
            bottomRight: Radius.circular(50),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: controller.filterBookings,
              decoration: InputDecoration(
                hintText: 'Search by Booking ID...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.filterBookings('');
                          clearSearch();
                        },
                      )
                    : const SizedBox()),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // Results Count
          Obx(() => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${controller.filteredList.length} booking${controller.filteredList.length == 1 ? '' : 's'} found',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
              )),

          const SizedBox(height: 8),

          // Booking List
          Expanded(
            child: Obx(() => controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : controller.filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox,
                                size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              controller.searchQuery.value.isNotEmpty
                                  ? 'No booking found with ID "${controller.searchQuery.value}"'
                                  : 'No bookings available',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => controller.fetchBookings(
                            widget.providerId, widget.labId),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: controller.filteredList.length,
                          itemBuilder: (context, index) =>
                              _buildTaskCard(controller.filteredList[index]),
                        ),
                      )),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> booking) {
    final patient = booking['patient_details']?['user'] ?? {};
    final tests = List.from(booking['lab_test_details'] ?? []);
    final payment = booking['payment_details'] ?? {};

    final name =
        '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}'.trim();
    final bookingId = booking['lab_test_booking_id']?.toString() ?? '-';
    final testCount = tests.length;
    final date = booking['booking_date'] ?? '-';
    final time = booking['booking_time'] ?? '-';
    final paymentStatus = payment['paymentStatus']?.toString() ?? 'Unknown';
    final isPaid = paymentStatus.toLowerCase() == 'paid';

    return InkWell(
      onTap: () => Get.toNamed(Routes.LABS_TEST_DETAILS, arguments: booking),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name.isEmpty ? 'Unknown Patient' : name,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPaid ? 'Paid' : 'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isPaid ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                        text: 'Booking ID: ',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13)),
                    TextSpan(
                        text: bookingId,
                        style: TextStyle(
                            color: AppConstants.appPrimaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$testCount test${testCount == 1 ? '' : 's'} • $date at $time',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tests.take(3).map((t) {
                        return Chip(
                          label: Text(
                            t['test_name'] ?? 'Test',
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          backgroundColor:
                              AppConstants.appPrimaryColor.withOpacity(0.1),
                          side: BorderSide(
                              color: AppConstants.appPrimaryColor
                                  .withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        );
                      }).toList(),
                    ),
                  ),
                  if (tests.length > 3)
                    Text('+${tests.length - 3} more',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                booking['booking_status'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: getBookingStatusColor(booking['booking_status']),
                ),
              ),
              const SizedBox(height: 0),
            ],
          ),
        ),
      ),
    );
  }
}
