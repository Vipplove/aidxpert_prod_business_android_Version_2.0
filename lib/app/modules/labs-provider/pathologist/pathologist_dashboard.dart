// lib/app/modules/labs-provider/views/pathologist_dashboard.dart
// ignore_for_file: deprecated_member_use
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../constants/app_constants.dart';
import '../../../../utils/helper.dart';
import '../labs_provider_dashboard/controllers/pathologist_dashboard_controller.dart.dart';
import 'pathologist_booking_list.dart';
import 'pathologist_profile.dart';

class PathologistDashboard extends StatefulWidget {
  const PathologistDashboard({super.key});

  @override
  State<PathologistDashboard> createState() => _PathologistDashboardState();
}

class _PathologistDashboardState extends State<PathologistDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Get.put(PathologistDashboardController());
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
                bottomRight: Radius.circular(50)),
          ),
        ),
        body: GetBuilder<PathologistDashboardController>(
          builder: (ctrl) => _selectedIndex == 0
              ? Home(controller: ctrl)
              : PathologistProfile(controller: ctrl),
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
                label: 'My Labs'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ==================== HOME TAB ====================
class Home extends StatelessWidget {
  final PathologistDashboardController controller;
  const Home({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'My Assigned Labs',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.appPrimaryColor),
              ),
            ),
            Expanded(
              child: controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : controller.labList.isEmpty
                      ? const Center(
                          child: Text("No labs assigned yet.",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey)),
                        )
                      : RefreshIndicator(
                          onRefresh: controller.refreshData,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: controller.labList.length,
                            itemBuilder: (context, index) {
                              final lab = controller.labList[index];
                              final photos = (lab['lab_photos'] as List?) ?? [];
                              final provider =
                                  lab['lab_service_provider'] ?? {};
                              final createdAt = lab['createdAt'] != null
                                  ? DateFormat('MMM dd, yyyy')
                                      .format(DateTime.parse(lab['createdAt']))
                                  : 'Unknown';
                              final labId = lab['lab_id']?.toString() ?? '3';
                              final providerId =
                                  lab['lab_service_provider_id']?.toString() ??
                                      '3';

                              return _LabCard(
                                name: lab['lab_name'] ?? 'Unknown Lab',
                                address:
                                    '${lab['area'] ?? ''}, ${lab['city'] ?? ''}, ${lab['state'] ?? ''} ${lab['zip_code'] ?? ''}',
                                description: lab['lab_description'],
                                imageUrl: photos.isNotEmpty
                                    ? photos[0].toString()
                                    : null,
                                providerLogo: provider['logo'],
                                providerName:
                                    provider['provider_name'] ?? 'Provider',
                                isActive: lab['is_active'] ?? false,
                                createdAt: createdAt,
                                providerId: providerId,
                                labId: labId,
                              );
                            },
                          ),
                        ),
            ),
          ],
        ));
  }
}

// ==================== LAB CARD ====================
class _LabCard extends StatelessWidget {
  final String name, address, providerName, createdAt, labId, providerId;
  final String? imageUrl, providerLogo, description;
  final bool isActive;

  const _LabCard({
    required this.name,
    required this.address,
    required this.providerName,
    required this.createdAt,
    required this.labId,
    required this.providerId,
    this.imageUrl,
    this.providerLogo,
    this.description,
    required this.isActive,
  });

  // Helper to capitalize first letter
  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.to(
            () => PathologistBookingList(providerId: providerId, labId: labId));
      },
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          color: Colors.grey[300],
                          child:
                              const Center(child: CircularProgressIndicator())),
                      errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 60)),
                    )
                  : Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(Icons.local_hospital,
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
                          _capitalize(name),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
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
                              color: isActive ? Colors.green : Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address
                              .trim()
                              .replaceAll(RegExp(r',\s*,|,\s*$'), ', ')
                              .replaceAll(', ,', ', '),
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (description != null &&
                      description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(description!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          providerLogo != null
                              ? CircleAvatar(
                                  radius: 14,
                                  backgroundImage: NetworkImage(providerLogo!))
                              : CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppConstants.appPrimaryColor,
                                  child: const Icon(Icons.business,
                                      size: 16, color: Colors.white)),
                          const SizedBox(width: 8),
                          Text(providerName,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[700])),
                        ],
                      ),
                      Text('Since: $createdAt',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
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
