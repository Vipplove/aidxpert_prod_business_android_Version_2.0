// screens/provider_list.dart
// ignore_for_file: deprecated_member_use

import 'package:aidxpert_business/utils/helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../controllers/sales_controller.dart';
import '../../../../constants/app_constants.dart';

class ProviderList extends StatefulWidget {
  const ProviderList({super.key});

  @override
  State<ProviderList> createState() => _ProviderListState();
}

class _ProviderListState extends State<ProviderList> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String role = (Get.arguments ?? "All").toString();

    return GetBuilder<SalesController>(
      init: SalesController()..fetchUsersByRole(role),
      builder: (controller) {
        _searchController.addListener(() {
          controller.onSearchChanged(_searchController.text.trim());
        });

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: AppConstants.appPrimaryColor,
            foregroundColor: Colors.white,
            title: Text(role),
            centerTitle: true,
            elevation: 0,
            shape: const ContinuousRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(60),
                bottomRight: Radius.circular(60),
              ),
            ),
            actions: [
              if (role == 'Doctors')
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Get.toNamed(Routes.REGISTER_DOCTOR,
                        arguments: {'type': 'create', 'action': 'sales'});
                  },
                )
              else if (role == 'Lab Service Provider')
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Get.toNamed(Routes.LABS_PROVIDER_REGISTRATION,
                        arguments: {'type': 'create', 'action': 'sales'});
                  },
                )
              else if (role == 'Diagnostics Service Provider')
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Get.toNamed(Routes.DIAGNOSTIC_PROVIDER_REGISTRATION,
                        arguments: {'type': 'create', 'action': 'sales'});
                  },
                )
              else if (role == 'Ambulance Service Provider')
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Get.toNamed(Routes.AMBULANCE_PROVIDER_REGISTRATION,
                        arguments: {'type': 'create', 'action': 'sales'});
                  },
                )
              else if (role == 'Caretaker Service Provider')
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Get.toNamed(Routes.CARETAKER_PROVIDER_REGISTRATION,
                        arguments: {'type': 'create', 'action': 'sales'});
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              // Search Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone, email...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              controller.onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // List
              Expanded(
                child: Obx(() {
                  if (controller.isLoadingUsers.value &&
                      controller.users.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.filteredUsers.isEmpty) {
                    return _buildEmptyState(context, role, controller);
                  }

                  return RefreshIndicator(
                    onRefresh: () => controller.refreshProviders(role),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.filteredUsers.length +
                          (controller.isLoadingMore.value ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i == controller.filteredUsers.length) {
                          controller.fetchUsersByRole(role, loadMore: true);
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return SmartProviderCard(
                            user: controller.filteredUsers[i]);
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
      BuildContext context, String role, SalesController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 90, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text("No $role found",
              style: TextStyle(fontSize: 20, color: Colors.grey[700])),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => controller.fetchUsersByRole(role),
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.appPrimaryColor),
          ),
        ],
      ),
    );
  }
}

// Updated Smart Card - Now uses provider_name instead of fullName
class SmartProviderCard extends StatelessWidget {
  final UserModel user;
  const SmartProviderCard({required this.user, super.key});

  // Helper to get provider name from correct nested object
  String get providerName {
    final extra = user.extraDetails;
    if (extra == null) return user.fullName;

    return extra['provider_name'] ??
        extra['lab_service_provider']?['provider_name'] ??
        extra['diagnostic_service_provider']?['provider_name'] ??
        extra['amb_service_provider']?['provider_name'] ??
        extra['caretaker_service_provider']?['provider_name'] ??
        user.fullName ??
        'Unknown Provider';
  }

  // Helper to get logo URL
  String? get logoUrl {
    final extra = user.extraDetails;
    if (extra == null) return user.profileImage;

    return extra['logo'] ??
        extra['lab_service_provider']?['logo'] ??
        extra['diagnostic_service_provider']?['logo'] ??
        extra['amb_service_provider']?['logo'] ??
        extra['caretaker_service_provider']?['logo'] ??
        user.profileImage;
  }

  // Helper to get accreditation/specialization list
  List<String> get accreditations {
    final extra = user.extraDetails;
    if (extra == null) return [];

    final accred = extra['accreditation'] ??
        extra['lab_service_provider']?['accreditation'] ??
        extra['diagnostic_service_provider']?['accreditation'] ??
        extra['amb_service_provider']?['ambulance_types'] ??
        extra['caretaker_service_provider']?['caretaker_types'] ??
        [];

    if (accred is List) {
      return accred.map((e) => e.toString()).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final extra = user.extraDetails;
        final String providerId = extra?['doctor_id']?.toString() ??
            extra?['lab_provider_id']?.toString() ??
            extra?['diagnostic_provider_id']?.toString() ??
            extra?['amb_provider_id']?.toString() ??
            extra?['caretaker_provider_id']?.toString() ??
            '';

        if (providerId.isEmpty) {
          Get.snackbar('Error', 'Provider ID not found');
          return;
        }

        await saveStr('profileId', providerId);

        final args = {
          'type': 'update',
          'id': providerId,
          'action': 'sales',
        };

        print(args);

        if (user.role == 'Doctor') {
          Get.toNamed(Routes.REGISTER_DOCTOR, arguments: args);
        } else if (user.role == 'Lab Service Provider') {
          Get.toNamed(Routes.LABS_PROVIDER_REGISTRATION, arguments: args);
        } else if (user.role == 'Diagnostics Service Provider') {
          Get.toNamed(Routes.DIAGNOSTIC_PROVIDER_REGISTRATION, arguments: args);
        } else if (user.role == 'Ambulance Service Provider') {
          Get.toNamed(Routes.AMBULANCE_PROVIDER_REGISTRATION, arguments: args);
        } else if (user.role == 'Caretaker Service Provider') {
          Get.toNamed(Routes.CARETAKER_PROVIDER_REGISTRATION, arguments: args);
        } else {
          Get.snackbar('Info', 'No detailed view available for this role.');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CachedNetworkImage(
                  imageUrl: logoUrl ?? '',
                  width: 92,
                  height: 92,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.grey[200],
                    child: Icon(_getRoleIcon(user.role),
                        size: 40, color: Colors.grey[600]),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: Icon(_getRoleIcon(user.role),
                        size: 40, color: Colors.grey[600]),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Provider Name (Main Title)
                    Text(
                      providerName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppConstants.appPrimaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.role,
                        style: TextStyle(
                          color: AppConstants.appPrimaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Phone
                    _infoRow(Icons.phone, user.phone),

                    // Location
                    if (user.city != null && user.city!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _infoRow(Icons.location_on,
                            "${user.city}, ${user.state ?? ''}"),
                      ),

                    // Accreditations / Special Info
                    if (accreditations.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: accreditations
                              .take(3)
                              .map((item) => Chip(
                                    label: Text(
                                      item,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: _getChipColor(user.role)),
                                    ),
                                    backgroundColor: _getChipColor(user.role)
                                        .withOpacity(0.12),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.appPrimaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.call,
                        color: AppConstants.appPrimaryColor, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.grey[400], size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon,
            size: 18, color: AppConstants.appPrimaryColor.withOpacity(0.8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[700], fontSize: 14.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getChipColor(String role) {
    switch (role) {
      case 'Doctor':
        return Colors.indigo;
      case 'Lab Service Provider':
      case 'Diagnostics Service Provider':
        return Colors.green;
      case 'Ambulance Service Provider':
        return Colors.red;
      case 'Caretaker Service Provider':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Doctor':
        return Icons.local_hospital_rounded;
      case 'Lab Service Provider':
      case 'Diagnostics Service Provider':
        return Icons.science_rounded;
      case 'Ambulance Service Provider':
        return Icons.emergency_rounded;
      case 'Caretaker Service Provider':
        return Icons.elderly_rounded;
      default:
        return Icons.business_rounded;
    }
  }
}
