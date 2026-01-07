import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';

class LabsProviderRegistrationController extends GetxController {
  // ===================== FORM CONTROLLERS =====================
  final providerNameController = TextEditingController();
  final gstController = TextEditingController();
  final panController = TextEditingController();
  final licenseController = TextEditingController();
  final expiryController = TextEditingController();
  final accountNoController = TextEditingController();
  final ifscController = TextEditingController();
  final upiController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final zipController = TextEditingController();
  final countryController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();

  // NEW: Account Registration Fields
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // ===================== REACTIVE VARIABLES =====================
  var logoPath = ''.obs;
  var certificationFiles = <String>[].obs;
  var selectedAccreditations = <String>[].obs;
  var isLoading = false.obs;
  var isLoadingLocation = false.obs;

  // Validation States
  var isAccountNoValid = false.obs;
  var accountNoErrorMessage = ''.obs;
  var isIfscValid = false.obs;
  var ifscErrorMessage = ''.obs;
  var isUpiValid = false.obs;
  var upiErrorMessage = ''.obs;
  var bankName = ''.obs;
  var isFetchingBank = false.obs;

  var selectedStatus = 'pending'.obs;
  var hasLoaded = false;

  final Map<String, Map<String, String>> _ifscCache = {};

  final List<String> _validUpiProviders = [
    'upi',
    'ybl',
    'okaxis',
    'oksbi',
    'okicici',
    'okhdfcbank',
    'apl',
    'axl',
    'ibl',
    'freecharge',
    'phonepe',
    'paytm',
    'amazonpay',
    'bharatpe',
    'whatsapp',
    'googlepay',
    'gpay'
  ];

  @override
  void onInit() {
    super.onInit();
    accountNoController.addListener(_validateAccountNoRealTime);
    ifscController.addListener(_validateAndFetchIfsc);
    upiController.addListener(_validateUpiRealTime);
  }

  @override
  void onClose() {
    accountNoController.removeListener(_validateAccountNoRealTime);
    ifscController.removeListener(_validateAndFetchIfsc);
    upiController.removeListener(_validateUpiRealTime);

    // Dispose all controllers
    for (var c in [
      providerNameController,
      gstController,
      panController,
      licenseController,
      expiryController,
      accountNoController,
      ifscController,
      upiController,
      addressController,
      cityController,
      stateController,
      zipController,
      countryController,
      latitudeController,
      longitudeController,
      phoneController,
      emailController,
      passwordController
    ]) {
      c.dispose();
    }

    super.onClose();
  }

  // ===================== NEW: FULL REGISTRATION FLOW =====================
  Future<void> registerAndContinue() async {
    if (!_validateForm(isNewRegistration: true)) return;

    isLoading.value = true;
    update(['labs-form']);

    try {
      // Step 1: Register User Account
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.endpoint}/users'),
      );

      request.fields.addAll({
        'first_name': providerNameController.text.trim(),
        'phone_number': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
        'role_id': '5',
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ Correct provider_id extraction based on API response
        final String? providerId =
            jsonResponse['profile_id']?['provider_id']?.toString() ??
                jsonResponse['user']?['user_id']?.toString();

        if (providerId == null || providerId.isEmpty) {
          customToast(
            'Account created but provider ID not received. Contact support.',
            Colors.orange,
          );
          return;
        }

        await saveStr('profileId', providerId);

        await _completeProfileSetup(providerId);
      } else {
        final errorMsg = jsonResponse['message'] ?? 'Registration failed';
        customToast(errorMsg);
      }
    } catch (e) {
      print('Registration Error: $e');
      customToast('Network error. Please try again.');
    } finally {
      isLoading.value = false;
      update(['labs-form']);
    }
  }

  // Reusable method to upload lab details after registration
  Future<void> _completeProfileSetup(providerId) async {
    try {
      final token = await readStr('token');
      if (token == null) {
        customToast('Authentication failed.');
        return;
      }

      final uri =
          Uri.parse('${AppConstants.endpoint}/labs/providers/$providerId');
      final request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields.addAll({
        'provider_name': providerNameController.text.trim(),
        'gst_number': gstController.text.trim(),
        'pan_number': panController.text.trim(),
        'license_number': licenseController.text.trim(),
        'license_expiry': expiryController.text,
        'bank_details': _buildBankJson(),
        'accreditation': jsonEncode(selectedAccreditations),
        'address': addressController.text.trim(),
        'city': cityController.text.trim(),
        'state': stateController.text.trim(),
        'zip_code': zipController.text.trim(),
        'country': 'India',
        'latitude': latitudeController.text.trim(),
        'longitude': longitudeController.text.trim(),
        'approval_status': 'pending',
      });

      print(request.fields);

      // Upload logo if selected
      if (logoPath.value.isNotEmpty && !logoPath.value.startsWith('http')) {
        request.files
            .add(await http.MultipartFile.fromPath('logo', logoPath.value));
      }

      // Upload certification documents
      for (String file
          in certificationFiles.where((f) => !f.startsWith('http'))) {
        request.files.add(
            await http.MultipartFile.fromPath('certification_documents', file));
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        customToast('Lab registration completed successfully!', Colors.green);
        Get.back();
      } else {
        final resp = await response.stream.bytesToString();
        customToast('Failed to save lab details. Please try again.');
        print(resp);
      }
    } catch (e) {
      customToast('Error completing registration: $e');
    }
  }

  // ===================== EXISTING: UPDATE PROFILE =====================
  Future<void> updateProvider() async {
    if (!_validateForm(isNewRegistration: false)) return;

    isLoading.value = true;
    update(['labs-form']);

    try {
      final token = await readStr('token');
      final String? id = await readStr('profileId');

      if (token == null || id == null) {
        customToast('Session expired. Please login again.');
        return;
      }

      final uri = Uri.parse('${AppConstants.endpoint}/labs/providers/$id');
      final request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields.addAll({
        'provider_name': providerNameController.text.trim(),
        'gst_number': gstController.text.trim(),
        'pan_number': panController.text.trim(),
        'bank_details': _buildBankJson(),
        'accreditation': jsonEncode(selectedAccreditations),
        'license_number': licenseController.text.trim(),
        'license_expiry': expiryController.text,
        'address': addressController.text.trim(),
        'city': cityController.text.trim(),
        'state': stateController.text.trim(),
        'zip_code': zipController.text.trim(),
        'country': 'India',
        'latitude': latitudeController.text.trim(),
        'longitude': longitudeController.text.trim(),
      });

      // Only sales/admin can change status
      final role = await readStr('roleType');
      if (role == 'Sales' || role == 'Admin') {
        request.fields['approval_status'] = selectedStatus.value;
      }

      if (logoPath.value.isNotEmpty && !logoPath.value.startsWith('http')) {
        request.files
            .add(await http.MultipartFile.fromPath('logo', logoPath.value));
      }

      for (String file
          in certificationFiles.where((f) => !f.startsWith('http'))) {
        request.files.add(
            await http.MultipartFile.fromPath('certification_documents', file));
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        customToast('Profile updated successfully!', Colors.green);
        Get.back();
      } else {
        customToast('Update failed. Try again.');
      }
    } catch (e) {
      customToast('Error: $e');
    } finally {
      isLoading.value = false;
      update(['labs-form']);
    }
  }

  // ===================== LOAD EXISTING DATA (Update Mode) =====================
  Future<void> loadUpdateDataFromApi(String labId) async {
    if (hasLoaded) return;
    hasLoaded = true;

    String? id = labId.isEmpty ? await readStr('profileId') : labId;
    if (id == null || id.isEmpty) {
      customToast('Invalid Lab ID');
      return;
    }

    try {
      final res = await http
          .get(Uri.parse('${AppConstants.endpoint}/labs/providers/$id'));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body)['provider'];

        providerNameController.text = json['provider_name'] ?? '';
        gstController.text = json['gst_number'] ?? '';
        panController.text = json['pan_number'] ?? '';
        licenseController.text = json['license_number'] ?? '';
        expiryController.text = (json['license_expiry'] ?? '').split('T')[0];

        final bank = json['bank_details'] ?? {};
        accountNoController.text = bank['account_no'] ?? '';
        ifscController.text = (bank['ifsc'] ?? '').toString().toUpperCase();
        upiController.text = bank['upi'] ?? '';

        addressController.text = json['address'] ?? '';
        cityController.text = json['city'] ?? '';
        stateController.text = json['state'] ?? '';
        zipController.text = json['zip_code'] ?? '';
        latitudeController.text = json['latitude']?.toString() ?? '';
        longitudeController.text = json['longitude']?.toString() ?? '';

        logoPath.value = json['logo'] ?? '';
        selectedAccreditations.value =
            List<String>.from(json['accreditation'] ?? []);
        certificationFiles.value =
            List<String>.from(json['certification_documents'] ?? []);
        selectedStatus.value = json['approval_status'] ?? 'pending';

        update(['labs-form']);
      }
    } catch (e) {
      customToast('Failed to load data');
    } finally {
      update(['labs-form']);
    }
  }

  // ===================== VALIDATIONS =====================
  void _validateAccountNoRealTime() {
    final acc = accountNoController.text.trim();
    final clean = acc.replaceAll(RegExp(r'\D'), '');
    if (acc != clean) {
      accountNoController.value = TextEditingValue(
          text: clean,
          selection: TextSelection.collapsed(offset: clean.length));
    }
    final length = clean.length;
    final valid = length >= 9 && length <= 18;
    isAccountNoValid.value = valid;
    accountNoErrorMessage.value =
        valid ? '' : (length < 9 ? 'Minimum 9 digits' : 'Maximum 18 digits');
    update(['labs-form']);
  }

  String? validateAccountNo(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final clean = v.trim().replaceAll(RegExp(r'\D'), '');
    return clean.length >= 9 && clean.length <= 18 ? null : '9–18 digits only';
  }

  void _validateAndFetchIfsc() {
    final ifsc = ifscController.text.trim().toUpperCase();
    ifscController.value = TextEditingValue(
        text: ifsc, selection: TextSelection.collapsed(offset: ifsc.length));

    if (ifsc.isEmpty) {
      _resetIfscState();
      return;
    }

    final validFormat = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc);
    isIfscValid.value = validFormat;

    if (!validFormat) {
      ifscErrorMessage.value = 'Invalid IFSC format';
      bankName.value = '';
      return;
    }

    ifscErrorMessage.value = '';
    _fetchIfscDetails(ifsc);
  }

  Future<void> _fetchIfscDetails(String ifsc) async {
    if (_ifscCache.containsKey(ifsc)) {
      _applyIfscData(_ifscCache[ifsc]!);
      return;
    }

    isFetchingBank.value = true;
    bankName.value = '';

    try {
      final res = await http.get(Uri.parse('https://ifsc.razorpay.com/$ifsc'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final result = {
          'bank':
              '${data['BANK'] ?? 'Unknown'} - ${data['BRANCH'] ?? ''}'.trim(),
          'city': data['CITY'] ?? '',
          'state': data['STATE'] ?? '',
        } as Map<String, String>;
        _ifscCache[ifsc] = result;
        _applyIfscData(result);
      } else {
        bankName.value = 'Invalid IFSC Code';
      }
    } catch (e) {
      bankName.value = 'Failed to fetch bank';
    } finally {
      isFetchingBank.value = false;
      update(['labs-form']);
    }
  }

  void _applyIfscData(Map<String, String> data) {
    bankName.value = data['bank'] ?? '';
    if (cityController.text.trim().isEmpty) {
      cityController.text = data['city'] ?? '';
    }
    if (stateController.text.trim().isEmpty) {
      stateController.text = data['state'] ?? '';
    }
  }

  void _resetIfscState() {
    isIfscValid.value = false;
    ifscErrorMessage.value = '';
    bankName.value = '';
    isFetchingBank.value = false;
  }

  String? validateIfsc(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(v.trim().toUpperCase())
        ? null
        : 'Invalid IFSC';
  }

  void _validateUpiRealTime() {
    final upi = upiController.text.trim().toLowerCase();
    if (upi.isEmpty) {
      isUpiValid.value = false;
      upiErrorMessage.value = '';
      return;
    }

    final parts = upi.split('@');
    final valid = parts.length == 2 &&
        RegExp(r'^[a-z0-9._-]{3,50}$').hasMatch(parts[0]) &&
        _validUpiProviders.contains(parts[1]);

    isUpiValid.value = valid;
    upiErrorMessage.value = valid ? '' : 'Invalid UPI ID format';
    update(['labs-form']);
  }

  String? validateUpi(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final parts = v.trim().toLowerCase().split('@');
    return parts.length == 2 &&
            RegExp(r'^[a-z0-9._-]{3,50}$').hasMatch(parts[0]) &&
            _validUpiProviders.contains(parts[1])
        ? null
        : 'Invalid UPI ID';
  }

  // ===================== FILE PICKERS =====================
  Future<void> pickLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final cropped = await _cropImage(path);
        logoPath.value = cropped ?? path;
        update(['labs-form']);
      }
    } catch (e) {
      customToast('Error picking logo');
    }
  }

  Future<String?> _cropImage(String path) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: path,
        aspectRatioPresets: [CropAspectRatioPreset.square],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Logo',
            toolbarColor: AppConstants.appPrimaryColor,
            toolbarWidgetColor: Colors.white,
          ),
          IOSUiSettings(title: 'Crop Logo'),
        ],
      );
      return cropped?.path;
    } catch (e) {
      return path;
    }
  }

  Future<void> pickCertificationDocuments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null) {
        for (var file in result.files) {
          final path = file.path;
          if (path != null &&
              !certificationFiles.contains(path) &&
              certificationFiles.length < 5 &&
              await _validateFileSize(path)) {
            certificationFiles.add(path);
          }
        }
        update(['labs-form']);
      }
    } catch (e) {
      customToast('Error picking documents');
    }
  }

  void removeCertificationFile(int index) {
    if (index >= 0 && index < certificationFiles.length) {
      certificationFiles.removeAt(index);
      update(['labs-form']);
    }
  }

  Future<bool> _validateFileSize(String path) async {
    final size = await File(path).length();
    if (size > 5 * 1024 * 1024) {
      customToast('File must be less than 5MB');
      return false;
    }
    return true;
  }

  void toggleAccreditation(String acc) {
    if (selectedAccreditations.contains(acc)) {
      selectedAccreditations.remove(acc);
    } else {
      selectedAccreditations.add(acc);
    }
    update(['labs-form']);
  }

  Future<void> pickExpiryDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppConstants.appPrimaryColor),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      expiryController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      update(['labs-form']);
    }
  }

  String _buildBankJson() => jsonEncode({
        'account_no': accountNoController.text.trim(),
        'ifsc': ifscController.text.trim().toUpperCase(),
        'upi': upiController.text.trim(),
      });

  // ===================== FORM VALIDATION =====================
  bool _validateForm({required bool isNewRegistration}) {
    if (logoPath.value.isEmpty) {
      customToast('Please upload lab logo');
      return false;
    }
    if (certificationFiles.isEmpty) {
      customToast('Please upload at least one certification document');
      return false;
    }
    if (!isAccountNoValid.value) {
      customToast('Valid account number required');
      return false;
    }
    if (!isIfscValid.value || bankName.value.contains('Invalid')) {
      customToast('Valid IFSC code required');
      return false;
    }
    if (isNewRegistration) {
      if (phoneController.text.trim().isEmpty) {
        customToast('Phone number is required');
        return false;
      }
      if (passwordController.text.trim().length < 6) {
        customToast('Password must be at least 6 characters');
        return false;
      }
    }
    return true;
  }
}
