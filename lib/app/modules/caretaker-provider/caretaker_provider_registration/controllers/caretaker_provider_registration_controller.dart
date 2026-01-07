// lib/app/modules/caretaker/controllers/caretaker_provider_registration_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';

class CaretakerProviderRegistrationController extends GetxController {
  // States
  var isLoading = false.obs;
  var isSubmitting = false.obs;
  var isLoadingLocation = false.obs;
  var is24x7 = true.obs;
  var serviceRadius = 30.0.obs;
  var logoPath = ''.obs;
  var certificationFiles = <String>[].obs;

  // Form Controllers
  final nameController = TextEditingController();
  final licenseController = TextEditingController();
  final expiryController = TextEditingController();
  final emergencyPhoneController = TextEditingController();
  final totalCaretakersController = TextEditingController();
  final customHoursController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final zipController = TextEditingController();
  final countryController = TextEditingController(text: 'India');
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();
  var selectedStatus = 'Pending'.obs;

  // NEW: Account Registration Fields
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Selection Lists
  var selectedTypes = <String>[].obs;
  var selectedSpecializations = <String>[].obs;
  var selectedAccreditations = <String>[].obs;
  final Map<String, TextEditingController> pricingControllers = {};

  final caretakerTypes = [
    'Home Nurse',
    'Elderly Care Assistant',
    'Patient Attendant',
    'Child Care Helper'
  ];
  final specializations = [
    'Post-Surgery Support',
    'Elderly Care',
    'Child Care',
    'Maternity Support',
    'Palliative Care',
    'Dementia Care'
  ];
  final accreditations = [
    'NABH Accredited',
    'ISO 13485',
    'CAP certified',
    'JCI Accredited',
    'Trained by AIIMS'
  ];

  @override
  void onInit() {
    super.onInit();
    for (var type in caretakerTypes) {
      pricingControllers[type] = TextEditingController();
    }
  }

  void toggleType(String type) {
    if (selectedTypes.contains(type)) {
      selectedTypes.remove(type);
      pricingControllers[type]!.clear();
    } else {
      selectedTypes.add(type);
    }
    update();
  }

  void toggleSpecialization(String spec) =>
      selectedSpecializations.contains(spec)
          ? selectedSpecializations.remove(spec)
          : selectedSpecializations.add(spec);

  void toggleAccreditation(String acc) => selectedAccreditations.contains(acc)
      ? selectedAccreditations.remove(acc)
      : selectedAccreditations.add(acc);

  bool _validateForm({bool isNewRegistration = false}) {
    if (nameController.text.trim().isEmpty) {
      customToast('Please enter provider name', Colors.red);
      return false;
    }
    if (licenseController.text.trim().isEmpty) {
      customToast('Please enter license number', Colors.red);
      return false;
    }
    if (expiryController.text.trim().isEmpty) {
      customToast('Please select license expiry date', Colors.red);
      return false;
    }
    if (emergencyPhoneController.text.trim().isEmpty) {
      customToast('Please enter emergency phone number', Colors.red);
      return false;
    }
    if (totalCaretakersController.text.trim().isEmpty) {
      customToast('Please enter total caretakers', Colors.red);
      return false;
    }
    if (addressController.text.trim().isEmpty) {
      customToast('Please enter address', Colors.red);
      return false;
    }
    if (cityController.text.trim().isEmpty) {
      customToast('Please enter city', Colors.red);
      return false;
    }
    if (stateController.text.trim().isEmpty) {
      customToast('Please enter state', Colors.red);
      return false;
    }
    if (zipController.text.trim().isEmpty) {
      customToast('Please enter zip code', Colors.red);
      return false;
    }
    if (selectedTypes.isEmpty) {
      customToast('Please select at least one caretaker type', Colors.red);
      return false;
    }
    if (isNewRegistration) {
      if (phoneController.text.trim().isEmpty) {
        customToast('Please enter phone number', Colors.red);
        return false;
      }
      if (emailController.text.trim().isEmpty) {
        customToast('Please enter email address', Colors.red);
        return false;
      }
      if (passwordController.text.trim().isEmpty) {
        customToast('Please enter password', Colors.red);
        return false;
      }
      if (passwordController.text.length < 6) {
        customToast('Password must be at least 6 characters', Colors.red);
        return false;
      }
    }
    return true;
  }

  Future<void> pickLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        final cropped = await ImageCropper().cropImage(
          sourcePath: result.files.single.path!,
          aspectRatioPresets: [CropAspectRatioPreset.square],
          uiSettings: [
            AndroidUiSettings(toolbarTitle: 'Crop Logo', lockAspectRatio: true),
            IOSUiSettings(title: 'Crop Logo')
          ],
        );
        logoPath.value = cropped?.path ?? result.files.single.path!;
        customToast('Logo updated', Colors.green);
      }
    } catch (e) {
      customToast('Failed to pick logo', Colors.red);
    }
  }

  Future<void> pickDocuments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
          allowMultiple: true);
      if (result != null) {
        for (var file in result.files) {
          if (file.path != null &&
              certificationFiles.length < 5 &&
              !certificationFiles.contains(file.path)) {
            final size = await File(file.path!).length();
            if (size / (1024 * 1024) <= 5) certificationFiles.add(file.path!);
          }
        }
        customToast(
            '${certificationFiles.length} documents added', Colors.green);
      }
    } catch (e) {
      customToast('Failed to add documents', Colors.red);
    }
  }

  void removeDocument(int index) => certificationFiles.removeAt(index);

  Future<void> pickExpiryDate(BuildContext context) async {
    final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2035));
    if (picked != null) {
      expiryController.text = picked.toIso8601String().split('T').first;
    }
  }

  Future<void> getCurrentLocation() async {
    isLoadingLocation.value = true;
    update(['caretaker-form']);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return customToast('Location permission denied', Colors.red);
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];

      addressController.text = '${place.street}, ${place.subLocality}'.trim();
      cityController.text = place.locality ?? '';
      stateController.text = place.administrativeArea ?? '';
      zipController.text = place.postalCode ?? '';
      latitudeController.text = position.latitude.toStringAsFixed(6);
      longitudeController.text = position.longitude.toStringAsFixed(6);
      customToast('Location updated', Colors.green);
    } catch (e) {
      customToast('Failed to get location', Colors.red);
    } finally {
      isLoadingLocation.value = false;
      update(['caretaker-form']);
    }
  }

  Future<void> loadDataIfUpdate(id) async {
    isLoading.value = true;
    update(['caretaker-form']);

    try {
      final token = await readStr('token');
      final providerId = id ?? await readStr('profileId');

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token missing');
      }

      final response = await http.get(
        Uri.parse('${AppConstants.endpoint}/caretakers/providers/$providerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Server error ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (data['status'] != true) {
        throw Exception(data['message'] ?? 'Failed to load provider data');
      }

      final provider = data['provider'] as Map<String, dynamic>;
      final user = provider['user'] as Map<String, dynamic>? ?? {};

      // Basic Info
      nameController.text = provider['provider_name'] ?? '';
      licenseController.text = provider['license_number'] ?? '';

      // License expiry date (format: YYYY-MM-DD)
      if (provider['license_expiry_date'] != null) {
        final expiryDate = DateTime.tryParse(provider['license_expiry_date']);
        if (expiryDate != null) {
          expiryController.text = DateFormat('yyyy-MM-dd').format(expiryDate);
        }
      }

      emergencyPhoneController.text = provider['emergency_contact_phone'] ?? '';
      totalCaretakersController.text =
          (provider['total_caretakers'] ?? 0).toString();

      // Service Radius
      serviceRadius.value = (provider['service_area_radius'] ?? 15).toDouble();

      // Caretaker Types
      selectedTypes.clear();
      final List types = provider['caretaker_types'] ?? [];
      selectedTypes.addAll(types.cast<String>());

      // Pricing Details (e.g., HomeNursePerDay → map to readable key)
      final Map<String, dynamic> pricing = provider['pricing_details'] ?? {};

      pricing.forEach((apiKey, price) {
        String displayKey = '';
        if (apiKey == 'HomeNursePerDay') {
          displayKey = 'Home Nurse';
        } else if (apiKey == 'PatientAttendantPerDay') {
          displayKey = 'Patient Attendant';
        }
        // Add more mappings as needed

        if (displayKey.isNotEmpty &&
            pricingControllers.containsKey(displayKey)) {
          pricingControllers[displayKey]!.text = price.toString();
        }
      });

      // Specializations
      selectedSpecializations.clear();
      final List specializations = provider['specialization_areas'] ?? [];
      selectedSpecializations.addAll(specializations.cast<String>());

      // Accreditations
      selectedAccreditations.clear();
      final List accreditations = provider['accreditation'] ?? [];
      selectedAccreditations.addAll(accreditations.cast<String>());

      // Address & Location
      addressController.text = provider['address'] ?? user['address'] ?? '';
      cityController.text = provider['city'] ?? user['city'] ?? '';
      stateController.text = provider['state'] ?? user['state'] ?? '';
      zipController.text = provider['zip_code'] ?? user['postal_code'] ?? '';

      latitudeController.text = provider['latitude']?.toString() ?? '';
      longitudeController.text = provider['longitude']?.toString() ?? '';

      // Logo & Certification Documents
      logoPath.value = provider['caretaker_logo'] ?? '';

      certificationFiles.value =
          List<String>.from(provider['certification_documents'] ?? []);

      selectedStatus.value =
          provider['approval_status']?.toString().toLowerCase() ?? 'pending';

      // Optional: Operating Hours (if you have a field for it)
      // operatingHours.value = provider['operating_hours'] ?? {};
    } catch (e) {
      debugPrint('Error loading caretaker data: $e');
    } finally {
      isLoading.value = false;
      update(['caretaker-form']);
    }
  }

  // Full new registration: create user + provider
  Future<void> registerAndComplete() async {
    if (!_validateForm(isNewRegistration: true)) return;

    isSubmitting.value = true;
    try {
      // Step 1: Create User Account
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.endpoint}/users'),
      );

      request.fields.addAll({
        'first_name': nameController.text.trim(),
        'phone_number': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
        'role_id': '9',
      });

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final providerId = json['user_id'] ?? json['id'];
        await saveStr('profileId', providerId.toString());
        await saveStr('roleType', 'CaretakerProvider');

        // Step 2: Submit provider data
        await _submitProviderData(providerId.toString());
      } else {
        customToast(json['message'] ?? 'Registration failed', Colors.red);
      }
    } catch (e) {
      customToast('Registration error: $e', Colors.red);
    } finally {
      isSubmitting.value = false;
    }
  }

  // Shared submission logic
  Future<void> _submitProviderData(String providerId) async {
    isSubmitting.value = true;
    try {
      final token = await readStr('token');
      if (token == null) {
        customToast('Authentication failed');
        return;
      }

      final uri = Uri.parse(
          '${AppConstants.endpoint}/caretakers/providers/$providerId');
      final request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Build pricing map
      final pricingMap = <String, int>{};
      for (var type in selectedTypes) {
        final priceText = pricingControllers[type]!.text.trim();
        if (priceText.isNotEmpty) {
          final price = int.tryParse(priceText);
          if (price != null && price >= 200) {
            pricingMap['${type.replaceAll(' ', '')}PerDay'] = price;
          }
        }
      }

      request.fields.addAll({
        'provider_name': nameController.text.trim(),
        'license_number': licenseController.text.trim(),
        'license_expiry_date': expiryController.text,
        'emergency_contact_phone': emergencyPhoneController.text.trim(),
        'total_caretakers': totalCaretakersController.text.trim(),
        'service_area_radius': serviceRadius.value.toInt().toString(),
        'caretaker_types': jsonEncode(selectedTypes),
        'pricing_details': jsonEncode(pricingMap),
        'specialization_areas': jsonEncode(selectedSpecializations),
        'accreditation': jsonEncode(selectedAccreditations),
        'address': addressController.text.trim(),
        'city': cityController.text.trim(),
        'state': stateController.text.trim(),
        'zip_code': zipController.text.trim(),
        'country': 'India',
        'latitude': latitudeController.text.trim(),
        'longitude': longitudeController.text.trim(),
        'operating_hours':
            is24x7.value ? '24/7' : customHoursController.text.trim(),
      });

      // Add sales approval status
      final role = await readStr('roleType');
      if (role == 'Sales' || role == 'Admin') {
        request.fields['approval_status'] = selectedStatus.value;
      }

      // Upload new logo
      if (logoPath.value.isNotEmpty && !logoPath.value.startsWith('http')) {
        request.files.add(await http.MultipartFile.fromPath(
            'caretaker_logo', logoPath.value));
      }

      // Upload new documents
      for (var path in certificationFiles.where((p) => !p.startsWith('http'))) {
        request.files.add(
            await http.MultipartFile.fromPath('certification_documents', path));
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        customToast('Provider saved successfully!', Colors.green);
        Get.back();
      } else {
        customToast('Failed to save provider', Colors.red);
      }
    } catch (e) {
      customToast('Error: $e', Colors.red);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> updateProvider() async {
    isSubmitting.value = true;
    update(['caretaker-form']);

    try {
      final id = Get.arguments['id'] ?? await readStr('profileId') ?? '1';
      final uri =
          Uri.parse('${AppConstants.endpoint}/caretakers/providers/$id');
      var request = http.MultipartRequest('PUT', uri);
      final token = await readStr('token');
      request.headers['Authorization'] = 'Bearer $token';

      final Map<String, int> pricingMap = {};
      for (var type in selectedTypes) {
        final priceText = pricingControllers[type]!.text.trim();
        if (priceText.isNotEmpty) {
          final key = '${type.replaceAll(' ', '')}PerDay';
          pricingMap[key] = int.tryParse(priceText) ?? 0;
        }
      }

      request.fields.addAll({
        'license_number': licenseController.text.trim(),
        'license_expiry_date': expiryController.text,
        'caretaker_types': jsonEncode(selectedTypes),
        'service_area_radius': serviceRadius.value.toInt().toString(),
        'operating_hours': is24x7.value
            ? jsonEncode({"Mon-Sun": "24/7"})
            : jsonEncode({"Custom": customHoursController.text.trim()}),
        'pricing_details': jsonEncode(pricingMap),
        'emergency_contact_phone': emergencyPhoneController.text.trim(),
        'total_caretakers': totalCaretakersController.text.trim(),
        'specialization_areas': jsonEncode(selectedSpecializations),
        'accreditation': jsonEncode(selectedAccreditations),
        'address': addressController.text.trim(),
        'city': cityController.text.trim(),
        'state': stateController.text.trim(),
        'zip_code': zipController.text.trim(),
        'country': 'India',
        'latitude': latitudeController.text.trim(),
        'longitude': longitudeController.text.trim(),
      });

      // Add sales approval status
      final role = await readStr('roleType');
      if (role == 'Sales' || role == 'Admin') {
        request.fields['approval_status'] = selectedStatus.value;
      }

      // ONLY upload new logo if user selected a new one (local path)
      if (logoPath.value.isNotEmpty && File(logoPath.value).existsSync()) {
        request.files.add(await http.MultipartFile.fromPath(
          'caretaker_logo',
          logoPath.value,
        ));
      }

      // Only upload new certification files (local paths)
      for (var path in certificationFiles) {
        if (File(path).existsSync()) {
          request.files.add(await http.MultipartFile.fromPath(
            'certification_documents',
            path,
          ));
        }
      }

      final response = await request.send();
      final respData = await response.stream.bytesToString();
      final jsonResp = jsonDecode(respData);

      if (response.statusCode == 200) {
        customToast('Provider updated successfully!', Colors.green);
        Get.back();
      } else {
        customToast(jsonResp['message'] ?? 'Update failed', Colors.red);
      }
    } catch (e) {
      print('Update error: $e');
      customToast('Error: $e', Colors.red);
    } finally {
      isSubmitting.value = false;
      update(['caretaker-form']);
    }
  }
}
