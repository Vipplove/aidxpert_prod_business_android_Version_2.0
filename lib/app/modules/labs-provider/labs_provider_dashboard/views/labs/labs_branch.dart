// ignore_for_file: depend_on_referenced_packages, deprecated_member_use
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import '../../../../../../constants/app_constants.dart';
import '../../../../../routes/app_pages.dart';
import '../../../component/lab_bottom_navbar.dart';
import '../../../component/lab_branch_form.dart';
import '../../controllers/labs_provider_dashboard_controller.dart';

class LabsBranchView extends GetView<LabsProviderDashboardController> {
  LabsBranchView({super.key});

  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.toNamed(Routes.LABS_PROVIDER_DASHBOARD);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppConstants.appScaffoldBgColor,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: AppConstants.appPrimaryColor,
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
        floatingActionButton: FloatingActionButton(
          mini: true,
          backgroundColor: AppConstants.appPrimaryColor,
          onPressed: () => _showAddEditDialog(context, null),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: GetBuilder<LabsProviderDashboardController>(
          id: 'labs-branch',
          initState: (_) => controller.getBranchList(),
          builder: (ctrl) => SmartRefresher(
            controller: _refreshController,
            enablePullDown: true,
            header: const WaterDropHeader(),
            onRefresh: () async {
              await ctrl.getBranchList();
              _refreshController.refreshCompleted();
            },
            child: ctrl.isLoading.isTrue
                ? const Center(child: CircularProgressIndicator())
                : ctrl.branchList.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: ctrl.branchList.length,
                        itemBuilder: (_, i) => _BranchCard(
                          branch: ctrl.branchList[i],
                          onEdit: () =>
                              _showAddEditDialog(context, ctrl.branchList[i]),
                          onDeactivate: () => ctrl.deactivateBranch(
                              ctrl.branchList[i]['lab_id'],
                              ctrl.branchList[i]['is_active']),
                        ),
                      ),
          ),
        ),
        bottomNavigationBar: const LabProviderBottomNavBar(index: 2),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_hospital, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No Branches Added",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap + to add your first branch",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, Map<String, dynamic>? data) {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.zero,
        child: LabBranchFormModal(data),
      ),
      barrierDismissible: false,
    );
  }
}

// ==================== MODERN BRANCH CARD ====================
class _BranchCard extends StatelessWidget {
  final Map<String, dynamic> branch;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  const _BranchCard({
    required this.branch,
    required this.onEdit,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = branch['is_active'] == true;
    final List photos = branch['lab_photos'] as List? ?? [];
    final List charges = branch['service_charges'] as List? ?? [];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Header
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: photos.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: photos.first,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Colors.grey.shade200,
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported,
                              size: 60, color: Colors.grey),
                        ),
                      )
                    : Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image,
                            size: 60, color: Colors.grey),
                      ),
              ),
              // Status Chip
              Positioned(
                top: 12,
                left: 12,
                child: Chip(
                  backgroundColor: isActive ? Colors.green : Colors.redAccent,
                  label: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lab Name
                Text(
                  branch['lab_name'].toString().capitalizeFirst ??
                      'Unknown Lab',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 6),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 16, color: AppConstants.appPrimaryColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${branch['area'] ?? ''}, ${branch['city'] ?? ''}, ${branch['state'] ?? ''}',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Full Address
                Row(
                  children: [
                    const Icon(Icons.home, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        branch['lab_address'] ?? '',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Description
                if (branch['lab_description'] != null &&
                    branch['lab_description'].toString().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      branch['lab_description'],
                      style: const TextStyle(
                          fontSize: 13, height: 1.5, color: Colors.black87),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.appPrimaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDeactivate,
                        icon: const Icon(Icons.block,
                            size: 16, color: Colors.red),
                        label: Text(
                            branch['is_active'] == true
                                ? 'Deactivate'
                                : 'Activate',
                            style: const TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
