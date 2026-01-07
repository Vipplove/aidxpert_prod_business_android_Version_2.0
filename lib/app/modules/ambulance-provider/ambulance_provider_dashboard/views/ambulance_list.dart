// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../../../constants/app_constants.dart';
import '../../../../routes/app_pages.dart';
import '../../component/ambulance_bottom_navbar.dart';
import '../../../../../utils/helper.dart';
import 'add_ambulance_screen.dart';

class AmbulanceList extends StatefulWidget {
  const AmbulanceList({super.key});

  @override
  State<AmbulanceList> createState() => _AmbulanceListState();
}

class _AmbulanceListState extends State<AmbulanceList> {
  final RxBool isLoading = true.obs;
  final RxList<dynamic> ambulances = <dynamic>[].obs;
  final RxMap<String, dynamic> providerInfo = <String, dynamic>{}.obs;

  @override
  void initState() {
    super.initState();
    fetchAmbulances();
  }

  Future<void> fetchAmbulances() async {
    final profileId = await readStr('profileId') ?? '1';
    final token = await readStr('token');

    try {
      isLoading.value = true;

      final response = await http.get(
        Uri.parse(
            "${AppConstants.endpoint}/ambulances/details/provider/$profileId/all"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        ambulances.assignAll(jsonData['list'] ?? []);
        if (ambulances.isNotEmpty) {
          providerInfo.value =
              ambulances.first['ambulance_service_providers'] ?? {};
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.toNamed(Routes.AMBULANCE_PROVIDER_DASHBOARD);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF4F7FB),
        appBar: AppBar(
          title: const Text("My Ambulances"),
          automaticallyImplyLeading: false,
          centerTitle: true,
          backgroundColor: AppConstants.appPrimaryColor,
          shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50)),
          ),
          actions: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    Get.to(
                        () => const AddAmbulanceScreen(
                              ambulanceData: null,
                            ),
                        transition: Transition.rightToLeft);
                  },
                ),
                const Text(
                  "Add",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(width: 15),
              ],
            ),
          ],
        ),
        body: Obx(() {
          if (isLoading.value) {
            return Center(child: loading);
          }

          return RefreshIndicator(
            onRefresh: fetchAmbulances,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ambulances.length + 1,
              itemBuilder: (_, index) {
                if (index == 0) return const SizedBox(height: 8);
                final amb = ambulances[index - 1];
                return GestureDetector(
                  onTap: () async {
                    final result = await Get.to(
                        () => AddAmbulanceScreen(ambulanceData: amb));
                    if (result == true) fetchAmbulances();
                  },
                  child: _ambulanceCard(amb),
                );
              },
            ),
          );
        }),
        bottomNavigationBar: const AmbulanceProviderBottomNavBar(index: 2),
      ),
    );
  }

  /// AMBULANCE CARD (NO EXPANSION)
  Widget _ambulanceCard(dynamic amb) {
    final List images = List<String>.from(amb['ambulance_photos'] ?? []);
    final charges = amb['transport_charges'] ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 15,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          /// IMAGE SLIDER
          SizedBox(
            height: 180,
            child: PageView.builder(
              itemCount: images.isEmpty ? 1 : images.length,
              itemBuilder: (_, i) {
                return ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  child: images.isEmpty
                      ? Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.local_hospital,
                              size: 80, color: Colors.white),
                        )
                      : Image.network(images[i], fit: BoxFit.cover),
                );
              },
            ),
          ),

          /// DETAILS
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// NAME + STATUS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        amb['ambulance_name'],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _statusChip(amb['availability_status']),
                  ],
                ),

                const SizedBox(height: 6),

                /// TYPE & VEHICLE
                Wrap(
                  spacing: 8,
                  children: [
                    _infoChip(Icons.category, amb['ambulance_type']),
                    _infoChip(Icons.confirmation_number, amb['vehicle_number']),
                  ],
                ),

                const SizedBox(height: 12),

                /// DRIVER & DEPOT
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _quickInfo("Driver", amb['driver_name']),
                    _quickInfo("Contact", amb['driver_contact']),
                  ],
                ),
                const SizedBox(height: 8),
                _quickInfo("Depot", amb['location_name']),
                const SizedBox(height: 12),

                /// SHIFT TIME
                _infoRow(Icons.access_time, "Shift", amb['driver_shift_time']),

                const Divider(height: 30),

                /// PRICING
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _priceTile("Base Fare", "₹${charges['baseFare'] ?? 0}"),
                    _priceTile("Per KM", "₹${charges['perKm'] ?? 0}"),
                    if (charges['waitingChargePerMin'] != null)
                      _priceTile(
                          "Waiting", "₹${charges['waitingChargePerMin']}/min"),
                  ],
                ),

                const SizedBox(height: 12),

                /// DESCRIPTION
                if ((amb['description'] ?? '').toString().isNotEmpty)
                  Text(
                    amb['description'],
                    style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final isAvailable = status == "AVAILABLE";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
            fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(text),
      backgroundColor: Colors.grey.shade100,
    );
  }

  Widget _quickInfo(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _priceTile(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text("$title: ", style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value)),
      ],
    );
  }
}
