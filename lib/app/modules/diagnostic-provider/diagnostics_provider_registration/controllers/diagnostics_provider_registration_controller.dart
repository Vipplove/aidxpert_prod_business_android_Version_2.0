// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';

class DiagnosticsProviderRegistrationController extends GetxController {
  // Form Controllers
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

  // Reactive
  var logoPath = ''.obs;
  var certificationFiles = <String>[].obs;
  var selectedAccreditations = <String>[].obs;
  var isLoading = false.obs;
  var isLoadingLocation = false.obs;

  // Validation
  var isAccountNoValid = false.obs;
  var accountNoErrorMessage = ''.obs;
  var isIfscValid = false.obs;
  var ifscErrorMessage = ''.obs;
  var isUpiValid = false.obs;
  var upiErrorMessage = ''.obs;
  var bankName = ''.obs;
  var isFetchingBank = false.obs;
  var selectedStatus = 'pending'.obs;

  final Map<String, Map<String, String>> _ifscCache = {};
  var hasLoaded = true.obs;

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
    // Dispose all
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
        'role_id': '7',
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

      final uri = Uri.parse(
          '${AppConstants.endpoint}/diagnostics/providers/$providerId');
      final request = http.MultipartRequest('PUT', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields.addAll({
          'provider_name': providerNameController.text.trim(),
          'gst_number': gstController.text.trim(),
          'pan_number': panController.text.trim(),
          'bank_details': _buildBankJson(),
          'accreditation': jsonEncode(selectedAccreditations),
          'license_number': licenseController.text.trim(),
          'license_expiry': expiryController.text.trim(),
          'address': addressController.text.trim(),
          'city': cityController.text.trim(),
          'state': stateController.text.trim(),
          'zip_code': zipController.text.trim(),
          'country': 'India',
          'latitude': latitudeController.text.trim(),
          'longitude': longitudeController.text.trim(),
        });

      var roles = await readStr('roleType');

      if (roles == 'Sales' || roles == 'Admin') {
        print(roles);
        request.fields['approval_status'] = selectedStatus.value;
      }

      // Upload new logo
      if (logoPath.value.isNotEmpty && !logoPath.value.startsWith('http')) {
        request.files
            .add(await http.MultipartFile.fromPath('logo', logoPath.value));
      }

      // Upload new certification documents
      for (String file
          in certificationFiles.where((f) => !f.startsWith('http'))) {
        request.files.add(
            await http.MultipartFile.fromPath('certification_documents', file));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        customToast('Profile updated successfully!', Colors.green);

        // Save ALL data directly from form (exactly what user typed)
        await saveStr('provider_name', providerNameController.text.trim());
        await saveStr('gst_number', gstController.text.trim());
        await saveStr('pan_number', panController.text.trim());
        await saveStr('license_number', licenseController.text.trim());
        await saveStr('bank_details', _buildBankJson());
        await saveStr('address', addressController.text.trim());
        await saveStr('city', cityController.text.trim());
        await saveStr('state', stateController.text.trim());
        await saveStr('zip_code', zipController.text.trim());
        await saveStr('accreditation', jsonEncode(selectedAccreditations));
        await saveStr('latitude', latitudeController.text.trim());
        await saveStr('longitude', longitudeController.text.trim());
        Get.back();
      } else {
        final errorMsg =
            jsonResponse['message'] ?? jsonResponse['error'] ?? 'Update failed';
        customToast('Failed: $errorMsg');
      }
    } catch (e) {
      debugPrint('Update Provider Error: $e');
      customToast('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
      update(['diagnostic-form']);
    }
  }

  // === LOAD FROM API ===
  Future<void> loadUpdateDataFromApi(diagId) async {
    hasLoaded.value = true;

    try {
      String? id;

      if (diagId == null) {
        id = await readStr('profileId');
      } else {
        id = diagId.toString();
      }

      // Validate ID
      if (id == null || id.isEmpty) {
        customToast("Invalid Provider ID");
        return;
      }

      final token = await readStr('token') ?? '';

      final res = await http.get(
        Uri.parse('${AppConstants.endpoint}/diagnostics/providers/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final provider = json['provider'] ?? {};

        // Basic Details
        providerNameController.text = provider['provider_name'] ?? '';
        gstController.text = provider['gst_number'] ?? '';
        panController.text = provider['pan_number'] ?? '';
        licenseController.text = provider['license_number'] ?? '';
        expiryController.text =
            (provider['license_expiry'] ?? '').toString().split('T')[0];

        // Bank Details
        final bank = provider['bank_details'] ?? {};
        accountNoController.text = bank['account_no'] ?? '';
        ifscController.text = (bank['ifsc'] ?? '').toString().toUpperCase();
        upiController.text = bank['upi'] ?? '';

        // Address
        addressController.text = provider['address'] ?? '';
        cityController.text = provider['city'] ?? '';
        stateController.text = provider['state'] ?? '';
        zipController.text = provider['zip_code'] ?? '';

        // Location
        latitudeController.text = (provider['latitude'] ?? '').toString();
        longitudeController.text = (provider['longitude'] ?? '').toString();

        // Files
        logoPath.value = provider['logo'] ?? '';

        selectedAccreditations.value =
            List<String>.from(provider['accreditation'] ?? []);

        certificationFiles.value =
            List<String>.from(provider['certification_documents'] ?? []);

        selectedStatus.value = provider['approval_status'] ?? 'pending';

        // Update UI
        Future.microtask(() => update(['diagnostic-form']));
      }
    } catch (e) {
      print("Diagnostics Load Error: $e");
      hasLoaded.value = false;
      update(['diagnostic-form']);
    } finally {
      hasLoaded.value = false;
      update(['diagnostic-form']);
    }
  }

  // === VALIDATIONS (unchanged) ===
  void _validateAccountNoRealTime() {
    final acc = accountNoController.text.trim();
    final clean = acc.replaceAll(RegExp(r'\D'), '');
    if (acc != clean) {
      accountNoController.value = TextEditingValue(
          text: clean,
          selection: TextSelection.collapsed(offset: clean.length));
    }
    final length = clean.length;
    final isValid = length >= 9 && length <= 18;
    isAccountNoValid.value = isValid;
    accountNoErrorMessage.value =
        isValid ? '' : (length < 9 ? 'Min 9 digits' : 'Max 18 digits');
    Future.microtask(() => update(['diagnostic-form']));
  }

  String? validateAccountNo(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final clean = v.trim().replaceAll(RegExp(r'\D'), '');
    return clean.length >= 9 && clean.length <= 18 ? null : '9–18 digits';
  }

  void _validateAndFetchIfsc() {
    final ifsc = ifscController.text.trim().toUpperCase();
    ifscController.value = TextEditingValue(
        text: ifsc, selection: TextSelection.collapsed(offset: ifsc.length));
    if (ifsc.isEmpty) {
      _resetIfscState();
      return;
    }

    final formatValid = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc);
    isIfscValid.value = formatValid;
    if (!formatValid) {
      ifscErrorMessage.value = _getIfscError(ifsc);
      bankName.value = '';
      return;
    }
    ifscErrorMessage.value = '';
    _fetchIfscDetails(ifsc);
  }

  String _getIfscError(String ifsc) {
    if (ifsc.length != 11) return 'Must be 11 characters';
    if (!RegExp(r'^[A-Z]{4}').hasMatch(ifsc)) return 'First 4 must be letters';
    if (ifsc[4] != '0') return '5th character must be 0';
    return 'Invalid format';
  }

  Future<void> _fetchIfscDetails(String ifsc) async {
    if (_ifscCache.containsKey(ifsc)) {
      _applyIfscData(_ifscCache[ifsc]!);
      return;
    }
    if (isFetchingBank.value) return;
    isFetchingBank.value = true;
    bankName.value = '';

    try {
      final res = await http.get(Uri.parse('https://ifsc.razorpay.com/$ifsc'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final result = {
          'bank':
              '${data['BANK'] ?? 'Unknown'} - ${data['BRANCH'] ?? ''}'.trim(),
          'city': (data['CITY'] ?? '').toString(),
          'state': (data['STATE'] ?? '').toString(),
        };
        _ifscCache[ifsc] = result;
        _applyIfscData(result);
      } else {
        bankName.value = 'Invalid IFSC';
      }
    } catch (e) {
      bankName.value = 'Failed to fetch';
    } finally {
      isFetchingBank.value = false;
      Future.microtask(() => update(['diagnostic-form']));
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
    upiController.value = TextEditingValue(
        text: upi, selection: TextSelection.collapsed(offset: upi.length));
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
    upiErrorMessage.value = valid
        ? ''
        : (parts.length != 2
            ? 'Use @'
            : parts[0].length < 3
                ? 'Username too short'
                : 'Invalid provider');
    Future.microtask(() => update(['diagnostic-form']));
  }

  String? validateUpi(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final clean = v.trim().toLowerCase();
    final parts = clean.split('@');
    return parts.length == 2 &&
            RegExp(r'^[a-z0-9._-]{3,50}$').hasMatch(parts[0]) &&
            _validUpiProviders.contains(parts[1])
        ? null
        : 'Invalid UPI ID';
  }

  // === FILE PICKERS ===
  Future<void> pickLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final cropped = await _cropImage(path);
        logoPath.value = cropped ?? path;
        Future.microtask(() => update(['diagnostic-form']));
      }
    } catch (e) {
      customToast('Error picking logo');
    }
  }

  Future<String?> _cropImage(String path) async {
    try {
      final cropped =
          await ImageCropper().cropImage(sourcePath: path, aspectRatioPresets: [
        CropAspectRatioPreset.square
      ], uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Crop Logo',
            toolbarColor: AppConstants.appPrimaryColor,
            toolbarWidgetColor: Colors.white),
        IOSUiSettings(title: 'Crop Logo'),
      ]);
      return cropped?.path ?? path;
    } catch (e) {
      return path;
    }
  }

  Future<void> pickCertificationDocuments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
          allowMultiple: true);
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
        Future.microtask(() => update(['diagnostic-form']));
      }
    } catch (e) {
      customToast('Error picking documents');
    }
  }

  void removeCertificationFile(int index) {
    if (index >= 0 && index < certificationFiles.length) {
      certificationFiles.removeAt(index);
      update(['diagnostic-form']);
    }
  }

  Future<bool> _validateFileSize(String path) async {
    final sizeMB = await File(path).length() / (1024 * 1024);
    if (sizeMB > 5) {
      customToast('File must be < 5MB');
      return false;
    }
    return true;
  }

  void toggleAccreditation(String acc) {
    selectedAccreditations.contains(acc)
        ? selectedAccreditations.remove(acc)
        : selectedAccreditations.add(acc);
    update(['diagnostic-form']);
  }

  Future<void> pickExpiryDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
              colorScheme:
                  ColorScheme.light(primary: AppConstants.appPrimaryColor)),
          child: child!),
    );
    if (picked != null) {
      expiryController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      update(['diagnostic-form']);
    }
  }

  String _buildBankJson() => jsonEncode({
        'account_no': accountNoController.text.trim(),
        'ifsc': ifscController.text.trim().toUpperCase(),
        'upi': upiController.text.trim(),
      });

  Future<void> updateProvider() async {
    if (!_validateForm(isNewRegistration: false)) return;

    isLoading.value = true;
    update(['diagnostic-form']);

    try {
      final token = await readStr('token');
      final String? id = await readStr('profileId');

      if (token == null || id == null) {
        customToast('Login required or profile not found');
        isLoading.value = false;
        update(['diagnostic-form']);
        return;
      }

      final uri =
          Uri.parse('${AppConstants.endpoint}/diagnostics/providers/$id');
      final request = http.MultipartRequest('PUT', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields.addAll({
          'provider_name': providerNameController.text.trim(),
          'gst_number': gstController.text.trim(),
          'pan_number': panController.text.trim(),
          'bank_details': _buildBankJson(),
          'accreditation': jsonEncode(selectedAccreditations),
          'license_number': licenseController.text.trim(),
          'license_expiry': expiryController.text.trim(),
          'address': addressController.text.trim(),
          'city': cityController.text.trim(),
          'state': stateController.text.trim(),
          'zip_code': zipController.text.trim(),
          'country': 'India',
          'latitude': latitudeController.text.trim(),
          'longitude': longitudeController.text.trim(),
        });

      var roles = await readStr('roleType');

      if (roles == 'Sales' || roles == 'Admin') {
        print(roles);
        request.fields['approval_status'] = selectedStatus.value;
      }

      // Upload new logo
      if (logoPath.value.isNotEmpty && !logoPath.value.startsWith('http')) {
        request.files
            .add(await http.MultipartFile.fromPath('logo', logoPath.value));
      }

      // Upload new certification documents
      for (String file
          in certificationFiles.where((f) => !f.startsWith('http'))) {
        request.files.add(
            await http.MultipartFile.fromPath('certification_documents', file));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        customToast('Profile updated successfully!', Colors.green);

        // Save ALL data directly from form (exactly what user typed)
        await saveStr('provider_name', providerNameController.text.trim());
        await saveStr('gst_number', gstController.text.trim());
        await saveStr('pan_number', panController.text.trim());
        await saveStr('license_number', licenseController.text.trim());
        await saveStr('bank_details', _buildBankJson());
        await saveStr('address', addressController.text.trim());
        await saveStr('city', cityController.text.trim());
        await saveStr('state', stateController.text.trim());
        await saveStr('zip_code', zipController.text.trim());
        await saveStr('accreditation', jsonEncode(selectedAccreditations));
        await saveStr('latitude', latitudeController.text.trim());
        await saveStr('longitude', longitudeController.text.trim());
        Get.back();
      } else {
        final errorMsg =
            jsonResponse['message'] ?? jsonResponse['error'] ?? 'Update failed';
        customToast('Failed: $errorMsg');
      }
    } catch (e) {
      debugPrint('Update Provider Error: $e');
      customToast('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
      update(['diagnostic-form']);
    }
  }

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
