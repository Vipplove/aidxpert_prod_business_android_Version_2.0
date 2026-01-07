// lib/app/modules/caretaker/views/caretaker_provider_registration.dart
// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/client_side_validation.dart';
import '../../../../../utils/helper.dart';
import '../../../components/image_viewer.dart';
import '../../component/caretaker_bottom_navbar.dart';
import '../controllers/caretaker_provider_registration_controller.dart';

class CaretakerProviderRegistration
    extends GetView<CaretakerProviderRegistrationController> {
  CaretakerProviderRegistration({super.key});

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    var type = Get.arguments['type'] ?? 'update';

    // Load data from API on update mode
    Future.microtask(
        () => controller.loadDataIfUpdate(Get.arguments['id'].toString()));

    return WillPopScope(
      onWillPop: () async {
        if (type == 'update' || type == 'create') {
          return true;
        } else {
          await onWillPop(context);
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: AppConstants.appPrimaryColor,
          foregroundColor: Colors.white,
          title: Text(
            type == 'update'
                ? 'Update Caretaker Provider'
                : 'Register Caretaker Provider',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (type != 'update' && type != 'create') {
                await onWillPop(Get.context!);
              } else {
                Get.back();
              }
            },
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        body: GetBuilder<CaretakerProviderRegistrationController>(
          id: 'caretaker-form',
          builder: (ctrl) {
            if (ctrl.isLoading.value && type == 'update') {
              return const Center(child: CircularProgressIndicator());
            }

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  // Account Information - Only for new registration
                  if (type != 'update') ...[
                    _buildSectionHeader('Account Information'),
                    _buildTextField(
                      label: 'Phone Number *',
                      controller: ctrl.phoneController,
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (v) => Validators.validMobileno(v!),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Email Address (Optional)',
                      controller: ctrl.emailController,
                      icon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v!.isEmpty ? null : (Validators.validEmail(v)),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Password *',
                      controller: ctrl.passwordController,
                      icon: Icons.lock_rounded,
                      obscureText: true,
                      validator: (v) => Validators.validPassword(v!),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Logo
                  _buildSectionHeader('Caretaker Provider Logo *'),
                  _buildLogoSection(ctrl),
                  const SizedBox(height: 32),

                  // Provider Information
                  _buildSectionHeader('Provider Information'),
                  _buildTextField(
                    label: 'Registered Name *',
                    controller: ctrl.nameController,
                    icon: Icons.business_rounded,
                    validator: (v) =>
                        Validators.validRequired(v!, 'Provider Name', min: 3),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'License Number *',
                    controller: ctrl.licenseController,
                    icon: Icons.verified_user_rounded,
                    validator: (v) =>
                        Validators.validRequired(v!, 'License Number'),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'License Expiry Date *',
                    controller: ctrl.expiryController,
                    icon: Icons.calendar_today_rounded,
                    readOnly: true,
                    onTap: () => ctrl.pickExpiryDate(context),
                    validator: (v) =>
                        Validators.validRequired(v!, 'Expiry Date'),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Emergency Contact *',
                    controller: ctrl.emergencyPhoneController,
                    icon: Icons.phone_in_talk_rounded,
                    keyboardType: TextInputType.phone,
                    validator: (v) => Validators.validMobileno(v!),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.call, color: Colors.green),
                      onPressed: () {
                        final phone = ctrl.emergencyPhoneController.text.trim();
                        if (phone.isNotEmpty)
                          launchUrl(Uri.parse('tel:$phone'));
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Total Caretakers Available *',
                    controller: ctrl.totalCaretakersController,
                    icon: Icons.people_alt_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final n = int.tryParse(v);
                      return n != null && n > 0
                          ? null
                          : 'Must be greater than 0';
                    },
                  ),
                  const SizedBox(height: 32),

                  // Service Radius
                  _buildSectionHeader('Service Coverage'),
                  const Text('Service Area Radius (km) *',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 15),
                  Obx(() => Column(
                        children: [
                          Slider(
                            value: ctrl.serviceRadius.value,
                            min: 5,
                            max: 100,
                            divisions: 19,
                            label: '${ctrl.serviceRadius.value.toInt()} km',
                            activeColor: AppConstants.appPrimaryColor,
                            onChanged: (v) => ctrl.serviceRadius.value = v,
                          ),
                          Text(
                              '${ctrl.serviceRadius.value.toInt()} km coverage area',
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.blueGrey)),
                        ],
                      )),
                  const SizedBox(height: 32),

                  // Caretaker Types
                  const Text('Caretaker Types Offered *',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Obx(() => Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: ctrl.caretakerTypes.map((type) {
                          final selected = ctrl.selectedTypes.contains(type);
                          return FilterChip(
                            label: Text(type),
                            selected: selected,
                            onSelected: (_) => ctrl.toggleType(type),
                            selectedColor:
                                AppConstants.appPrimaryColor.withOpacity(0.2),
                            checkmarkColor: AppConstants.appPrimaryColor,
                            backgroundColor: Colors.grey[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: BorderSide(
                                  color: selected
                                      ? AppConstants.appPrimaryColor
                                      : Colors.grey.shade400),
                            ),
                          );
                        }).toList(),
                      )),
                  if (ctrl.selectedTypes.isEmpty)
                    const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Select at least one type',
                            style: TextStyle(color: Colors.red))),
                  const SizedBox(height: 32),

                  // Pricing
                  _buildSectionHeader('Pricing Per Day (INR) *'),
                  Obx(() {
                    if (ctrl.selectedTypes.isEmpty) {
                      return const Text(
                          'Select caretaker types above to set pricing',
                          style: TextStyle(color: Colors.orangeAccent));
                    }
                    return Column(
                      children: ctrl.selectedTypes.map((type) {
                        final priceCtrl = ctrl.pricingControllers[type]!;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 3))
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.currency_rupee_rounded,
                                  color: AppConstants.appPrimaryColor),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text('$type (Per Day)',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600))),
                              SizedBox(
                                width: 140,
                                child: TextFormField(
                                  controller: priceCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Price',
                                    prefixText: '₹ ',
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Required';
                                    final p = int.tryParse(v);
                                    return p != null && p >= 200
                                        ? null
                                        : 'Min ₹200';
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }),
                  const SizedBox(height: 32),

                  // Specializations & Accreditations
                  const Text('Specialization Areas (Optional)',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Obx(() => Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: ctrl.specializations.map((s) {
                          final sel = ctrl.selectedSpecializations.contains(s);
                          return FilterChip(
                            label: Text(s),
                            selected: sel,
                            onSelected: (_) => ctrl.toggleSpecialization(s),
                            selectedColor: Colors.purple.withOpacity(0.2),
                            checkmarkColor: Colors.purple,
                            backgroundColor: Colors.grey[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: BorderSide(
                                  color: sel
                                      ? Colors.purple
                                      : Colors.grey.shade400),
                            ),
                          );
                        }).toList(),
                      )),
                  const SizedBox(height: 32),

                  const Text('Accreditations (Optional)',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Obx(() => Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: ctrl.accreditations.map((a) {
                          final sel = ctrl.selectedAccreditations.contains(a);
                          return FilterChip(
                            label: Text(a),
                            selected: sel,
                            onSelected: (_) => ctrl.toggleAccreditation(a),
                            selectedColor: Colors.teal.withOpacity(0.2),
                            checkmarkColor: Colors.teal,
                            backgroundColor: Colors.grey[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: BorderSide(
                                  color:
                                      sel ? Colors.teal : Colors.grey.shade400),
                            ),
                          );
                        }).toList(),
                      )),
                  const SizedBox(height: 32),

                  // Operating Hours
                  _buildSectionHeader('Operating Hours *'),
                  Obx(() => Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              RadioListTile<bool>(
                                title: const Text('24/7 Available',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                value: true,
                                groupValue: ctrl.is24x7.value,
                                onChanged: (v) => ctrl.is24x7.value = true,
                                activeColor: AppConstants.appPrimaryColor,
                              ),
                              RadioListTile<bool>(
                                title: const Text('Custom Hours'),
                                value: false,
                                groupValue: ctrl.is24x7.value,
                                onChanged: (v) => ctrl.is24x7.value = false,
                                activeColor: AppConstants.appPrimaryColor,
                              ),
                              if (!ctrl.is24x7.value)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: TextFormField(
                                    controller: ctrl.customHoursController,
                                    maxLines: 4,
                                    decoration: InputDecoration(
                                      hintText:
                                          'e.g.,\nMon-Sat: 08:00 AM - 08:00 PM\nSun: 09:00 AM - 02:00 PM',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    validator: (v) => v?.trim().isEmpty == true
                                        ? 'Enter operating hours'
                                        : null,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: 32),

                  // Address
                  _buildSectionHeader('Service Address'),
                  _buildTextField(
                    label: 'Full Address *',
                    controller: ctrl.addressController,
                    icon: Icons.location_on_rounded,
                    maxLines: 3,
                    validator: (v) =>
                        Validators.validRequired(v!, 'Address', min: 10),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                        child: _buildTextField(
                            label: 'City *',
                            controller: ctrl.cityController,
                            icon: Icons.location_city_rounded,
                            validator: (v) =>
                                Validators.validRequired(v!, 'City'))),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildTextField(
                            label: 'State *',
                            controller: ctrl.stateController,
                            icon: Icons.map_rounded,
                            validator: (v) =>
                                Validators.validRequired(v!, 'State'))),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                        child: _buildTextField(
                            label: 'Zip Code *',
                            controller: ctrl.zipController,
                            icon: Icons.pin_drop_rounded,
                            validator: (v) =>
                                (v?.length ?? 0) >= 5 ? null : 'Invalid Zip')),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildTextField(
                            label: 'Country',
                            controller: ctrl.countryController,
                            icon: Icons.public_rounded,
                            enabled: false,
                            initialValue: 'India')),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                        child: _buildTextField(
                            label: 'Latitude',
                            controller: ctrl.latitudeController,
                            icon: Icons.gps_fixed_rounded,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true))),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildTextField(
                            label: 'Longitude',
                            controller: ctrl.longitudeController,
                            icon: Icons.gps_not_fixed_rounded,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true))),
                  ]),
                  const SizedBox(height: 20),
                  _buildCurrentLocationButton(ctrl),
                  const SizedBox(height: 32),

                  // Documents
                  _buildSectionHeader('Certification Documents * (Max 5)'),
                  _buildDocumentSection(ctrl),
                  const SizedBox(height: 32),

                  // Sales Status
                  if (Get.arguments['action'] == 'sales') ...[
                    _buildSectionHeader('Provider Status *'),
                    Obx(() => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 3))
                            ],
                          ),
                          child: DropdownButtonFormField<String>(
                            value: ctrl.selectedStatus.value.isEmpty
                                ? null
                                : ctrl.selectedStatus.value,
                            decoration: InputDecoration(
                              labelText: 'Select Status',
                              prefixIcon: Icon(Icons.verified_user_rounded,
                                  color: AppConstants.appPrimaryColor),
                              border: InputBorder.none,
                            ),
                            items: ["pending", "approved", "rejected"]
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) => v != null
                                ? ctrl.selectedStatus.value = v
                                : null,
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                        )),
                    const SizedBox(height: 40),
                  ],

                  // Submit Button
                  Obx(() {
                    final canSubmit = ctrl.logoPath.value.isNotEmpty &&
                        ctrl.selectedTypes.isNotEmpty &&
                        ctrl.certificationFiles.isNotEmpty;

                    return SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        onPressed: ctrl.isSubmitting.value
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) {
                                  customToast(
                                      'Please fix all errors', Colors.red);
                                  return;
                                }
                                if (type == 'update') {
                                  await ctrl.updateProvider();
                                } else {
                                  await ctrl.registerAndComplete();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canSubmit
                              ? AppConstants.appPrimaryColor
                              : Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          elevation: 8,
                        ),
                        child: ctrl.isSubmitting.value
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            color: Colors.white)),
                                    SizedBox(width: 16),
                                    Text('Processing...',
                                        style: TextStyle(fontSize: 18)),
                                  ])
                            : Text(
                                type == 'update'
                                    ? 'Update Provider'
                                    : 'Complete Registration',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: Get.arguments['action'] != 'sales'
            ? (type == 'update'
                ? const CaretakerProviderBottomNavBar(index: 3)
                : Container(
                    color: Colors.red.shade600,
                    padding: const EdgeInsets.all(20),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        children: [
                          const TextSpan(
                              text:
                                  "We're reviewing your application. Our team will contact you soon. Need help? "),
                          TextSpan(
                            text: "Call Support",
                            style: const TextStyle(
                                color: Colors.yellow,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                if (await canLaunchUrl(
                                    Uri.parse(AppConstants.teleCall))) {
                                  await launchUrl(
                                      Uri.parse(AppConstants.teleCall));
                                }
                              },
                          ),
                          const TextSpan(text: "."),
                        ],
                      ),
                    ),
                  ))
            : null,
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800])),
          const SizedBox(height: 8),
          Container(
              height: 4,
              width: 80,
              decoration: BoxDecoration(
                  color: AppConstants.appPrimaryColor,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
        ],
      );

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    bool enabled = true,
    bool obscureText = false,
    String? initialValue,
  }) {
    if (initialValue != null && controller.text.isEmpty)
      controller.text = initialValue;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      enabled: enabled,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppConstants.appPrimaryColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: AppConstants.appPrimaryColor, width: 2)),
      ),
    );
  }

  Widget _buildCurrentLocationButton(
      CaretakerProviderRegistrationController ctrl) {
    return Center(
      child: ElevatedButton.icon(
        onPressed:
            ctrl.isLoadingLocation.value ? null : ctrl.getCurrentLocation,
        icon: ctrl.isLoadingLocation.value
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white))
            : const Icon(Icons.my_location_rounded, color: Colors.white),
        label: const Text('Use Current Location',
            style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildLogoSection(CaretakerProviderRegistrationController ctrl) {
    return Obx(() {
      final path = ctrl.logoPath.value;
      final hasLogo = path.isNotEmpty;

      return Column(
        children: [
          GestureDetector(
            onTap: hasLogo
                ? () => Get.to(() => FullScreenImage(imageUrl: path))
                : null,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color:
                        hasLogo ? Colors.green.shade400 : Colors.red.shade300,
                    width: 4),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6))
                ],
              ),
              child: hasLogo
                  ? ClipOval(
                      child: path.startsWith('http')
                          ? Image.network(path,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.business_rounded, size: 60))
                          : Image.file(File(path), fit: BoxFit.cover),
                    )
                  : const Icon(Icons.add_a_photo_rounded,
                      size: 50, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: ctrl.pickLogo,
            icon: const Icon(Icons.upload_rounded, color: Colors.white),
            label: Text(
              hasLogo ? 'Change Logo' : 'Upload Logo',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.appPrimaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDocumentSection(CaretakerProviderRegistrationController ctrl) {
    return Obx(() {
      final files = ctrl.certificationFiles;
      return Column(
        children: [
          if (files.isNotEmpty)
            ...files.asMap().entries.map((e) {
              final path = e.value;
              final name = path.split('/').last.split('?').first;
              final isPdf = name.toLowerCase().endsWith('.pdf');
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                      isPdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.image_rounded,
                      color: isPdf ? Colors.red : Colors.blue),
                  title: Text(name, overflow: TextOverflow.ellipsis),
                  subtitle:
                      Text(isPdf ? 'Tap to view PDF' : 'Tap to view image'),
                  trailing: path.startsWith('http')
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => ctrl.removeDocument(e.key)),
                  onTap: () => isPdf
                      ? launchUrl(Uri.parse(path))
                      : Get.to(() => FullScreenImage(imageUrl: path)),
                ),
              );
            }),
          OutlinedButton.icon(
            onPressed: files.length < 5 ? ctrl.pickDocuments : null,
            icon: const Icon(Icons.attach_file_rounded),
            label: Text(
                'Add Document ${files.isNotEmpty ? '(${files.length}/5)' : ''}'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: files.length < 5
                      ? AppConstants.appPrimaryColor
                      : Colors.grey),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      );
    });
  }
}
