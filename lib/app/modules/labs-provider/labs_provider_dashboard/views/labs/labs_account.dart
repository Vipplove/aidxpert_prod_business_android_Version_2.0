// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../../../../constants/app_constants.dart';
import '../../../../../../utils/helper.dart';
import '../../../../../routes/app_pages.dart';
import '../../../component/lab_bottom_navbar.dart';
import 'labs_price_table.dart';

class LabAccount extends StatefulWidget {
  const LabAccount({Key? key}) : super(key: key);

  @override
  State<LabAccount> createState() => _LabAccountState();
}

class _LabAccountState extends State<LabAccount> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Provider data (cached)
  Map<String, dynamic> provider = {};
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  // Load from local → fallback to API
  Future<void> _loadProviderData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      // Try to load from local storage first
      final cached = await _loadFromLocalStorage();
      if (cached.isNotEmpty) {
        provider = cached;
        setState(() => isLoading = false);
        return;
      }

      // If not in cache, fetch from API
      await _fetchProviderProfile();
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      customToast('Failed to load profile', Colors.red);
    }
  }

  // Load all provider data from SharedPreferences
  Future<Map<String, dynamic>> _loadFromLocalStorage() async {
    final name = await readStr('provider_name');
    if (name == null || name.isEmpty) return {};

    final bankDetailsJson = await readStr('bank_details');
    final accreditationJson = await readStr('accreditation');

    return {
      'provider_name': name,
      'logo': (await readStr('logo')) ?? 'https://via.placeholder.com/150',
      'gst_number': (await readStr('gst_number')) ?? 'N/A',
      'pan_number': (await readStr('pan_number')) ?? 'N/A',
      'license_number': (await readStr('license_number')) ?? 'N/A',
      'address': (await readStr('address')) ?? '',
      'city': (await readStr('city')) ?? '',
      'state': (await readStr('state')) ?? '',
      'zip_code': (await readStr('zip_code')) ?? '',
      'rating': double.tryParse(await readStr('rating') ?? '0') ?? 0.0,
      'bank_details':
          bankDetailsJson != null ? jsonDecode(bankDetailsJson) : {},
      'accreditation':
          accreditationJson != null ? jsonDecode(accreditationJson) : [],
    };
  }

  // Fetch from API and save to local
  Future<void> _fetchProviderProfile() async {
    final profileId = await readStr('profileId');
    final token = await readStr('token') ?? '';
    final url = '${AppConstants.endpoint}/labs/providers/$profileId';

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

          // Save to local storage
          await saveStr('provider_name', provider['provider_name'] ?? '');
          await saveStr('gst_number', provider['gst_number'] ?? '');
          await saveStr('pan_number', provider['pan_number'] ?? '');
          await saveStr('license_number', provider['license_number'] ?? '');
          await saveStr(
              'logo', provider['logo'] ?? 'https://via.placeholder.com/150');
          await saveStr(
              'bank_details', jsonEncode(provider['bank_details'] ?? {}));
          await saveStr('address', provider['address'] ?? '');
          await saveStr('city', provider['city'] ?? '');
          await saveStr('state', provider['state'] ?? '');
          await saveStr('zip_code', provider['zip_code'] ?? '');
          await saveStr(
              'accreditation', jsonEncode(provider['accreditation'] ?? []));
          await saveStr('rating', (provider['rating'] ?? 0).toString());
        } else {
          throw Exception(res['message']);
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Change Password
  Future<void> _changePassword() async {
    EasyLoading.show(status: 'Changing Password...');
    final userId = await readStr('user_id');
    final response = await http.put(
      Uri.parse('${AppConstants.endpoint}/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await readStr('token')}',
      },
      body: jsonEncode({
        "userId": int.parse(userId),
        "oldPassword": _oldPasswordController.text,
        "newPassword": _newPasswordController.text,
        "confirmPassword": _confirmPasswordController.text,
      }),
    );

    if (response.statusCode == 200) {
      customToast('Password changed successfully.', Colors.green);
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      Get.back();
    } else {
      final res = jsonDecode(response.body);
      customToast('Failed: ${res['message']}', Colors.red);
    }
    EasyLoading.dismiss();
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
        Get.toNamed(Routes.LABS_PROVIDER_DASHBOARD);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: AppConstants.appPrimaryColor,
          elevation: 0,
          title: const Text("My Lab Account",
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
                : _buildBody(),
        bottomNavigationBar: const LabProviderBottomNavBar(index: 4),
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
            onPressed: _loadProviderData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildProfileHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildMenuTile(
                icon: Icons.health_and_safety_outlined,
                title: "Edit Profile",
                onTap: () => Get.toNamed(
                  Routes.LABS_PROVIDER_REGISTRATION,
                  arguments: {'type': 'update'},
                ),
              ),
              _buildMenuTile(
                icon: Icons.schedule_outlined,
                title: "Schedule Timings",
                onTap: () => Get.to(() => const LabPriceTable()),
              ),
              _buildMenuTile(
                icon: Icons.note_alt_outlined,
                title: "Patient Reports",
                onTap: () => Get.toNamed(Routes.LABS_REPORTS),
              ),
              _buildMenuTile(
                icon: Icons.receipt_long_outlined,
                title: "Download Invoices",
                onTap: () => Get.toNamed(Routes.LABS_INVOICES),
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
              const Divider(height: 32),
              _buildMenuTile(
                icon: Icons.exit_to_app_outlined,
                title: "Log Out",
                onTap: () async => Get.defaultDialog(
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
                ),
                isLogout: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Practo-style Header
  Widget _buildProfileHeader() {
    final logo = provider['logo'] ?? 'https://via.placeholder.com/150';
    final name = provider['provider_name'] ?? 'Your Lab';
    final address = [
      provider['address'] ?? '',
      provider['city'] ?? '',
      provider['state'] ?? '',
      provider['zip_code'] ?? ''
    ].where((e) => e.isNotEmpty).join(', ');
    final gst = provider['gst_number'] ?? 'N/A';
    final pan = provider['pan_number'] ?? 'N/A';
    final license = provider['license_number'] ?? 'N/A';
    final rating = (provider['rating'] ?? 0).toDouble();
    final accreditation = List<String>.from(provider['accreditation'] ?? []);

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
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Logo
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          fontSize: 21, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address.isEmpty ? 'Address not set' : address,
                            style: const TextStyle(
                                fontSize: 13.5, color: Colors.grey),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Accreditation
                    if (accreditation.isNotEmpty)
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: accreditation.take(3).map((acc) {
                          return Chip(
                            label: Text(acc,
                                style: const TextStyle(fontSize: 10.5)),
                            backgroundColor: Colors.green.shade50,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(color: Colors.green.shade200),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.grey),
          const SizedBox(height: 10),
          // GST / PAN / License
          Row(
            children: [
              Expanded(child: _infoChip('GST', gst)),
              const SizedBox(width: 12),
              Expanded(child: _infoChip('PAN', pan)),
              const SizedBox(width: 12),
              Expanded(child: _infoChip('License', license)),
            ],
          ),
          const SizedBox(height: 10),
          // Rating
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 6),
              Text(
                rating > 0 ? '$rating ★ (Rated)' : 'Not rated yet',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: rating > 0 ? Colors.black87 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon,
            color: isLogout ? Colors.red : AppConstants.appPrimaryColor,
            size: 26),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: isLogout ? FontWeight.bold : FontWeight.w500,
            color: isLogout ? Colors.red : Colors.black87,
          ),
        ),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
