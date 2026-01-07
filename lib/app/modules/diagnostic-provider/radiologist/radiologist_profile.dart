// lib/app/modules/labs-provider/views/profile_tab.dart
// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../../constants/app_constants.dart';
import '../../../../utils/helper.dart';
import '../../../routes/app_pages.dart';
import '../diagnostics_provider_dashboard/controllers/radiologist_dashboard_controller.dart.dart';

class RadiologistProfile extends StatefulWidget {
  final RadiologistDashboardController controller;
  const RadiologistProfile({super.key, required this.controller});

  @override
  State<RadiologistProfile> createState() => _RadiologistProfileState();
}

class _RadiologistProfileState extends State<RadiologistProfile> {
  late TextEditingController firstNameCtrl;
  late TextEditingController lastNameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController birthdayCtrl;
  late TextEditingController bioCtrl;
  late TextEditingController addressCtrl;

  String? gender = 'Male';
  File? profileImage;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = widget.controller.userData;
    firstNameCtrl = TextEditingController(text: user['first_name'] ?? '');
    lastNameCtrl = TextEditingController(text: user['last_name'] ?? '');
    phoneCtrl = TextEditingController(text: user['phone_number'] ?? '');
    emailCtrl = TextEditingController(text: user['email'] ?? '');
    birthdayCtrl = TextEditingController(text: user['birthday'] ?? '');
    bioCtrl = TextEditingController(text: user['biography'] ?? '');
    addressCtrl = TextEditingController(text: user['address'] ?? '');
    gender = user['gender'] ?? 'Male';
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => profileImage = File(pickedFile.path));
    }
  }

  Future<void> updateProfile() async {
    if (isSaving) return;
    setState(() => isSaving = true);

    try {
      final token = await readStr('token');
      final userId = await readStr('user_id') ?? 1;

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('${AppConstants.endpoint}/users/$userId'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['first_name'] = firstNameCtrl.text.trim();
      request.fields['last_name'] = lastNameCtrl.text.trim();
      request.fields['phone_number'] = phoneCtrl.text.trim();
      request.fields['email'] = emailCtrl.text.trim();
      request.fields['gender'] = gender!;
      request.fields['birthday'] = birthdayCtrl.text.trim();
      request.fields['biography'] = bioCtrl.text.trim();
      request.fields['address'] = addressCtrl.text.trim();

      if (profileImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'profile_image',
          profileImage!.path,
        ));
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      print(respStr);

      if (response.statusCode == 200) {
        customToast('Profile updated successfully!', Colors.green);
        // widget.controller.fetchUserData(); // Refresh user data
      } else {
        customToast('Failed to update profile', Colors.red);
      }
    } catch (e) {
      customToast('Error: $e', Colors.red);
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.controller.userData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Picture
          Stack(
            children: [
              CircleAvatar(
                radius: 70,
                backgroundColor: AppConstants.appPrimaryColor.withOpacity(0.2),
                backgroundImage: profileImage != null
                    ? FileImage(profileImage!)
                    : (user['profile_image_name'] != null
                        ? NetworkImage(user['profile_image_name'])
                            as ImageProvider
                        : null),
                child:
                    profileImage == null && user['profile_image_name'] == null
                        ? Text(
                            '${firstNameCtrl.text.isNotEmpty ? firstNameCtrl.text[0] : 'P'}'
                            '${lastNameCtrl.text.isNotEmpty ? lastNameCtrl.text[0] : 'L'}',
                            style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.appPrimaryColor),
                          )
                        : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.appPrimaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            '${firstNameCtrl.text} ${lastNameCtrl.text}'.trim().isEmpty
                ? 'Pathologist'
                : '${firstNameCtrl.text} ${lastNameCtrl.text}'.trim(),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),

          Text(emailCtrl.text,
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppConstants.appPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('RAD${user['user_id'] ?? ''}',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.appPrimaryColor)),
          ),

          const SizedBox(height: 30),

          // Form Fields
          _buildTextField(firstNameCtrl, 'First Name', Icons.person),
          _buildTextField(lastNameCtrl, 'Last Name', Icons.person_outline),
          _buildTextField(phoneCtrl, 'Phone Number', Icons.phone,
              keyboardType: TextInputType.phone),
          _buildTextField(emailCtrl, 'Email', Icons.email,
              keyboardType: TextInputType.emailAddress),
          _buildTextField(birthdayCtrl, 'Birthday (YYYY-MM-DD)', Icons.cake,
              readOnly: true, onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              birthdayCtrl.text = picked.toString().split(' ')[0];
            }
          }),
          _buildDropdown(),
          _buildTextField(bioCtrl, 'Biography', Icons.info_outline,
              maxLines: 3),
          _buildTextField(addressCtrl, 'Address', Icons.home, maxLines: 2),

          const SizedBox(height: 15),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: isSaving ? null : updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.appPrimaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 5,
              ),
              child: isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Changes',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.fromLTRB(25, 3, 25, 0),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    'or',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  minimumSize: const Size(50, 50),
                  fixedSize: const Size(150, 50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo/ic_launcher.png',
                      width: 24.0,
                      height: 24.0,
                    ),
                    const SizedBox(width: 10.0),
                    const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboardType,
      int? maxLines = 1,
      bool readOnly = false,
      VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppConstants.appPrimaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: AppConstants.appPrimaryColor, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: gender,
        decoration: InputDecoration(
          labelText: 'Gender',
          prefixIcon: Icon(Icons.wc, color: AppConstants.appPrimaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: AppConstants.appPrimaryColor, width: 2),
          ),
        ),
        items: ['Male', 'Female', 'Other']
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (value) => setState(() => gender = value),
      ),
    );
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    birthdayCtrl.dispose();
    bioCtrl.dispose();
    addressCtrl.dispose();
    super.dispose();
  }
}
