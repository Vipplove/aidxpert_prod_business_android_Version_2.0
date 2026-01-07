// lib/app/modules/radiologist/views/radiologist_dashboard.dart
// ignore_for_file: deprecated_member_use
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../constants/app_constants.dart';
import '../../../../utils/helper.dart';
import '../diagnostics_provider_dashboard/controllers/radiologist_dashboard_controller.dart.dart';
import 'radiologist_booking_list.dart';
import 'radiologist_profile.dart';

class RadiologistDashboard extends StatefulWidget {
  const RadiologistDashboard({super.key});

  @override
  State<RadiologistDashboard> createState() => _RadiologistDashboardState();
}

class _RadiologistDashboardState extends State<RadiologistDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Get.put(RadiologistDashboardController());
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => await onWillPop(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppConstants.appPrimaryColor,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          centerTitle: true,
          elevation: 0,
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
        body: GetBuilder<RadiologistDashboardController>(
          builder: (ctrl) => _selectedIndex == 0
              ? Home(controller: ctrl)
              : RadiologistProfile(controller: ctrl),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: AppConstants.appPrimaryColor,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'My Diagnostics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== HOME TAB ====================
class Home extends StatelessWidget {
  final RadiologistDashboardController controller;
  const Home({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'My Assigned Diagnostic Centers',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.appPrimaryColor,
                ),
              ),
            ),
            Expanded(
              child: controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : controller.diagnosticList.isEmpty
                      ? const Center(
                          child: Text(
                            "No diagnostic center assigned yet.",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: controller.refreshData,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: controller.diagnosticList.length,
                            itemBuilder: (context, index) {
                              final center = controller.diagnosticList[index];

                              // Extract data safely
                              final photos =
                                  (center['center_photos'] as List?) ?? [];
                              final provider =
                                  center['diagnostic_center_providers'] ?? {};
                              final createdAt = center['createdAt'] != null
                                  ? DateFormat('MMM dd, yyyy').format(
                                      DateTime.parse(center['createdAt']))
                                  : 'Unknown';

                              final centerId =
                                  center['diagnostic_center_id'].toString();
                              final providerId =
                                  (center['diagnostic_service_provider_id'] ??
                                          1)
                                      .toString();

                              return _DiagnosticCenterCard(
                                name: center['center_name'] ?? 'Unknown Center',
                                address:
                                    '${center['area'] ?? ''}, ${center['city'] ?? ''}, ${center['state'] ?? ''}',
                                description: center['center_description'],
                                imageUrl: photos.isNotEmpty
                                    ? photos[0].toString()
                                    : null,
                                providerLogo: provider['logo'],
                                providerName:
                                    provider['provider_name'] ?? 'Provider',
                                isActive: center['is_active'] == true,
                                createdAt: createdAt,
                                centerId: centerId,
                                providerId: providerId,
                              );
                            },
                          ),
                        ),
            ),
          ],
        ));
  }
}

// ==================== DIAGNOSTIC CENTER CARD ====================
class _DiagnosticCenterCard extends StatelessWidget {
  final String name, address, providerName, createdAt, centerId, providerId;
  final String? imageUrl, providerLogo, description;
  final bool isActive;

  const _DiagnosticCenterCard({
    required this.name,
    required this.address,
    required this.providerName,
    required this.createdAt,
    required this.centerId,
    required this.providerId,
    this.imageUrl,
    this.providerLogo,
    this.description,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.to(() => RadiologistBookingList(
              providerId: providerId,
              centerId: centerId,
            ));
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, size: 60),
                      ),
                    )
                  : Container(
                      height: 180,
                      color: Colors.grey[300],
                      child: const Icon(Icons.medical_services,
                          size: 70, color: Colors.white70),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withOpacity(0.15)
                              : Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Address
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address.trim().isEmpty
                              ? 'Location not available'
                              : address,
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),

                  // Description
                  if (description != null &&
                      description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      description!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Provider Info + Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          providerLogo != null
                              ? CircleAvatar(
                                  radius: 14,
                                  backgroundImage: NetworkImage(providerLogo!),
                                )
                              : CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppConstants.appPrimaryColor,
                                  child: const Icon(Icons.business,
                                      size: 16, color: Colors.white),
                                ),
                          const SizedBox(width: 8),
                          Text(
                            providerName,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      Text(
                        'Since: $createdAt',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
