// ignore_for_file: deprecated_member_use
import 'package:aidxpert_business/constants/app_constants.dart';
import 'package:aidxpert_business/utils/helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../controllers/sales_controller.dart';

class SalesDashboard extends StatelessWidget {
  SalesDashboard({super.key});

  final controller = Get.put(SalesController());

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => await onWillPop(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: AppConstants.appPrimaryColor,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          centerTitle: true,
          elevation: 0,
          title: Image.asset(
            'assets/logo/logo.png',
            height: 120,
            width: 120,
            color: Colors.white,
          ),
          shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(60),
              bottomRight: Radius.circular(60),
            ),
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value && controller.dashboardData.isEmpty) {
            return Center(child: loading);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.98,
                  children: [
                    _buildModernCard(
                        title: "Total Users",
                        value:
                            controller.dashboardData['TotalUsers'].toString(),
                        icon: Icons.people_alt_rounded,
                        baseColor: Colors.deepPurple,
                        onTap: () {
                          controller
                              .fetchUsersByRole(getProviderType("Total Users"));
                          Get.toNamed(Routes.PROVIDER_LIST,
                              arguments: 'Total Users');
                        }),
                    _buildModernCard(
                        title: "Total Doctors",
                        value:
                            controller.dashboardData['TotalDoctors'].toString(),
                        icon: Icons.medical_services_rounded,
                        baseColor: Colors.blue,
                        onTap: () {
                          controller
                              .fetchUsersByRole(getProviderType("Doctors"));
                          Get.toNamed(Routes.PROVIDER_LIST,
                              arguments: 'Doctors');
                        }),
                    _buildModernCard(
                        title: "Total Patients",
                        value: controller.dashboardData['TotalPatients']
                            .toString(),
                        icon: Icons.sentiment_satisfied_alt_rounded,
                        baseColor: Colors.orange,
                        onTap: () {
                          controller
                              .fetchUsersByRole(getProviderType("Patients"));
                          Get.toNamed(Routes.PROVIDER_LIST,
                              arguments: 'Patients');
                        }),
                    _buildModernCard(
                        title: "Total Lab Providers",
                        value: controller
                            .dashboardData['TotalLabServiceProviders']
                            .toString(),
                        icon: Icons.science_rounded,
                        baseColor: Colors.teal,
                        onTap: () {
                          controller.fetchUsersByRole(
                              getProviderType("Lab Providers"));
                          Get.toNamed(Routes.PROVIDER_LIST,
                              arguments: 'Lab Service Provider');
                        }),
                    _buildModernCard(
                        title: "Total Diagnostics",
                        value: controller
                            .dashboardData['TotalDiagnosticsProviders']
                            .toString(),
                        icon: Icons.monitor_heart_rounded,
                        baseColor: Colors.indigo,
                        onTap: () {
                          controller.fetchUsersByRole(
                              getProviderType("Diagnostic Providers"));
                          Get.toNamed(Routes.PROVIDER_LIST,
                              arguments: 'Diagnostics Service Provider');
                        }),
                    _buildModernCard(
                        title: "Total Ambulance",
                        value: controller
                            .dashboardData['TotalAmbulanceServiceProviders']
                            .toString(),
                        icon: Icons.airport_shuttle_rounded,
                        baseColor: Colors.redAccent,
                        onTap: () {
                          controller.fetchUsersByRole(
                              getProviderType("Ambulances Providers"));
                          Get.toNamed(Routes.PROVIDER_LIST,
                              arguments: 'Ambulance Service Provider');
                        }),
                    _buildModernCard(
                        title: "Total Caretakers",
                        value: controller
                            .dashboardData['TotalCaretakerServiceProviders']
                            .toString(),
                        icon: Icons.elderly_rounded,
                        baseColor: Colors.pinkAccent,
                        onTap: () {
                          controller.fetchUsersByRole(
                              getProviderType("Caretakers Providers"));
                          Get.toNamed(Routes.PROVIDER_LIST,
                              arguments: 'Caretaker Service Provider');
                        }),
                    _buildLogoutCard(),
                  ],
                )
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Modern Stat Card Design
  Widget _buildModernCard({
    required String title,
    required String value,
    required IconData icon,
    required Color baseColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // ClipRRect ensures the large background icon doesn't spill out
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  icon,
                  size: 100,
                  color: baseColor.withOpacity(0.08),
                ),
              ),

              // 2. Main Content
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon Container
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: baseColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        color: baseColor,
                        size: 26,
                      ),
                    ),

                    const Spacer(),

                    // Count Value
                    Text(
                      value == 'null' || value.isEmpty ? "0" : value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Title Label
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                          height: 1.1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Specialized Logout Card Design
  Widget _buildLogoutCard() {
    return GestureDetector(
      onTap: () {
        Get.defaultDialog(
          title: "Logout",
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
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
      child: Container(
        decoration: BoxDecoration(
          // Subtle red gradient for logout to make it distinct
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade50,
              Colors.red.shade100.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(Icons.logout_rounded,
                  size: 28, color: Colors.redAccent),
            ),
            const SizedBox(height: 12),
            const Text(
              "Logout",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getProviderType(String title) {
    switch (title) {
      case "Doctors":
        return "Doctor";
      case "Patients":
        return "Patient";
      case "Ambulances Providers":
      case "Ambulance":
        return "Ambulance Service Provider";
      case "Lab Providers":
        return "Lab Service Provider";
      case "Diagnostic Providers":
      case "Diagnostics":
        return "Diagnostics Service Provider";
      case "Caretakers Providers":
      case "Caretakers":
        return "Caretaker Service Provider";
      default:
        return title;
    }
  }
}
