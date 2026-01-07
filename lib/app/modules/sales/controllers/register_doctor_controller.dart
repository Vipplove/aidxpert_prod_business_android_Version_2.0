// ignore_for_file: prefer_interpolation_to_compose_strings, avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../../constants/app_constants.dart';
import '../../../../utils/helper.dart';

class RegisterDoctorController extends GetxController {
  late final TextEditingController userNameController;
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController birthdayController;
  late final TextEditingController biographyController;
  late final TextEditingController doctorCodeController;
  late final TextEditingController medicalRegNoController;
  late final TextEditingController serviceSearchController;
  late final TextEditingController specializationController;
  late final TextEditingController languageSearchController;
  final RxList<Map<String, TextEditingController>> educations =
      <Map<String, TextEditingController>>[].obs;
  final RxList<Map<String, TextEditingController>> experiences =
      <Map<String, TextEditingController>>[].obs;
  final RxList<Map<String, TextEditingController>> awards =
      <Map<String, TextEditingController>>[].obs;
  final RxList<Map<String, TextEditingController>> memberships =
      <Map<String, TextEditingController>>[].obs;
  final RxList<Map<String, TextEditingController>> registrations =
      <Map<String, TextEditingController>>[].obs;
  final RxList<Map<String, TextEditingController>> pricing =
      <Map<String, TextEditingController>>[].obs;
  final RxList<Map<String, dynamic>> clinics = <Map<String, dynamic>>[].obs;
  final RxString profileUrl = ''.obs;
  final RxString profileImagePath = ''.obs;
  final RxMap<String, List<String>> documentUrls = <String, List<String>>{}.obs;
  final RxList<String> services = <String>[].obs;
  final RxList<String> specializations = <String>[].obs;
  final RxList<String> languages = <String>[].obs;
  final RxString selectedGender = ''.obs;
  final RxBool isSurgeon = false.obs;
  final RxBool isAvailable = false.obs;
  var isLoading = false.obs;
  var startDate = DateTime.now();
  var endDate = DateTime.now();
  final ImagePicker _picker = ImagePicker();
  final List<String> availableServices = [
    'Root Canal',
    'Braces',
    'General Checkup',
    'Surgery',
    'Consultation',
    'X-Ray',
    'Blood Test',
    'MRI Scan',
    'Physical Therapy',
    'Dental Checkup'
  ];
  final List<String> availableSpecializations = [
    'Dentist',
    'Cardiology',
    'Neurology',
    'Pediatrics',
    'Orthopedics',
    'Dermatology',
    'Ophthalmology',
    'Gynecology'
  ];

  @override
  void onInit() {
    super.onInit();
    userNameController = TextEditingController();
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    birthdayController = TextEditingController();
    biographyController = TextEditingController();
    doctorCodeController = TextEditingController();
    medicalRegNoController = TextEditingController();
    serviceSearchController = TextEditingController();
    specializationController = TextEditingController();
    languageSearchController = TextEditingController();
    documentUrls['medicalDegree'] = [];
    documentUrls['medicalCouncil'] = [];
    documentUrls['identityProof'] = [];
    loadUserData();
    addEducation();
    addExperience();
    addAward();
    addMembership();
    addRegistration();
    addPricing();
  }

  @override
  void onClose() {
    userNameController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    birthdayController.dispose();
    biographyController.dispose();
    doctorCodeController.dispose();
    medicalRegNoController.dispose();
    serviceSearchController.dispose();
    specializationController.dispose();
    languageSearchController.dispose();
    for (var edu in educations) {
      edu['degreeController']?.dispose();
      edu['instituteController']?.dispose();
      edu['yearOfCompletionController']?.dispose();
    }
    for (var exp in experiences) {
      exp['hospitalNameController']?.dispose();
      exp['designationController']?.dispose();
      exp['fromController']?.dispose();
      exp['toController']?.dispose();
    }
    for (var award in awards) {
      award['titleController']?.dispose();
      award['yearController']?.dispose();
    }
    for (var mem in memberships) {
      mem['organizationController']?.dispose();
    }
    for (var reg in registrations) {
      reg['councilController']?.dispose();
      reg['yearController']?.dispose();
    }
    for (var price in pricing) {
      price['typeController']?.dispose();
      price['priceController']?.dispose();
    }
    for (var clinic in clinics) {
      clinic['clinicNameController']?.dispose();
      clinic['clinicAddressController']?.dispose();
      clinic['areaController']?.dispose();
      clinic['cityController']?.dispose();
      clinic['stateController']?.dispose();
      clinic['countryController']?.dispose();
      clinic['postalCodeController']?.dispose();
      clinic['latitudeController']?.dispose();
      clinic['longitudeController']?.dispose();
      clinic['contactNumberController']?.dispose();
      clinic['emailController']?.dispose();
      clinic['websiteController']?.dispose();
      clinic['openingTimeController']?.dispose();
      clinic['closingTimeController']?.dispose();
      clinic['workingDaysController']?.dispose();
      clinic['isActiveController']?.dispose();
    }
    super.onClose();
  }

  Future<void> loadUserData() async {
    userNameController.text = await readStr('user_name') ?? '';
    firstNameController.text = await readStr('first_name') ?? '';
    lastNameController.text = await readStr('last_name') ?? '';
    emailController.text = await readStr('email') ?? '';
    phoneController.text = await readStr('phone_number') ?? '';
    selectedGender.value = await readStr('gender') ?? '';
    birthdayController.text = await readStr('birthday') ?? '';
    biographyController.text = await readStr('biography') ?? '';
    update(['doctor-edit-profile']);
  }

  void setProfileImage(XFile image) {
    profileImagePath.value = image.path;
    update(['doctor-edit-profile']);
  }

  Future<void> pickDocument({required String documentKey}) async {
    final XFile? file = await _picker.pickMedia();
    if (file != null) {
      final fileSize = await File(file.path).length();
      if (fileSize > 5 * 1024 * 1024) {
        customToast("File size must be less than 5MB", Colors.red);
        return;
      }
      final extension = file.path.toLowerCase().split('.').last;
      if (!['pdf', 'jpg', 'png'].contains(extension)) {
        customToast("Only PDF, JPG, or PNG files are allowed", Colors.red);
        return;
      }
      documentUrls[documentKey] = [file.path];
      update(['doctor-edit-profile']);
    }
  }

  // Document management methods
  void addDocument(String documentKey, String filePath) {
    documentUrls[documentKey] = [filePath];
    update(['doctor-edit-profile']);
  }

  void removeDocument(String documentKey) {
    documentUrls[documentKey] = [];
    update(['doctor-edit-profile']);
  }

  void removeService(String service) {
    services.remove(service);
    update(['doctor-edit-profile']);
  }

  void addSelectedServices(List<String> selectedServices) {
    for (var service in selectedServices) {
      if (!services.contains(service)) {
        services.add(service);
      }
    }
    update(['doctor-edit-profile']);
  }

  void removeSpecialization(String spec) {
    specializations.remove(spec);
    update(['doctor-edit-profile']);
  }

  void addSelectedSpecializations(List<String> selectedSpecializations) {
    for (var spec in selectedSpecializations) {
      if (!specializations.contains(spec)) {
        specializations.add(spec);
      }
    }
    update(['doctor-edit-profile']);
  }

  void removeLanguage(String lang) {
    languages.remove(lang);
    update(['doctor-edit-profile']);
  }

  void addSelectedLanguages(List<String> selectedLanguages) {
    for (var lang in selectedLanguages) {
      if (!languages.contains(lang)) {
        languages.add(lang);
      }
    }
    update(['doctor-edit-profile']);
  }

  void addEducation() {
    educations.add({
      'degreeController': TextEditingController(),
      'instituteController': TextEditingController(),
      'yearOfCompletionController': TextEditingController(),
    });
    update(['doctor-edit-profile']);
  }

  void addExperience() {
    experiences.add({
      'hospitalNameController': TextEditingController(),
      'designationController': TextEditingController(),
      'fromController': TextEditingController(),
      'toController': TextEditingController(),
    });
    update(['doctor-edit-profile']);
  }

  void addAward() {
    awards.add({
      'titleController': TextEditingController(),
      'yearController': TextEditingController(),
    });
    update(['doctor-edit-profile']);
  }

  void addMembership() {
    memberships.add({
      'organizationController': TextEditingController(),
    });
    update(['doctor-edit-profile']);
  }

  void addRegistration() {
    registrations.add({
      'councilController': TextEditingController(),
      'yearController': TextEditingController(),
    });
    update(['doctor-edit-profile']);
  }

  void addPricing() {
    pricing.add({
      'typeController': TextEditingController(),
      'priceController': TextEditingController(),
    });
    update(['doctor-edit-profile']);
  }

  Future<void> setGender(String value) async {
    selectedGender.value = value;
    update(['doctor-edit-profile']);
  }

  void setIsSurgeon(bool value) {
    isSurgeon.value = value;
    update(['doctor-edit-profile']);
  }

  void setAvailability(bool val) {
    isAvailable.value = !val;
    update(['availability']);
  }

  Future<void> fetchDoctorProfile(docId) async {
    EasyLoading.show(status: 'Loading...');
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.endpoint}/doctors/$docId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await readStr('token') ?? ''}',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final doctor = responseBody['doctorDetails'] as Map<String, dynamic>?;

        if (doctor != null) {
          // --- Basic doctor info ---
          doctorCodeController.text = doctor['doctor_code']?.toString() ?? '';
          medicalRegNoController.text =
              doctor['medical_reg_no']?.toString() ?? '';
          isSurgeon.value = doctor['is_surgeon'] ?? false;

          // --- Pricing ---
          pricing.clear();
          for (var p in (doctor['pricing'] as List<dynamic>?) ?? []) {
            pricing.add({
              'typeController':
                  TextEditingController(text: p['type']?.toString() ?? ''),
              'priceController':
                  TextEditingController(text: p['price']?.toString() ?? ''),
            });
          }

          // --- Services ---
          services.clear();
          for (var s in (doctor['services'] as List<dynamic>?) ?? []) {
            services.add(s.toString());
          }

          // --- Specializations ---
          specializations.clear();
          for (var sp in (doctor['specializations'] as List<dynamic>?) ?? []) {
            specializations.add(sp.toString());
          }

          // --- Education ---
          educations.clear();
          for (var edu in (doctor['education'] as List<dynamic>?) ?? []) {
            educations.add({
              'degreeController':
                  TextEditingController(text: edu['degree']?.toString() ?? ''),
              'instituteController':
                  TextEditingController(text: edu['college']?.toString() ?? ''),
              'yearOfCompletionController': TextEditingController(
                  text: edu['year_of_completion']?.toString() ?? ''),
            });
          }

          // --- Experience ---
          experiences.clear();
          for (var exp in (doctor['experience'] as List<dynamic>?) ?? []) {
            experiences.add({
              'hospitalNameController': TextEditingController(
                  text: exp['hospital_name']?.toString() ?? ''),
              'designationController': TextEditingController(
                  text: exp['designation']?.toString() ?? ''),
              'fromController': TextEditingController(
                  text: exp['from_date']?.toString().split('-')[0] ?? ''),
              'toController': TextEditingController(
                  text: exp['to_date']?.toString().split('-')[0] ?? ''),
            });
          }

          // --- Languages ---
          languages.clear();
          for (var lang
              in (doctor['languages_known'] as List<dynamic>?) ?? []) {
            languages.add(lang.toString());
          }

          // --- Awards ---
          awards.clear();
          for (var award in (doctor['awards'] as List<dynamic>?) ?? []) {
            awards.add({
              'titleController':
                  TextEditingController(text: award['title']?.toString() ?? ''),
              'yearController':
                  TextEditingController(text: award['year']?.toString() ?? ''),
            });
          }

          // --- Memberships ---
          memberships.clear();
          for (var mem in (doctor['memberships'] as List<dynamic>?) ?? []) {
            memberships.add({
              'organizationController': TextEditingController(
                  text: mem['association']?.toString() ?? ''),
            });
          }

          // --- Registrations ---
          registrations.clear();
          for (var reg in (doctor['registrations'] as List<dynamic>?) ?? []) {
            registrations.add({
              'councilController':
                  TextEditingController(text: reg['council']?.toString() ?? ''),
              'yearController':
                  TextEditingController(text: reg['year']?.toString() ?? ''),
            });
          }

          // --- Documents ---
          documentUrls['medicalDegree'] = [];
          documentUrls['medicalCouncil'] = [];
          documentUrls['identityProof'] = [];

          final uploads =
              (doctor['document_uploads'] as List<dynamic>?)?.cast<String>() ??
                  [];

          if (uploads.isNotEmpty) {
            if (uploads.isNotEmpty) {
              documentUrls['medicalDegree'] = [uploads[0]];
            }
            if (uploads.length > 1) {
              documentUrls['medicalCouncil'] = [uploads[1]];
            }
            if (uploads.length > 2) {
              documentUrls['identityProof'] = [uploads[2]];
            }
          }

          // --- User info ---
          final user = doctor['user'] as Map<String, dynamic>? ?? {};
          profileUrl.value = user['profile_image_name']?.toString() ?? '';
          userNameController.text = user['user_name']?.toString() ?? '';
          emailController.text = user['email']?.toString() ?? '';
          firstNameController.text = user['first_name']?.toString() ?? '';
          lastNameController.text = user['last_name']?.toString() ?? '';
          phoneController.text = user['phone_number']?.toString() ?? '';
          selectedGender.value = user['gender']?.toString() ?? '';
          birthdayController.text = user['birthday']?.toString() ?? '';
          biographyController.text = user['biography']?.toString() ?? '';

          update(['doctor-edit-profile']);
        } else {
          throw Exception('Doctor details not found in response');
        }
      } else {
        throw Exception('Failed to fetch doctor profile: ${response.body}');
      }
    } catch (e) {
      customToast('Error fetching doctor profile: $e', Colors.red);
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> updateUserProfile(
      Map<String, dynamic> userData, File? profileImage) async {
    final userId = await readStr('user_id') ?? '';
    print(userData);
    if (userId.isEmpty) {
      throw Exception('User ID is missing');
    }
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('${AppConstants.endpoint}/users/$userId'),
      );
      request.headers['Authorization'] =
          'Bearer ${await readStr('token') ?? ''}';
      request.headers['Content-Type'] = 'multipart/form-data';
      request.fields.addAll(
          userData.map((key, value) => MapEntry(key, value.toString())));
      if (profileImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'profile_image', profileImage.path));
      }
      final response = await request.send();
      if (response.statusCode == 200) {
        await saveStr('user_name', userData['user_name']?.toString() ?? '');
        await saveStr('first_name', userData['first_name']?.toString() ?? '');
        await saveStr('last_name', userData['last_name']?.toString() ?? '');
        await saveStr('email', userData['email']?.toString() ?? '');
        await saveStr(
            'phone_number', userData['phone_number']?.toString() ?? '');
        await saveStr('gender', userData['gender']?.toString() ?? '');
        await saveStr('birthday', userData['birthday']?.toString() ?? '');
        await saveStr('biography', userData['biography']?.toString() ?? '');
      } else {
        throw Exception(
            'Failed to update user profile: ${await response.stream.bytesToString()}');
      }
    } catch (e) {
      throw Exception('Error updating user profile: $e');
    }
  }

  Future<void> updateDoctorProfile(
    Map<String, dynamic> doctorData,
    Map<String, List<String>> documentUrls,
  ) async {
    final docId = await readStr('profileId') ?? '';
    if (docId.isEmpty) {
      throw Exception('Doctor ID is missing');
    }

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('${AppConstants.endpoint}/doctors/$docId'),
      );
      request.headers['Authorization'] =
          'Bearer ${await readStr('token') ?? ''}';
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add doctor data fields
      request.fields['medical_reg_no'] =
          doctorData['medical_reg_no'].toString();
      request.fields['is_surgeon'] = doctorData['is_surgeon'].toString();
      request.fields['pricing'] = jsonEncode(doctorData['pricing']);
      request.fields['services'] = jsonEncode(doctorData['services']);
      request.fields['specializations'] =
          jsonEncode(doctorData['specializations']);
      request.fields['education'] = jsonEncode(doctorData['education']);
      request.fields['experience'] = jsonEncode(doctorData['experience']);
      request.fields['languages_known'] =
          jsonEncode(doctorData['languages_known']);
      request.fields['awards'] = jsonEncode(doctorData['awards']);
      request.fields['memberships'] = jsonEncode(doctorData['memberships']);
      request.fields['registrations'] = jsonEncode(doctorData['registrations']);

      // Add document uploads (only local files, skip https URLs)
      for (var key in documentUrls.keys) {
        if (documentUrls[key]!.isNotEmpty) {
          for (var filePath in documentUrls[key]!) {
            if (!filePath.startsWith('http')) {
              // Only upload if it's a local file
              request.files.add(
                await http.MultipartFile.fromPath(
                  'document_uploads',
                  filePath,
                  filename: '$key.${filePath.split('.').last}',
                ),
              );
            } else {
              print("⏩ Skipping remote file for $key: $filePath");
            }
          }
        }
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);

        doctorCodeController.text = data['doctor_code']?.toString() ?? '';
        medicalRegNoController.text = data['medical_reg_no']?.toString() ?? '';
        isSurgeon.value = data['is_surgeon'] ?? false;

        // Update document URLs from response if needed
        documentUrls['medicalDegree'] =
            (data['document_uploads'] as List<dynamic>?)
                    ?.where((doc) => doc.contains('medicalDegree'))
                    .cast<String>()
                    .toList() ??
                [];
        documentUrls['medicalCouncil'] =
            (data['document_uploads'] as List<dynamic>?)
                    ?.where((doc) => doc.contains('medicalCouncil'))
                    .cast<String>()
                    .toList() ??
                [];
        documentUrls['identityProof'] =
            (data['document_uploads'] as List<dynamic>?)
                    ?.where((doc) => doc.contains('identityProof'))
                    .cast<String>()
                    .toList() ??
                [];

        update(['doctor-edit-profile']);
      } else {
        throw Exception('Failed: $responseBody');
      }
    } catch (e) {
      throw Exception('Error updating doctor profile: $e');
    }
  }
}
