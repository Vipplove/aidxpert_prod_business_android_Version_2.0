// screens/doctor/register_doctor_profile.dart
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/Get.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';
import '../../../data/static_data.dart';
import '../controllers/register_doctor_controller.dart';

class RegisterDoctorProfile extends StatefulWidget {
  const RegisterDoctorProfile({super.key});

  @override
  State<RegisterDoctorProfile> createState() => _RegisterDoctorProfileState();
}

class _RegisterDoctorProfileState extends State<RegisterDoctorProfile> {
  final ImagePicker _picker = ImagePicker();

  final GlobalKey<FormState> _step1Key = GlobalKey<FormState>();
  final GlobalKey<FormState> _step2Key = GlobalKey<FormState>();
  final GlobalKey<FormState> _step3Key = GlobalKey<FormState>();
  final GlobalKey<FormState> _step4Key = GlobalKey<FormState>();
  final GlobalKey<FormState> _step5Key = GlobalKey<FormState>();

  int _currentStep = 0;

  final controller = Get.find<RegisterDoctorController>();

  bool _validateCurrentStep() {
    final keys = [_step1Key, _step2Key, _step3Key, _step4Key, _step5Key];
    final currentKey = keys[_currentStep];
    return currentKey.currentState?.validate() ?? false;
  }

  bool _validateAllSteps() {
    return [_step1Key, _step2Key, _step3Key, _step4Key, _step5Key]
        .every((key) => key.currentState?.validate() ?? true);
  }

  bool _validateDocuments() {
    return controller.documentUrls['medicalDegree']?.isNotEmpty == true &&
        controller.documentUrls['medicalCouncil']?.isNotEmpty == true &&
        controller.documentUrls['identityProof']?.isNotEmpty == true;
  }

  Future<void> _saveProfile() async {
    if (!_validateAllSteps()) {
      customToast(
          "Please complete all required fields in previous steps", Colors.red);
      return;
    }
    if (!_validateDocuments()) {
      customToast("Please upload all required documents", Colors.red);
      return;
    }

    try {
      EasyLoading.show(status: 'Updating profile...');

      var isVerified = await readStr('isVerified');
      final userData = {
        'email': controller.emailController.text,
        'first_name': controller.firstNameController.text,
        'last_name': controller.lastNameController.text,
        'phone_number': controller.phoneController.text,
        'gender': controller.selectedGender.value,
        'birthday': controller.birthdayController.text,
        'biography': controller.biographyController.text,
        if (isVerified == 'pending') 'isVerified': 'processing',
        'role_id': '2',
      };

      final doctorData = {
        'medical_reg_no': controller.medicalRegNoController.text,
        'pricing': controller.pricing
            .map((p) => {
                  'type': p['typeController']!.text,
                  'price': int.tryParse(p['priceController']!.text) ?? 0,
                  'currency': 'INR',
                })
            .toList(),
        'services': controller.services.toList(),
        'specializations': controller.specializations.toList(),
        'education': controller.educations
            .map((e) => {
                  'degree': e['degreeController']!.text,
                  'college': e['instituteController']!.text,
                  'year_of_completion':
                      int.tryParse(e['yearOfCompletionController']!.text) ??
                          DateTime.now().year,
                })
            .toList(),
        'experience': controller.experiences
            .map((e) => {
                  'hospital_name': e['hospitalNameController']!.text,
                  'designation': e['designationController']!.text,
                  'from_date': '${e['fromController']!.text}-01-01T00:00:00Z',
                  'to_date': '${e['toController']!.text}-01-01T00:00:00Z',
                })
            .toList(),
        'languages_known': controller.languages.toList(),
        'awards': controller.awards
            .map((a) => {
                  'title': a['titleController']!.text,
                  'year': a['yearController']!.text,
                })
            .toList(),
        'memberships': controller.memberships
            .map((m) => {
                  'association': m['organizationController']!.text,
                })
            .toList(),
        'registrations': controller.registrations
            .map((r) => {
                  'council': r['councilController']!.text,
                  'year': r['yearController']!.text,
                })
            .toList(),
        'is_surgeon': controller.isSurgeon.value,
      };

      await controller.updateUserProfile(
        userData,
        controller.profileImagePath.value.isNotEmpty
            ? File(controller.profileImagePath.value)
            : null,
      );
      await controller.updateDoctorProfile(doctorData, controller.documentUrls);

      EasyLoading.dismiss();
      customToast("Profile updated successfully", Colors.green);

      Get.defaultDialog(
        title: 'Profile Updated',
        middleText:
            'Profile has been updated successfully and is under review.',
        textConfirm: "OK",
        confirmTextColor: Colors.white,
        onConfirm: () {
          Get.back();
          Get.back();
        },
      );
    } catch (e) {
      EasyLoading.dismiss();
      customToast("Failed to update profile: $e", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSize = screenWidth < 400 ? 14.0 : 16.0;

    return Scaffold(
      backgroundColor: AppConstants.appScaffoldBgColor,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppConstants.appPrimaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text("Edit Profile",
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(60),
              bottomRight: Radius.circular(60)),
        ),
      ),
      body: GetBuilder<RegisterDoctorController>(
        id: 'doctor-edit-profile',
        initState: (state) =>
            controller.fetchDoctorProfile(Get.arguments['id'].toString()),
        builder: (ctrl) {
          if (ctrl.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            physics: const BouncingScrollPhysics(),
            onStepContinue: () {
              if (_currentStep < 4) {
                if (_validateCurrentStep()) {
                  setState(() => _currentStep += 1);
                } else {
                  customToast("Please fill all required fields in this step",
                      Colors.red);
                }
              } else {
                _saveProfile();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep -= 1);
              }
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                                color: AppConstants.appPrimaryColor, width: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Previous',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppConstants.appPrimaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _currentStep == 4 ? 'Save' : 'Next',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Personal'),
                content:
                    Form(key: _step1Key, child: _buildStep1(ctrl, fontSize)),
                isActive: _currentStep >= 0,
                state:
                    _currentStep > 0 ? StepState.complete : StepState.editing,
              ),
              Step(
                title: const Text('Professional'),
                content:
                    Form(key: _step2Key, child: _buildStep2(ctrl, fontSize)),
                isActive: _currentStep >= 1,
                state:
                    _currentStep > 1 ? StepState.complete : StepState.editing,
              ),
              Step(
                title: const Text('Services'),
                content:
                    Form(key: _step3Key, child: _buildStep3(ctrl, fontSize)),
                isActive: _currentStep >= 2,
                state:
                    _currentStep > 2 ? StepState.complete : StepState.editing,
              ),
              Step(
                title: const Text('Experience'),
                content:
                    Form(key: _step4Key, child: _buildStep4(ctrl, fontSize)),
                isActive: _currentStep >= 3,
                state:
                    _currentStep > 3 ? StepState.complete : StepState.editing,
              ),
              Step(
                title: const Text('Documents'),
                content: Form(
                    key: _step5Key,
                    child: _buildStep5(context, ctrl, fontSize)),
                isActive: _currentStep >= 4,
                state:
                    _currentStep == 4 ? StepState.editing : StepState.complete,
              ),
            ],
          );
        },
      ),
    );
  }

  // All step content methods remain the same as in previous version
  // Just copy them here without changes

  Widget _buildStep1(RegisterDoctorController ctrl, double fontSize) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  child: Obx(
                    () => ctrl.profileImagePath.value.isNotEmpty
                        ? ClipOval(
                            child: Image.file(
                              File(ctrl.profileImagePath.value),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          )
                        : ctrl.profileUrl.value.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: ctrl.profileUrl.value,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                  errorWidget: (context, url, error) =>
                                      Image.asset('assets/image/doctor.png',
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover),
                                ),
                              )
                            : Icon(Icons.person,
                                size: 60, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton.icon(
                  onPressed: () async {
                    final XFile? image =
                        await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      final file = File(image.path);
                      if (await file.length() > 2 * 1024 * 1024) {
                        customToast(
                            "Profile image must be less than 2MB", Colors.red);
                        return;
                      }
                      ctrl.setProfileImage(image);
                    }
                  },
                  icon: const Icon(Icons.upload, size: 20),
                  label: Text('Upload Photo (JPG, GIF, PNG, Max 2MB)',
                      style: TextStyle(
                          fontSize: fontSize,
                          color: AppConstants.appPrimaryColor)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          TextFormField(
            readOnly: true,
            controller: ctrl.userNameController,
            style: TextStyle(fontSize: fontSize),
            decoration: inputFieldDecoration(
                'Username*',
                '',
                Icon(Icons.person_outline,
                    color: AppConstants.appPrimaryColor, size: 20)),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: ctrl.firstNameController,
            style: TextStyle(fontSize: fontSize),
            keyboardType: TextInputType.name,
            decoration: inputFieldDecoration(
                'First Name*',
                '',
                Icon(Icons.person_outline,
                    color: AppConstants.appPrimaryColor, size: 20)),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: ctrl.lastNameController,
            style: TextStyle(fontSize: fontSize),
            keyboardType: TextInputType.name,
            decoration: inputFieldDecoration(
                'Last Name*',
                '',
                Icon(Icons.person_outline,
                    color: AppConstants.appPrimaryColor, size: 20)),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: ctrl.emailController,
            style: TextStyle(fontSize: fontSize),
            keyboardType: TextInputType.emailAddress,
            decoration: inputFieldDecoration(
                'Email*',
                '',
                Icon(Icons.email_outlined,
                    color: AppConstants.appPrimaryColor, size: 20)),
            validator: (value) =>
                (value?.isEmpty ?? true) || !value!.contains('@')
                    ? 'Enter a valid email'
                    : null,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: ctrl.phoneController,
            style: TextStyle(fontSize: fontSize),
            keyboardType: TextInputType.phone,
            decoration: inputFieldDecoration(
                'Phone Number*',
                '',
                Icon(Icons.phone_outlined,
                    color: AppConstants.appPrimaryColor, size: 20)),
            validator: (value) => (value?.isEmpty ?? true) || value!.length < 10
                ? 'Enter a valid phone number'
                : null,
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: ctrl.selectedGender.value.isEmpty
                ? null
                : ctrl.selectedGender.value,
            decoration: inputFieldDecoration(
                'Gender*',
                '',
                Icon(Icons.wc_outlined,
                    color: AppConstants.appPrimaryColor, size: 20)),
            items: ['Male', 'Female', 'Other']
                .map((gender) => DropdownMenuItem(
                    value: gender,
                    child: Text(gender, style: TextStyle(fontSize: fontSize))))
                .toList(),
            onChanged: (value) {
              if (value != null) ctrl.setGender(value);
            },
            validator: (value) => value == null ? 'Required' : null,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: ctrl.birthdayController,
            readOnly: true,
            style: TextStyle(fontSize: fontSize),
            decoration: inputFieldDecoration(
                'Birthday*',
                '',
                Icon(Icons.calendar_today_outlined,
                    color: AppConstants.appPrimaryColor, size: 20)),
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (pickedDate != null) {
                ctrl.birthdayController.text =
                    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
              }
            },
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: ctrl.biographyController,
            style: TextStyle(fontSize: fontSize),
            maxLines: 4,
            decoration: inputFieldDecoration(
                'Biography*',
                '',
                Icon(Icons.info_outline,
                    color: AppConstants.appPrimaryColor, size: 20)),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStep2(RegisterDoctorController ctrl, double fontSize) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            readOnly: false,
            controller: ctrl.doctorCodeController,
            style: TextStyle(fontSize: fontSize),
            decoration: inputFieldDecoration(
                'Doctor Code*',
                '',
                Icon(Icons.code,
                    color: AppConstants.appPrimaryColor, size: 20)),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: ctrl.medicalRegNoController,
            style: TextStyle(fontSize: fontSize),
            decoration: inputFieldDecoration(
                'Medical Registration Number*',
                '',
                Icon(Icons.verified_user_outlined,
                    color: AppConstants.appPrimaryColor, size: 20)),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 15),
          Obx(() => SwitchListTile(
                title: Text('Is Surgeon',
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.w600)),
                value: ctrl.isSurgeon.value,
                onChanged: (value) => ctrl.setIsSurgeon(value),
                activeColor: AppConstants.appPrimaryColor,
                contentPadding: EdgeInsets.zero,
              )),
          const SizedBox(height: 15),
          const Text('Pricing',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 10),
          Obx(() => Column(
                children: [
                  for (int i = 0; i < ctrl.pricing.length; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          DropdownButtonFormField<String>(
                            value:
                                ctrl.pricing[i]['typeController']!.text.isEmpty
                                    ? null
                                    : ctrl.pricing[i]['typeController']!.text,
                            decoration: inputFieldDecoration(
                                'Type*',
                                '',
                                Icon(Icons.medical_services_outlined,
                                    color: AppConstants.appPrimaryColor,
                                    size: 20)),
                            items: [
                              'ClinicVisit',
                              'VideoConsultation',
                              'TeleConsultation'
                            ]
                                .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type,
                                        style: TextStyle(fontSize: fontSize))))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                ctrl.pricing[i]['typeController']!.text = value;
                                ctrl.update(['doctor-edit-profile']);
                              }
                            },
                            validator: (value) =>
                                value == null ? 'Required' : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: ctrl.pricing[i]['priceController']!,
                            style: TextStyle(fontSize: fontSize),
                            keyboardType: TextInputType.number,
                            decoration: inputFieldDecoration(
                                'Price*',
                                '',
                                Icon(Icons.monetization_on_outlined,
                                    color: AppConstants.appPrimaryColor,
                                    size: 20)),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          if (ctrl.pricing.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                ctrl.pricing[i]['typeController']!.dispose();
                                ctrl.pricing[i]['priceController']!.dispose();
                                ctrl.pricing.removeAt(i);
                                ctrl.update(['doctor-edit-profile']);
                              },
                            ),
                        ],
                      ),
                    ),
                  if (ctrl.pricing.isEmpty)
                    const Text('At least one pricing entry is required',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              )),
          TextButton.icon(
            onPressed: ctrl.addPricing,
            icon: const Icon(Icons.add, size: 20),
            label: Text('Add Pricing',
                style: TextStyle(
                    fontSize: fontSize, color: AppConstants.appPrimaryColor)),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildStep3(RegisterDoctorController ctrl, double fontSize) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Services',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl.serviceSearchController,
            readOnly: true,
            style: TextStyle(fontSize: fontSize),
            decoration: inputFieldDecoration(
                '',
                'Services*',
                Icon(Icons.search,
                    color: AppConstants.appPrimaryColor, size: 20)),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => MultiSelectDialog(
                  height: 500,
                  width: Get.width * 0.9,
                  items: ctrl.availableServices
                      .map((service) =>
                          MultiSelectItem<String>(service, service))
                      .toList(),
                  initialValue: ctrl.services.toList(),
                  title: const Text('Select Services'),
                  confirmText: Text('OK',
                      style: TextStyle(color: AppConstants.appPrimaryColor)),
                  cancelText: Text('Cancel',
                      style: TextStyle(color: AppConstants.appPrimaryColor)),
                ),
              ).then((selected) {
                if (selected != null)
                  ctrl.addSelectedServices(selected.cast<String>());
              });
            },
            validator: (value) => ctrl.services.isEmpty
                ? 'At least one service is required'
                : null,
          ),
          const SizedBox(height: 15),
          Obx(() => Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: ctrl.services
                    .map((service) => Chip(
                          label: Text(service,
                              style: TextStyle(fontSize: fontSize)),
                          deleteIcon: const Icon(Icons.cancel, size: 20),
                          onDeleted: () => ctrl.removeService(service),
                          backgroundColor:
                              AppConstants.appPrimaryColor.withOpacity(0.1),
                        ))
                    .toList(),
              )),
          const SizedBox(height: 16),
          const Text('Specializations',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl.specializationController,
            readOnly: true,
            style: TextStyle(fontSize: fontSize),
            decoration: inputFieldDecoration(
                '',
                'Specializations*',
                Icon(Icons.search,
                    color: AppConstants.appPrimaryColor, size: 20)),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => MultiSelectDialog(
                  height: 500,
                  width: Get.width * 0.9,
                  items: ctrl.availableSpecializations
                      .map((spec) => MultiSelectItem<String>(spec, spec))
                      .toList(),
                  initialValue: ctrl.specializations.toList(),
                  title: const Text('Select Specializations'),
                  confirmText: Text('OK',
                      style: TextStyle(color: AppConstants.appPrimaryColor)),
                  cancelText: Text('Cancel',
                      style: TextStyle(color: AppConstants.appPrimaryColor)),
                ),
              ).then((selected) {
                if (selected != null)
                  ctrl.addSelectedSpecializations(selected.cast<String>());
              });
            },
            validator: (value) => ctrl.specializations.isEmpty
                ? 'At least one specialization is required'
                : null,
          ),
          const SizedBox(height: 15),
          Obx(() => Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: ctrl.specializations
                    .map((spec) => Chip(
                          label:
                              Text(spec, style: TextStyle(fontSize: fontSize)),
                          deleteIcon: const Icon(Icons.cancel, size: 20),
                          onDeleted: () => ctrl.removeSpecialization(spec),
                          backgroundColor:
                              AppConstants.appPrimaryColor.withOpacity(0.1),
                        ))
                    .toList(),
              )),
          const SizedBox(height: 16),
          const Text('Languages',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl.languageSearchController,
            readOnly: true,
            style: TextStyle(fontSize: fontSize),
            decoration: inputFieldDecoration(
                '',
                'Languages*',
                Icon(Icons.language,
                    color: AppConstants.appPrimaryColor, size: 20)),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => MultiSelectDialog(
                  height: 500,
                  width: Get.width * 0.9,
                  items: availableLanguages
                      .map((lang) => MultiSelectItem<String>(lang, lang))
                      .toList(),
                  initialValue: ctrl.languages.toList(),
                  title: const Text('Select Languages'),
                  confirmText: Text('OK',
                      style: TextStyle(color: AppConstants.appPrimaryColor)),
                  cancelText: Text('Cancel',
                      style: TextStyle(color: AppConstants.appPrimaryColor)),
                ),
              ).then((selected) {
                if (selected != null)
                  ctrl.addSelectedLanguages(selected.cast<String>());
              });
            },
            validator: (value) => ctrl.languages.isEmpty
                ? 'At least one language is required'
                : null,
          ),
          const SizedBox(height: 15),
          Obx(() => Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: ctrl.languages
                    .map((lang) => Chip(
                          label:
                              Text(lang, style: TextStyle(fontSize: fontSize)),
                          deleteIcon: const Icon(Icons.cancel, size: 20),
                          onDeleted: () => ctrl.removeLanguage(lang),
                          backgroundColor:
                              AppConstants.appPrimaryColor.withOpacity(0.1),
                        ))
                    .toList(),
              )),
          const SizedBox(height: 16),
          const Text('Education',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 10),
          Obx(() => Column(
                children: [
                  for (int i = 0; i < ctrl.educations.length; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextFormField(
                            controller: ctrl.educations[i]['degreeController']!,
                            style: TextStyle(fontSize: fontSize),
                            decoration: inputFieldDecoration(
                                'Degree*',
                                '',
                                Icon(Icons.school_outlined,
                                    color: AppConstants.appPrimaryColor,
                                    size: 20)),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: ctrl.educations[i]
                                ['instituteController']!,
                            style: TextStyle(fontSize: fontSize),
                            decoration: inputFieldDecoration(
                                'Institute*',
                                '',
                                Icon(Icons.location_city_outlined,
                                    color: AppConstants.appPrimaryColor,
                                    size: 20)),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 15),
                          DropdownButtonFormField<int>(
                            value: int.tryParse(ctrl
                                    .educations[i]
                                        ['yearOfCompletionController']!
                                    .text) ??
                                DateTime.now().year,
                            decoration: inputFieldDecoration(
                                'Year of Completion*',
                                '',
                                Icon(Icons.calendar_today_outlined,
                                    color: AppConstants.appPrimaryColor,
                                    size: 20)),
                            items: List.generate(106, (index) => 1925 + index)
                                .map((year) => DropdownMenuItem<int>(
                                    value: year,
                                    child: Text(year.toString(),
                                        style: TextStyle(fontSize: fontSize))))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                ctrl
                                    .educations[i]
                                        ['yearOfCompletionController']!
                                    .text = value.toString();
                                ctrl.update(['doctor-edit-profile']);
                              }
                            },
                            validator: (value) =>
                                value == null ? 'Required' : null,
                          ),
                          if (ctrl.educations.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                ctrl.educations[i]['degreeController']!
                                    .dispose();
                                ctrl.educations[i]['instituteController']!
                                    .dispose();
                                ctrl.educations[i]
                                        ['yearOfCompletionController']!
                                    .dispose();
                                ctrl.educations.removeAt(i);
                                ctrl.update(['doctor-edit-profile']);
                              },
                            ),
                        ],
                      ),
                    ),
                  if (ctrl.educations.isEmpty)
                    const Text('At least one education entry is required',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              )),
          TextButton.icon(
            onPressed: ctrl.addEducation,
            icon: const Icon(Icons.add, size: 20),
            label: Text('Add Education',
                style: TextStyle(
                    fontSize: fontSize, color: AppConstants.appPrimaryColor)),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildStep4(RegisterDoctorController ctrl, double fontSize) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Experience',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 10),
          Obx(() => Column(
                children: [
                  for (int i = 0; i < ctrl.experiences.length; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextFormField(
                            controller: ctrl.experiences[i]
                                ['hospitalNameController']!,
                            style: TextStyle(fontSize: fontSize),
                            decoration: inputFieldDecoration(
                                'Hospital Name*',
                                '',
                                Icon(Icons.local_hospital_outlined,
                                    color: AppConstants.appPrimaryColor,
                                    size: 20)),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: ctrl.experiences[i]
                                ['designationController']!,
                            style: TextStyle(fontSize: fontSize),
                            decoration: inputFieldDecoration(
                                'Designation*',
                                '',
                                Icon(Icons.work_outline,
                                    color: AppConstants.appPrimaryColor,
                                    size: 20)),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 15),
                          DropdownButtonFormField<int>(
                            value: int.tryParse(ctrl
                                    .experiences[i]['fromController']!.text) ??
                                DateTime.now().year,
                            decoration: inputFieldDecoration(
                                'From Year*',
                                '',
                                Icon(Icons.calendar_today_outlined,
                                    color: AppConstants.appPrimaryColor,
                                    size: 20)),
                            items: List.generate(106, (index) => 1925 + index)
                                .map((year) => DropdownMenuItem<int>(
                                    value: year,
                                    child: Text(year.toString(),
                                        style: TextStyle(fontSize: fontSize))))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                ctrl.experiences[i]['fromController']!.text =
                                    value.toString();
                                ctrl.update(['doctor-edit-profile']);
                              }
                            },
                            validator: (value) =>
                                value == null ? 'Required' : null,
                          ),
                          const SizedBox(height: 15),
                          DropdownButtonFormField<int>(
                            value: int.tryParse(ctrl
                                    .experiences[i]['toController']!.text) ??
                                DateTime.now().year,
                            decoration: inputFieldDecoration(
                                'To Year*',
                                '',
                                Icon(Icons.calendar_today_outlined,
                                    color: AppConstants.appPrimaryColor,
                                    size: 20)),
                            items: List.generate(106, (index) => 1925 + index)
                                .map((year) => DropdownMenuItem<int>(
                                    value: year,
                                    child: Text(year.toString(),
                                        style: TextStyle(fontSize: fontSize))))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                ctrl.experiences[i]['toController']!.text =
                                    value.toString();
                                ctrl.update(['doctor-edit-profile']);
                              }
                            },
                            validator: (value) =>
                                value == null ? 'Required' : null,
                          ),
                          if (ctrl.experiences.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                ctrl.experiences[i]['hospitalNameController']!
                                    .dispose();
                                ctrl.experiences[i]['designationController']!
                                    .dispose();
                                ctrl.experiences[i]['fromController']!
                                    .dispose();
                                ctrl.experiences[i]['toController']!.dispose();
                                ctrl.experiences.removeAt(i);
                                ctrl.update(['doctor-edit-profile']);
                              },
                            ),
                        ],
                      ),
                    ),
                  if (ctrl.experiences.isEmpty)
                    const Text('At least one experience entry is required',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              )),
          TextButton.icon(
            onPressed: ctrl.addExperience,
            icon: const Icon(Icons.add, size: 20),
            label: Text('Add Experience',
                style: TextStyle(
                    fontSize: fontSize, color: AppConstants.appPrimaryColor)),
          ),
          const SizedBox(height: 15),
          const Text('Awards',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 10),
          Obx(() => Column(
                children: [
                  for (int i = 0; i < ctrl.awards.length; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextFormField(
                            controller: ctrl.awards[i]['titleController']!,
                            style: TextStyle(fontSize: fontSize),
                            decoration: inputFieldDecoration(
                                'Award Title*',
                                '',
                                Icon(Icons.card_giftcard_outlined,
                                    color: AppConstants.appPrimaryColor,
                                    size: 20)),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 15),
                          DropdownButtonFormField<int>(
                            value: int.tryParse(
                                    ctrl.awards[i]['yearController']!.text) ??
                                DateTime.now().year,
                            decoration: inputFieldDecoration(
                                'Year*',
                                '',
                                Icon(Icons.calendar_today_outlined,
                                    color: AppConstants.appPrimaryColor,
                                    size: 20)),
                            items: List.generate(106, (index) => 1925 + index)
                                .map((year) => DropdownMenuItem<int>(
                                    value: year,
                                    child: Text(year.toString(),
                                        style: TextStyle(fontSize: fontSize))))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                ctrl.awards[i]['yearController']!.text =
                                    value.toString();
                                ctrl.update(['doctor-edit-profile']);
                              }
                            },
                            validator: (value) =>
                                value == null ? 'Required' : null,
                          ),
                          if (ctrl.awards.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                ctrl.awards[i]['titleController']!.dispose();
                                ctrl.awards[i]['yearController']!.dispose();
                                ctrl.awards.removeAt(i);
                                ctrl.update(['doctor-edit-profile']);
                              },
                            ),
                        ],
                      ),
                    ),
                  if (ctrl.awards.isEmpty)
                    const Text('At least one award entry is required',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              )),
          TextButton.icon(
            onPressed: ctrl.addAward,
            icon: const Icon(Icons.add, size: 20),
            label: Text('Add Award',
                style: TextStyle(
                    fontSize: fontSize, color: AppConstants.appPrimaryColor)),
          ),
          const SizedBox(height: 15),
          const Text('Memberships',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 10),
          Obx(() => Column(
                children: [
                  for (int i = 0; i < ctrl.memberships.length; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextFormField(
                            controller: ctrl.memberships[i]
                                ['organizationController']!,
                            style: TextStyle(fontSize: fontSize),
                            decoration: inputFieldDecoration(
                                'Organization*',
                                '',
                                Icon(Icons.group_outlined,
                                    color: AppConstants.appPrimaryColor,
                                    size: 20)),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          if (ctrl.memberships.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                ctrl.memberships[i]['organizationController']!
                                    .dispose();
                                ctrl.memberships.removeAt(i);
                                ctrl.update(['doctor-edit-profile']);
                              },
                            ),
                        ],
                      ),
                    ),
                  if (ctrl.memberships.isEmpty)
                    const Text('At least one membership entry is required',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              )),
          TextButton.icon(
            onPressed: ctrl.addMembership,
            icon: const Icon(Icons.add, size: 20),
            label: Text('Add Membership',
                style: TextStyle(
                    fontSize: fontSize, color: AppConstants.appPrimaryColor)),
          ),
          const SizedBox(height: 15),
          const Text('Registrations',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 10),
          Obx(() => Column(
                children: [
                  for (int i = 0; i < ctrl.registrations.length; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextFormField(
                            controller: ctrl.registrations[i]
                                ['councilController']!,
                            style: TextStyle(fontSize: fontSize),
                            decoration: inputFieldDecoration(
                                'Council*',
                                '',
                                Icon(Icons.verified_outlined,
                                    color: AppConstants.appPrimaryColor,
                                    size: 20)),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 15),
                          DropdownButtonFormField<int>(
                            value: int.tryParse(ctrl
                                    .registrations[i]['yearController']!
                                    .text) ??
                                DateTime.now().year,
                            decoration: inputFieldDecoration(
                                'Year*',
                                '',
                                Icon(Icons.calendar_today_outlined,
                                    color: AppConstants.appPrimaryColor,
                                    size: 20)),
                            items: List.generate(106, (index) => 1925 + index)
                                .map((year) => DropdownMenuItem<int>(
                                    value: year,
                                    child: Text(year.toString(),
                                        style: TextStyle(fontSize: fontSize))))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                ctrl.registrations[i]['yearController']!.text =
                                    value.toString();
                                ctrl.update(['doctor-edit-profile']);
                              }
                            },
                            validator: (value) =>
                                value == null ? 'Required' : null,
                          ),
                          if (ctrl.registrations.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                ctrl.registrations[i]['councilController']!
                                    .dispose();
                                ctrl.registrations[i]['yearController']!
                                    .dispose();
                                ctrl.registrations.removeAt(i);
                                ctrl.update(['doctor-edit-profile']);
                              },
                            ),
                        ],
                      ),
                    ),
                  if (ctrl.registrations.isEmpty)
                    const Text('At least one registration entry is required',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              )),
          TextButton.icon(
            onPressed: ctrl.addRegistration,
            icon: const Icon(Icons.add, size: 20),
            label: Text('Add Registration',
                style: TextStyle(
                    fontSize: fontSize, color: AppConstants.appPrimaryColor)),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildStep5(
      BuildContext context, RegisterDoctorController ctrl, double fontSize) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            color: Colors.yellow[50],
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Document Guidelines',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 5),
                Text(
                  '• All documents must be clear legible scanned copies or high quality photos\n'
                  '• Maximum file size: 5MB per document\n'
                  '• Allowed formats: PDF, JPG, PNG\n'
                  '• Documents should be in color and not black & white\n'
                  '• Ensure all text in the documents is clearly visible',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          _buildDocumentUploadField(
              context: context,
              ctrl: ctrl,
              label: 'Medical Degree Certificate*',
              hint: 'PDF, JPG or PNG (Max. 5MB)',
              documentKey: 'medicalDegree',
              fontSize: fontSize),
          const SizedBox(height: 15),
          _buildDocumentUploadField(
              context: context,
              ctrl: ctrl,
              label: 'Medical Council Registration Certificate*',
              hint: 'PDF, JPG or PNG (Max. 5MB)',
              documentKey: 'medicalCouncil',
              fontSize: fontSize),
          const SizedBox(height: 15),
          _buildDocumentUploadField(
              context: context,
              ctrl: ctrl,
              label: 'Identity Proof*',
              hint: 'PDF, JPG or PNG (Max. 5MB)',
              documentKey: 'identityProof',
              fontSize: fontSize),
          const SizedBox(height: 10),
          const Text(
            'All uploaded documents will be verified by our team. Any discrepancy in the documents may result in rejection of your registration. Please ensure all documents are genuine and valid.',
            style: TextStyle(fontSize: 14, color: Colors.blue),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadField({
    required BuildContext context,
    required RegisterDoctorController ctrl,
    required String label,
    required String hint,
    required String documentKey,
    required double fontSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () async {
            await ctrl.pickDocument(documentKey: documentKey);
          },
          child: Container(
            height: 100,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: Obx(() {
                String? filePath =
                    ctrl.documentUrls[documentKey]?.isNotEmpty == true
                        ? ctrl.documentUrls[documentKey]![0]
                        : null;
                if (filePath != null) {
                  final isUrl = filePath.startsWith('http');
                  final extension = filePath.toLowerCase().split('.').last;
                  final isPdf = extension == 'pdf';
                  return Stack(
                    children: [
                      Center(
                        child: isPdf
                            ? const Icon(Icons.picture_as_pdf,
                                size: 80, color: Colors.red)
                            : isUrl
                                ? CachedNetworkImage(
                                    imageUrl: filePath,
                                    fit: BoxFit.contain,
                                    height: 80,
                                    placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2)),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error,
                                            size: 80, color: Colors.red),
                                  )
                                : Image.file(File(filePath),
                                    fit: BoxFit.contain, height: 80),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => ctrl.removeDocument(documentKey),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload_outlined,
                          size: 30, color: Colors.grey),
                      const SizedBox(height: 5),
                      const Text('Click to upload or drag and drop',
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
                      Text(hint,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  );
                }
              }),
            ),
          ),
        ),
        Obx(() => ctrl.documentUrls[documentKey]?.isNotEmpty == true
            ? const SizedBox.shrink()
            : const Text('Required',
                style: TextStyle(color: Colors.red, fontSize: 12))),
      ],
    );
  }

  InputDecoration inputFieldDecoration(
      String label, String hint, Icon prefixIcon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: AppConstants.appPrimaryColor, width: 2)),
    );
  }
}
