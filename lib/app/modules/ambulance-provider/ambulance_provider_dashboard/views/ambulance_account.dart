// screens/ambulance/ambulance_account.dart
// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';
import '../../../../routes/app_pages.dart';
import '../../component/ambulance_bottom_navbar.dart';

class AmbulanceAccount extends StatefulWidget {
  const AmbulanceAccount({Key? key}) : super(key: key);

  @override
  State<AmbulanceAccount> createState() => _AmbulanceAccountState();
}

class _AmbulanceAccountState extends State<AmbulanceAccount> {
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

    try {
      final cached = await _loadFromLocalStorage();
      if (cached.isNotEmpty) {
        provider = cached['provider'];
        user = cached['user'];
        setState(() => isLoading = false);
        return;
      }
      await _fetchProviderProfile();
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      customToast('Failed to load profile', Colors.red);
    }
  }

  Future<Map<String, dynamic>> _loadFromLocalStorage() async {
    final name = await readStr('amb_provider_name');
    if (name == null || name.isEmpty) return {};

    return {
      'provider': {
        'registered_name': name,
        'amb_provider_logo': await readStr('amb_provider_logo') ??
            'https://via.placeholder.com/150',
        'license_number': await readStr('amb_license_number') ?? 'N/A',
        'emergency_contact_phone':
            await readStr('amb_emergency_contact') ?? 'N/A',
        'total_ambulances':
            int.tryParse(await readStr('amb_total_ambulances') ?? '0') ?? 0,
        'ambulance_types': jsonDecode(await readStr('amb_types') ?? '[]'),
        'operating_hours':
            jsonDecode(await readStr('amb_operating_hours') ?? '{}'),
        'pricing_details': jsonDecode(await readStr('amb_pricing') ?? '{}'),
        'rating': double.tryParse(await readStr('amb_rating') ?? '0') ?? 0.0,
      },
      'user': {
        'first_name': await readStr('amb_first_name') ?? '',
        'last_name': await readStr('amb_last_name') ?? '',
        'email': await readStr('amb_email') ?? '',
        'phone_number': await readStr('amb_phone') ?? '',
      }
    };
  }

  Future<void> _fetchProviderProfile() async {
    final profileId = await readStr('profileId');
    final token = await readStr('token') ?? '';

    final url = '${AppConstants.endpoint}/ambulances/providers/$profileId';

    try {
      final response = await http.get(
        Uri.parse(url),
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
          await saveStr('amb_provider_name', provider['registered_name'] ?? '');
          await saveStr(
              'amb_provider_logo', provider['amb_provider_logo'] ?? '');
          await saveStr('amb_license_number', provider['license_number'] ?? '');
          await saveStr('amb_emergency_contact',
              provider['emergency_contact_phone'] ?? '');
          await saveStr('amb_total_ambulances',
              (provider['total_ambulances'] ?? 0).toString());
          await saveStr(
              'amb_types', jsonEncode(provider['ambulance_types'] ?? []));
          await saveStr('amb_operating_hours',
              jsonEncode(provider['operating_hours'] ?? {}));
          await saveStr(
              'amb_pricing', jsonEncode(provider['pricing_details'] ?? {}));
          await saveStr('amb_rating', (provider['rating'] ?? 0).toString());

          // User data
          await saveStr('amb_first_name', user['first_name'] ?? '');
          await saveStr('amb_last_name', user['last_name'] ?? '');
          await saveStr('amb_email', user['email'] ?? '');
          await saveStr('amb_phone', user['phone_number'] ?? '');
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
        Get.toNamed(Routes.AMBULANCE_PROVIDER_DASHBOARD);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: AppConstants.appPrimaryColor,
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
            ? const Center(child: CircularProgressIndicator())
            : hasError
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: _loadProviderData,
                    child: _buildBody(),
                  ),
        bottomNavigationBar: const AmbulanceProviderBottomNavBar(index: 4),
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
          const SizedBox(height: 8),
          _buildMenuSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final logo =
        provider['amb_provider_logo'] ?? 'https://via.placeholder.com/150';
    final name = provider['registered_name'] ?? 'Ambulance Provider';
    final license = provider['license_number'] ?? 'N/A';
    final contact = provider['emergency_contact_phone'] ?? 'N/A';
    final totalAmbulances = provider['total_ambulances'] ?? 0;
    final rating = (provider['rating'] ?? 0).toDouble();

    final types = List<String>.from(provider['ambulance_types'] ?? []);
    final pricing =
        Map<String, dynamic>.from(provider['pricing_details'] ?? {});
    final hours = Map<String, dynamic>.from(provider['operating_hours'] ?? {});

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
              const SizedBox(width: 0),
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
              _infoBox("Total Ambulances", totalAmbulances.toString(),
                  Icons.directions_car),
              _infoBox(
                  "Types Offered", types.length.toString(), Icons.category),
              _infoBox(rating > 0 ? rating.toStringAsFixed(1) : "Unrated",
                  rating > 0 ? "★" : "-", Icons.star),
            ],
          ),
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
            onTap: () => Get.toNamed(Routes.AMBULANCE_PROVIDER_REGISTRATION,
                arguments: {"type": "update"}),
          ),
          _buildMenuTile(
              icon: Icons.password_outlined,
              title: "Change Password",
              onTap: _showChangePasswordDialog),
          _buildMenuTile(
              icon: Icons.support_agent_outlined,
              title: "Support",
              onTap: () {}),
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

  Widget _buildMenuTile(
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      bool isLogout = false}) {
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
