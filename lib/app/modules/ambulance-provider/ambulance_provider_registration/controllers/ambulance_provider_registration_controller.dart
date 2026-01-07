// lib/app/modules/ambulance/controllers/ambulance_provider_registration_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';

class AmbulanceProviderRegistrationController extends GetxController {
  // States
  var isLoading = false.obs;
  var isSubmitting = false.obs;
  var isLoadingLocation = false.obs;
  var is24x7 = true.obs;
  var serviceRadius = 50.0.obs;
  var logoPath = ''.obs;
  var certificationFiles = <String>[].obs;

  // Form Controllers
  final nameController = TextEditingController();
  final licenseController = TextEditingController();
  final expiryController = TextEditingController();
  final emergencyPhoneController = TextEditingController();
  final totalAmbulancesController = TextEditingController();
  final customHoursController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final zipController = TextEditingController();
  final countryController = TextEditingController(text: 'India');
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();

  // Account fields
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var selectedStatus = 'pending'.obs;

  // Selections
  var selectedTypes = <String>[].obs;
  final Map<String, TextEditingController> pricingControllers = {};

  final ambulanceTypes = [
    'Basic Ambulance',
    'Advanced Ambulance',
    'ICU Ambulance',
    'Cardiac Ambulance',
    'Pediatric Ambulance',
    'Neonatal Ambulance',
    'Mortuary Ambulance',
    'Air Ambulance',
    'COVID Transport Ambulance',
  ];

  var hasLoaded = false;

  @override
  void onInit() {
    super.onInit();
    for (var type in ambulanceTypes) {
      pricingControllers[type] = TextEditingController();
    }
  }

  @override
  void onClose() {
    for (var c in pricingControllers.values) c.dispose();
    super.onClose();
  }

  void toggleType(String type) {
    if (selectedTypes.contains(type)) {
      selectedTypes.remove(type);
      pricingControllers[type]!.clear();
    } else {
      selectedTypes.add(type);
    }
  }

  TextEditingController getPricingController(String type) => pricingControllers[type]!;

  Future<void> pickLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        final cropped = await ImageCropper().cropImage(
          sourcePath: result.files.single.path!,
          aspectRatioPresets: [CropAspectRatioPreset.square],
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Logo',
              toolbarColor: AppConstants.appPrimaryColor,
              toolbarWidgetColor: Colors.white,
              lockAspectRatio: true,
            ),
            IOSUiSettings(title: 'Crop Logo'),
          ],
        );
        logoPath.value = cropped?.path ?? result.files.single.path!;
        customToast('Logo selected', Colors.green);
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
        allowMultiple: true,
      );
      if (result != null) {
        int added = 0;
        for (var file in result.files) {
          if (file.path != null &&
              certificationFiles.length < 5 &&
              !certificationFiles.contains(file.path)) {
            final size = await File(file.path!).length();
            if (size <= 5 * 1024 * 1024) {
              certificationFiles.add(file.path!);
              added++;
            }
          }
        }
        if (added > 0) customToast('$added document(s) added', Colors.green);
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
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: AppConstants.appPrimaryColor)),
        child: child!,
      ),
    );
    if (picked != null) {
      expiryController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> getCurrentLocation() async {
    isLoadingLocation.value = true;
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) {
        customToast('Location permission denied forever', Colors.red);
        return;
      }
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      Placemark place = marks[0];

      addressController.text = '${place.street}, ${place.subLocality}'.trim();
      cityController.text = place.locality ?? '';
      stateController.text = place.administrativeArea ?? '';
      zipController.text = place.postalCode ?? '';
      latitudeController.text = pos.latitude.toStringAsFixed(6);
      longitudeController.text = pos.longitude.toStringAsFixed(6);
      customToast('Location updated', Colors.green);
    } catch (e) {
      customToast('Failed to get location', Colors.red);
    } finally {
      isLoadingLocation.value = false;
    }
  }

  Future<void> loadDataIfUpdate(String? id) async {
    if (hasLoaded) return;
    hasLoaded = true;
    isLoading.value = true;

    try {
      final token = await readStr('token');
      final providerId = id ?? await readStr('profileId');
      final res = await http.get(Uri.parse('${AppConstants.endpoint}/ambulances/providers/$providerId'), headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final provider = json['provider'];

        nameController.text = provider['registered_name'] ?? '';
        licenseController.text = provider['license_number'] ?? '';
        expiryController.text = (provider['license_expiry_date'] ?? '').split('T')[0];
        emergencyPhoneController.text = provider['emergency_contact_phone'] ?? '';
        totalAmbulancesController.text = (provider['total_ambulances'] ?? '').toString();
        serviceRadius.value = (provider['service_area_radius'] ?? 50).toDouble();

        selectedTypes.value = List<String>.from(provider['ambulance_types'] ?? []);

        final pricing = provider['pricing_details'] ?? {};
        pricing.forEach((key, value) {
          if (pricingControllers.containsKey(key)) {
            pricingControllers[key]!.text = value.toString();
          }
        });

        addressController.text = provider['address'] ?? '';
        cityController.text = provider['city'] ?? '';
        stateController.text = provider['state'] ?? '';
        zipController.text = provider['zip_code'] ?? '';
        latitudeController.text = provider['latitude']?.toString() ?? '';
        longitudeController.text = provider['longitude']?.toString() ?? '';

        logoPath.value = provider['amb_provider_logo'] ?? '';
        certificationFiles.value = List<String>.from(provider['certification_documents'] ?? []);

        selectedStatus.value = provider['approval_status'] ?? 'pending';
      }
    } catch (e) {
      customToast('Failed to load data');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> registerAndComplete() async {
    if (!_validateForm(isNewRegistration: true)) return;

    isSubmitting.value = true;
    try {
      var request = http.MultipartRequest('POST', Uri.parse('${AppConstants.endpoint}/users'));
      request.fields.addAll({
        'first_name': nameController.text.trim(),
        'phone_number': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
        'role_id': '10', // Replace with actual Ambulance role ID
      });

      final res = await request.send();
      final body = await res.stream.bytesToString();
      final json = jsonDecode(body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final providerId = json['user_id'] ?? json['id'];
        await saveStr('profileId', providerId.toString());
        await saveStr('roleType', 'AmbulanceProvider');

        customToast('Account created! Saving details...', Colors.green);
        await _submitProviderData(providerId.toString());
      } else {
        customToast(json['message'] ?? 'Registration failed', Colors.red);
      }
    } catch (e) {
      customToast('Error: $e', Colors.red);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> updateProvider() async {
    if (!_validateForm(isNewRegistration: false)) return;
    final id = Get.arguments['id'] ?? await readStr('profileId');
    if (id == null) return;
    await _submitProviderData(id);
  }

  Future<void> _submitProviderData(String providerId) async {
    isSubmitting.value = true;
    try {
      final token = await readStr('token');
      final uri = Uri.parse('${AppConstants.endpoint}/ambulances/providers/$providerId');
      final request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';

      final pricingMap = <String, int>{};
      for (var type in selectedTypes) {
        final price = int.tryParse(pricingControllers[type]!.text);
        if (price != null && price >= 100) {
          pricingMap[type] = price;
        }
      }

      request.fields.addAll({
        'registered_name': nameController.text.trim(),
        'license_number': licenseController.text.trim(),
        'license_expiry_date': expiryController.text,
        'emergency_contact_phone': emergencyPhoneController.text.trim(),
        'total_ambulances': totalAmbulancesController.text.trim(),
        'service_area_radius': serviceRadius.value.toInt().toString(),
        'ambulance_types': jsonEncode(selectedTypes),
        'pricing_details': jsonEncode(pricingMap),
        'operating_hours': is24x7.value ? '24/7' : customHoursController.text.trim(),
        'address': addressController.text.trim(),
        'city': cityController.text.trim(),
        'state': stateController.text.trim(),
        'zip_code': zipController.text.trim(),
        'country': 'India',
        'latitude': latitudeController.text.trim(),
        'longitude': longitudeController.text.trim(),
      });

      final role = await readStr('roleType');
      if (role == 'Sales' || role == 'Admin') {
        request.fields['approval_status'] = selectedStatus.value;
      }

      if (logoPath.value.isNotEmpty && !logoPath.value.startsWith('http')) {
        request.files.add(await http.MultipartFile.fromPath('amb_provider_logo', logoPath.value));
      }
      for (var path in certificationFiles.where((p) => !p.startsWith('http'))) {
        request.files.add(await http.MultipartFile.fromPath('certification_documents', path));
      }

      final res = await request.send();
      if (res.statusCode == 200) {
        customToast('Saved successfully!', Colors.green);
        Get.back();
      } else {
        customToast('Failed to save', Colors.red);
      }
    } catch (e) {
      customToast('Error: $e', Colors.red);
    } finally {
      isSubmitting.value = false;
    }
  }

  bool _validateForm({required bool isNewRegistration}) {
    if (logoPath.value.isEmpty) {
      customToast('Upload logo');
      return false;
    }
    if (selectedTypes.isEmpty) {
      customToast('Select ambulance types');
      return false;
    }
    if (certificationFiles.isEmpty) {
      customToast('Upload documents');
      return false;
    }
    for (var type in selectedTypes) {
      final price = int.tryParse(pricingControllers[type]!.text);
      if (price == null || price < 100) {
        customToast('Set valid price for $type (min ₹100)');
        return false;
      }
    }
    if (isNewRegistration) {
      if (phoneController.text.trim().isEmpty || passwordController.text.trim().length < 6) {
        customToast('Valid phone & password required');
        return false;
      }
    }
    return true;
  }
}