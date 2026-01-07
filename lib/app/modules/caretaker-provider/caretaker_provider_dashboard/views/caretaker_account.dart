// screens/caretaker/caretaker_account.dart
// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';
import '../../../../routes/app_pages.dart';
import '../../component/caretaker_bottom_navbar.dart';

class CaretakerAccount extends StatefulWidget {
  const CaretakerAccount({Key? key}) : super(key: key);

  @override
  State<CaretakerAccount> createState() => _CaretakerAccountState();
}

class _CaretakerAccountState extends State<CaretakerAccount> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Map<String, dynamic> provider = {};
  Map<String, dynamic> user = {};
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    await _fetchProviderProfile();
  }

  Future<void> _fetchProviderProfile() async {
    final profileId = await readStr('profileId');
    final token = await readStr('token') ?? '';
    if (profileId == null) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.endpoint}/caretakers/providers/$profileId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['status'] == true) {
          provider = res['provider'];
          user = provider['user'] ?? {};

          // Save to local storage
          await saveStr(
              'caretaker_provider_name', provider['provider_name'] ?? '');
          await saveStr('caretaker_logo', provider['caretaker_logo'] ?? '');
          await saveStr('caretaker_license', provider['license_number'] ?? '');
          await saveStr('caretaker_emergency_contact',
              provider['emergency_contact_phone'] ?? '');
          await saveStr('caretaker_total',
              (provider['total_caretakers'] ?? 0).toString());
          await saveStr(
              'caretaker_types', jsonEncode(provider['caretaker_types'] ?? []));
          await saveStr('caretaker_specialization',
              jsonEncode(provider['specialization_areas'] ?? []));
          await saveStr('caretaker_accreditation',
              jsonEncode(provider['accreditation'] ?? []));
          await saveStr(
              'caretaker_rating', (provider['rating'] ?? 0).toString());

          // User data
          await saveStr('caretaker_first_name', user['first_name'] ?? '');
          await saveStr('caretaker_last_name', user['last_name'] ?? '');
          await saveStr('caretaker_email', user['email'] ?? '');
          await saveStr('caretaker_phone', user['phone_number'] ?? '');
        } else {
          throw Exception(res['message']);
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    EasyLoading.show(status: 'Changing Password...');
    final userId = await readStr('user_id');
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.endpoint}/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await readStr('token')}',
        },
        body: jsonEncode({
          "userId": int.tryParse(userId ?? '0') ?? 0,
          "oldPassword": _oldPasswordController.text,
          "newPassword": _newPasswordController.text,
          "confirmPassword": _confirmPasswordController.text,
        }),
      );

      final res = json.decode(response.body);
      if (response.statusCode == 200 && res['status'] == true) {
        customToast('Password changed successfully.', Colors.green);
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        Get.back();
      } else {
        customToast(
            'Failed: ${res['message'] ?? 'Invalid credentials'}', Colors.red);
      }
    } catch (e) {
      customToast('Error: $e', Colors.red);
    } finally {
      EasyLoading.dismiss();
    }
  }

  void _showChangePasswordDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(_oldPasswordController, 'Old Password'),
                const SizedBox(height: 12),
                _buildTextField(_newPasswordController, 'New Password'),
                const SizedBox(height: 12),
                _buildTextField(_confirmPasswordController, 'Confirm Password'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_newPasswordController.text ==
                      _confirmPasswordController.text &&
                  _newPasswordController.text.isNotEmpty) {
                _changePassword();
              } else {
                customToast('Passwords do not match', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.appPrimaryColor),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.toNamed(Routes.CARETAKER_PROVIDER_DASHBOARD);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: AppConstants.appPrimaryColor,
          automaticallyImplyLeading: false,
          elevation: 0,
          title: const Text("My Account",
              style: TextStyle(color: Colors.white, fontSize: 20)),
          centerTitle: true,
          shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50)),
          ),
        ),
        body: isLoading
            ? Center(child: loading)
            : hasError
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: _loadProviderData,
                    child: _buildBody(),
                  ),
        bottomNavigationBar: const CaretakerProviderBottomNavBar(index: 3),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Failed to load profile', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _loadProviderData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildProfileHeader(),
          _buildMenuSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final logo =
        provider['caretaker_logo'] ?? 'https://via.placeholder.com/150';
    final name = provider['provider_name'] ?? 'Caretaker Provider';
    final license = provider['license_number'] ?? 'N/A';
    final contact = provider['emergency_contact_phone'] ?? 'N/A';
    final totalCaretakers = provider['total_caretakers'] ?? 0;
    final rating = (provider['rating'] ?? 0).toDouble();

    final types = List<String>.from(provider['caretaker_types'] ?? []);
    final specializations =
        List<String>.from(provider['specialization_areas'] ?? []);
    final accreditations = List<String>.from(provider['accreditation'] ?? []);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  logo,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 90,
                    height: 90,
                    color: Colors.grey[300],
                    child: const Icon(Icons.business, size: 40),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 21, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.local_phone,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(contact, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text("License: $license",
                        style: const TextStyle(
                            fontSize: 13.5, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoBox("Total Caretakers", totalCaretakers.toString(),
                  Icons.people_alt),
              _infoBox("Service Types", types.length.toString(),
                  Icons.medical_services),
              _infoBox(rating > 0 ? rating.toStringAsFixed(1) : "Unrated",
                  rating > 0 ? "★" : "-", Icons.star),
            ],
          ),
          if (specializations.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text("Specializations",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: specializations
                  .map((s) => Chip(
                        label: Text(s, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.blue.shade50,
                      ))
                  .toList(),
            ),
          ],
          if (accreditations.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text("Accreditations",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: accreditations
                  .map((a) => Chip(
                        label: Text(a, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.green.shade50,
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoBox(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28, color: AppConstants.appPrimaryColor),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          _buildMenuTile(
            icon: Icons.edit_outlined,
            title: "Edit Profile",
            onTap: () => Get.toNamed(Routes.CARETAKER_PROVIDER_REGISTRATION,
                arguments: {"type": "update"}),
          ),
          _buildMenuTile(
            icon: Icons.password_outlined,
            title: "Change Password",
            onTap: _showChangePasswordDialog,
          ),
          _buildMenuTile(
            icon: Icons.support_agent_outlined,
            title: "Support",
            onTap: () {},
          ),
          const Divider(height: 40),
          _buildMenuTile(
            icon: Icons.exit_to_app_outlined,
            title: "Log Out",
            onTap: () async => Get.defaultDialog(
              title: "Logout",
              titleStyle: const TextStyle(fontWeight: FontWeight.bold),
              middleText: "Are you sure you want to logout?",
              textCancel: "Cancel",
              textConfirm: "Logout",
              contentPadding: const EdgeInsets.all(15),
              confirmTextColor: Colors.white,
              buttonColor: Colors.redAccent,
              cancelTextColor: Colors.black54,
              radius: 16,
              onConfirm: () async {
                await clearAllStore();
                Get.offAllNamed(Routes.ONBOARDING);
              },
            ),
            isLogout: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Card(
      elevation: 1,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
        leading: Icon(icon,
            color: isLogout ? Colors.red : AppConstants.appPrimaryColor,
            size: 28),
        title: Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: isLogout ? FontWeight.bold : FontWeight.w500,
                color: isLogout ? Colors.red : Colors.black87)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
