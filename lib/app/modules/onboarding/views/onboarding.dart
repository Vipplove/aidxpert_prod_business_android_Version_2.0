// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../constants/app_constants.dart';
import '../../../../utils/helper.dart';
import '../../../routes/app_pages.dart';

class Onboarding extends StatelessWidget {
  const Onboarding({super.key});

  // Admin role options
  final List<Map<String, String>> adminRoles = const [
    {'title': 'Support Login', 'value': 'support'},
    {'title': 'Sale Login', 'value': 'sale'},
    {'title': 'Admin Login', 'value': 'admin'},
  ];

  // Show admin selection dialog
  void _showAdminRoleDialog(BuildContext context) {
    String? selectedRole = 'admin'; // default

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings,
                color: AppConstants.appPrimaryColor),
            const SizedBox(width: 10),
            const Text('Select Admin Role'),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: adminRoles.map((role) {
              return RadioListTile<String>(
                title: Text(
                  role['title']!,
                  style: const TextStyle(fontSize: 16),
                ),
                value: role['value']!,
                groupValue: selectedRole,
                activeColor: AppConstants.appPrimaryColor,
                onChanged: (value) {
                  setState(() {
                    selectedRole = value;
                  });
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.appPrimaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Get.toNamed(Routes.LOGIN, arguments: selectedRole);
            },
            child:
                const Text('Continue', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => await onWillPop(context),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),

              // Logo
              Image.asset(
                'assets/logo/logo.png',
                width: 180,
                color: AppConstants.appPrimaryColor,
              ),
              const SizedBox(height: 15),

              // Title
              Text(
                'Select Your Role',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.appPrimaryColor,
                ),
              ),
              const SizedBox(height: 15),

              // 2x3 Grid (6 items)
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: [
                    _buildGridItem(
                      icon: 'assets/image/blood-test.png',
                      title: 'Labs Provider',
                      onTap: () => Get.toNamed(Routes.LOGIN, arguments: 'Labs'),
                    ),
                    _buildGridItem(
                      icon: 'assets/image/ct-scan.png',
                      title: 'Diagnostic Provider',
                      onTap: () =>
                          Get.toNamed(Routes.LOGIN, arguments: 'Diagnostic'),
                    ),
                    _buildGridItem(
                      icon: 'assets/image/ambulance.png',
                      title: 'Ambulance Provider',
                      onTap: () =>
                          Get.toNamed(Routes.LOGIN, arguments: 'Ambulance'),
                    ),
                    _buildGridItem(
                      icon: 'assets/image/caretaker.png',
                      title: 'Caretaker Login',
                      onTap: () =>
                          Get.toNamed(Routes.LOGIN, arguments: 'Admin'),
                    ),
                    _buildGridItem(
                      icon: 'assets/image/integrity.png',
                      title: 'Insurance Agent',
                      onTap: () =>
                          Get.toNamed(Routes.LOGIN, arguments: 'agent'),
                    ),
                    // ADMIN LOGIN → Show Dialog
                    _buildGridItem(
                      icon: 'assets/image/person.png',
                      title: 'Admin Login',
                      onTap: () => _showAdminRoleDialog(context),
                    ),
                  ],
                ),
              ),

              // Footer text
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'Powered by AidXpert © 2025',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shadowColor: AppConstants.appPrimaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppConstants.appPrimaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppConstants.appPrimaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppConstants.appPrimaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    icon,
                    width: 38,
                    height: 38,
                    color: AppConstants.appPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                  letterSpacing: 0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
