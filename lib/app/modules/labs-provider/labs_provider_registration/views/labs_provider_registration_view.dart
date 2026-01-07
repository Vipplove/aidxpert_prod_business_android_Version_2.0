// ignore_for_file: must_be_immutable, deprecated_member_use, dead_code
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/client_side_validation.dart';
import '../../../../../utils/gps_location.dart';
import '../../../../../utils/helper.dart';
import '../../../components/image_viewer.dart';
import '../../../components/pdf_viewer.dart';
import '../../component/lab_bottom_navbar.dart';
import '../controllers/labs_provider_registration_controller.dart';

class LabsRegistrationView extends GetView<LabsProviderRegistrationController> {
  LabsRegistrationView({Key? key}) : super(key: key);
  final GlobalKey<FormState> labsRegisterformKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    Get.put(LabsProviderRegistrationController());
    var type = Get.arguments['type'] ?? 'update';

    // Load data from API on update mode
    Future.microtask(
        () => controller.loadUpdateDataFromApi(Get.arguments['id'].toString()));

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
        appBar: _buildAppBar(type),
        body: GetBuilder<LabsProviderRegistrationController>(
          id: 'labs-form',
          builder: (ctrl) {
            // SAFETY: handle null controller state
            if (ctrl.hasLoaded != true) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return Form(
              key: labsRegisterformKey,
              child: ListView(padding: const EdgeInsets.all(20), children: [
                if (type != 'update') ...[
                  _buildSectionHeader('Account Information'),
                  _buildFullWidthField(
                    label: 'Phone Number *',
                    controller: ctrl.phoneController,
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    validator: (v) => Validators.validMobileno(v!),
                    ctrl: ctrl,
                  ),
                  const SizedBox(height: 16),
                  _buildFullWidthField(
                    label: 'Email Address (Optional)',
                    controller: ctrl.emailController,
                    icon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        v!.isEmpty ? null : (Validators.validEmail(v)),
                    ctrl: ctrl,
                  ),
                  const SizedBox(height: 16),
                  _buildFullWidthField(
                    label: 'Password *',
                    controller: ctrl.passwordController,
                    icon: Icons.lock_rounded,
                    obscureText: true,
                    validator: (v) => Validators.validPassword(v!),
                    ctrl: ctrl,
                  ),
                  const SizedBox(height: 32),
                ],
                _buildSectionHeader('Lab Logo'),
                _buildLogoSection(ctrl),
                const SizedBox(height: 32),
                _buildSectionHeader('Provider Information'),
                _buildFullWidthField(
                  label: 'Provider Name *',
                  controller: ctrl.providerNameController,
                  icon: Icons.local_hospital_rounded,
                  validator: (v) => Validators.validRequired(
                      v!, 'Provider Name',
                      min: 3, max: 100),
                  ctrl: ctrl,
                ),
                const SizedBox(height: 16),
                _buildFullWidthField(
                  label: 'GST Number',
                  controller: ctrl.gstController,
                  icon: Icons.receipt_long,
                  ctrl: ctrl,
                ),
                const SizedBox(height: 16),
                _buildFullWidthField(
                  label: 'PAN Number',
                  controller: ctrl.panController,
                  icon: Icons.credit_card,
                  validator: (v) =>
                      v!.length == 10 ? null : 'Invalid PAN (10 chars)',
                  ctrl: ctrl,
                ),
                const SizedBox(height: 16),
                _buildFullWidthField(
                  label: 'License Number *',
                  controller: ctrl.licenseController,
                  icon: Icons.verified_user,
                  validator: (v) =>
                      Validators.validRequired(v!, 'License Number'),
                  ctrl: ctrl,
                ),
                const SizedBox(height: 16),
                _buildFullWidthField(
                  label: 'License Expiry *',
                  controller: ctrl.expiryController,
                  icon: Icons.calendar_today,
                  readOnly: true,
                  onTap: () => ctrl.pickExpiryDate(context),
                  validator: (v) => Validators.validRequired(v!, 'Expiry Date'),
                  ctrl: ctrl,
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('Bank Details'),
                _buildFullWidthField(
                  label: 'Bank Account Number *',
                  controller: ctrl.accountNoController,
                  icon: Icons.account_balance_wallet,
                  isAccountNoField: true,
                  validator: ctrl.validateAccountNo,
                  hint: '9 to 18 digits',
                  keyboardType: TextInputType.number,
                  ctrl: ctrl,
                ),
                const SizedBox(height: 16),
                _buildIfscWithBank(ctrl),
                const SizedBox(height: 16),
                _buildFullWidthField(
                  label: 'UPI ID (Optional)',
                  controller: ctrl.upiController,
                  icon: Icons.payment,
                  isUpiField: true,
                  validator: ctrl.validateUpi,
                  hint: 'e.g., yourname@upi',
                  ctrl: ctrl,
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('Accreditations'),
                _buildAccreditationChips(ctrl),
                const SizedBox(height: 32),
                _buildSectionHeader('Address Details'),
                _buildFullWidthField(
                  label: 'Full Address *',
                  controller: ctrl.addressController,
                  icon: Icons.location_on,
                  maxLines: 3,
                  validator: (v) =>
                      Validators.validRequired(v!, 'Address', min: 10),
                  ctrl: ctrl,
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: _buildFullWidthField(
                      label: 'City *',
                      controller: ctrl.cityController,
                      icon: Icons.location_city,
                      validator: (v) => Validators.validRequired(v!, 'City'),
                      ctrl: ctrl,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFullWidthField(
                      label: 'State *',
                      controller: ctrl.stateController,
                      icon: Icons.map,
                      validator: (v) => Validators.validRequired(v!, 'State'),
                      ctrl: ctrl,
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: _buildFullWidthField(
                      label: 'Zip Code *',
                      controller: ctrl.zipController,
                      icon: Icons.pin_drop,
                      validator: (v) => v!.length >= 5 ? null : 'Invalid Zip',
                      ctrl: ctrl,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFullWidthField(
                      label: 'Country',
                      controller: ctrl.countryController,
                      icon: Icons.public,
                      enabled: false,
                      initialValue: 'India',
                      ctrl: ctrl,
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                _buildFullWidthField(
                  label: 'Latitude',
                  controller: ctrl.latitudeController,
                  icon: Icons.gps_fixed,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  ctrl: ctrl,
                ),
                const SizedBox(height: 16),
                _buildFullWidthField(
                  label: 'Longitude',
                  controller: ctrl.longitudeController,
                  icon: Icons.gps_not_fixed,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  ctrl: ctrl,
                ),
                const SizedBox(height: 16),
                _buildCurrentLocationButton(ctrl),
                const SizedBox(height: 25),
                _buildSectionHeader('Certification Documents *'),
                _buildDocumentUploadSection(ctrl),
                const SizedBox(height: 25),
                if (Get.arguments['action'] == 'sales') ...[
                  // ADD THIS NEW STATUS FIELD HERE
                  _buildSectionHeader('Provider Status *'),

                  Obx(
                    () => Container(
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
                            offset: Offset(0, 3),
                          )
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: ctrl.selectedStatus.value.isEmpty
                            ? null
                            : ctrl.selectedStatus.value,
                        decoration: InputDecoration(
                          labelText: 'Select Status',
                          prefixIcon: Icon(
                            Icons.verified_user,
                            color: AppConstants.appPrimaryColor,
                          ),
                          border: InputBorder.none,
                        ),
                        items: ["pending", "approved", "rejected"]
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: status == 'approved'
                                          ? Colors.green.shade700
                                          : status == 'pending'
                                              ? Colors.orange.shade700
                                              : status == 'rejected'
                                                  ? Colors.red.shade700
                                                  : Colors.blueGrey,
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            ctrl.selectedStatus.value = value;
                          }
                        },
                        validator: (v) =>
                            v == null ? 'Status is required' : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
                _buildSubmitButton(type, ctrl),
                const SizedBox(height: 20),
              ]),
            );
          },
        ),
        bottomNavigationBar: Get.arguments['action'] != 'sales'
            ? (type == 'update' || type == 'create'
                ? const LabProviderBottomNavBar(index: 4)
                : Container(
                    color: Colors.red,
                    padding: const EdgeInsets.all(12),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        children: [
                          const TextSpan(
                            text:
                                "We're working on verifying your account! The Aidxpert team will call you soon. Need help right now? Our support team is here for you. ",
                          ),
                          TextSpan(
                            text: "Call Now",
                            style: const TextStyle(
                              color: Colors.yellow,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                final tel = AppConstants.teleCall;
                                if (await canLaunchUrl(Uri.parse(tel))) {
                                  await launchUrl(Uri.parse(tel));
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

  // === HELPER WIDGETS (unchanged except logo & docs) ===
  PreferredSizeWidget _buildAppBar(String type) => AppBar(
        backgroundColor: AppConstants.appPrimaryColor,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Text(
          type == 'update' ? 'Update Profile' : 'Update Profile',
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
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
        centerTitle: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
      );

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
              width: 60,
              decoration: BoxDecoration(
                  color: AppConstants.appPrimaryColor,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
        ],
      );

  Widget _buildFullWidthField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    bool readOnly = false,
    bool obscureText = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
    String? initialValue,
    bool isAccountNoField = false,
    bool isIfscField = false,
    bool isUpiField = false,
    required LabsProviderRegistrationController ctrl,
  }) {
    if (initialValue != null && controller.text.isEmpty) {
      controller.text = initialValue;
    }

    final bool showError;
    final String errorText;
    final bool isValid;

    if (isAccountNoField) {
      showError = ctrl.accountNoErrorMessage.value.isNotEmpty;
      errorText = ctrl.accountNoErrorMessage.value;
      isValid = ctrl.isAccountNoValid.value;
    } else if (isIfscField) {
      showError = ctrl.ifscErrorMessage.value.isNotEmpty;
      errorText = ctrl.ifscErrorMessage.value;
      isValid = ctrl.isIfscValid.value;
    } else if (isUpiField) {
      showError = ctrl.upiErrorMessage.value.isNotEmpty;
      errorText = ctrl.upiErrorMessage.value;
      isValid = ctrl.isUpiValid.value;
    } else {
      showError = false;
      errorText = '';
      isValid = false;
    }

    final Color borderColor = isValid
        ? Colors.green
        : (showError ? Colors.red : Colors.grey.shade300);

    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscureText,
      onTap: onTap,
      maxLines: maxLines,
      keyboardType: keyboardType,
      enabled: enabled,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppConstants.appPrimaryColor),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: borderColor,
              width: isAccountNoField || isIfscField || isUpiField ? 2 : 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: isValid
                  ? Colors.green
                  : (isAccountNoField || isIfscField || isUpiField
                      ? Colors.red
                      : AppConstants.appPrimaryColor),
              width: 2),
        ),
        errorText: showError ? errorText : null,
        errorStyle: const TextStyle(fontSize: 12, color: Colors.red),
      ),
    );
  }

  Widget _buildIfscWithBank(LabsProviderRegistrationController ctrl) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFullWidthField(
            label: 'IFSC Code *',
            controller: ctrl.ifscController,
            icon: Icons.code,
            isIfscField: true,
            validator: ctrl.validateIfsc,
            hint: 'e.g., HDFC0001234',
            ctrl: ctrl,
          ),
          const SizedBox(height: 8),
          Obx(() {
            if (ctrl.isFetchingBank.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Fetching bank...',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ]),
              );
            }
            if (ctrl.bankName.value.isNotEmpty) {
              final isSuccess = !ctrl.bankName.value.contains('Invalid') &&
                  !ctrl.bankName.value.contains('Failed');
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Icon(isSuccess ? Icons.account_balance : Icons.error,
                      size: 16, color: isSuccess ? Colors.green : Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ctrl.bankName.value,
                      style: TextStyle(
                          fontSize: 13,
                          color: isSuccess
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ]),
              );
            }
            return const SizedBox(height: 8);
          }),
        ],
      );

  Widget _buildLogoSection(LabsProviderRegistrationController ctrl) => Column(
        children: [
          // Clickable circle avatar for viewing
          Obx(() => GestureDetector(
                onTap: ctrl.logoPath.value.isNotEmpty
                    ? () => Get.to(
                        () => FullScreenImage(imageUrl: ctrl.logoPath.value))
                    : null,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ctrl.logoPath.value.isEmpty
                          ? Colors.red.shade300
                          : Colors.green.shade400,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ctrl.logoPath.value.isEmpty
                      ? _buildPlaceholder()
                      : ctrl.logoPath.value.startsWith('http')
                          ? ClipOval(
                              child: Image.network(
                                ctrl.logoPath.value,
                                fit: BoxFit.cover,
                                width: 140,
                                height: 140,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildErrorPlaceholder(),
                              ),
                            )
                          : ClipOval(
                              child: Image.file(
                                File(ctrl.logoPath.value),
                                fit: BoxFit.cover,
                                width: 140,
                                height: 140,
                              ),
                            ),
                ),
              )),
          const SizedBox(height: 16),
          // Upload button - always clickable
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: ctrl.pickLogo,
              icon: const Icon(Icons.upload, size: 20),
              label: Text(
                ctrl.logoPath.value.isEmpty
                    ? 'Upload Logo (PNG/JPG)'
                    : 'Change Logo',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.appPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
            ),
          ),
        ],
      );

// Add these two methods to your class
  Widget _buildPlaceholder() => Container(
        decoration:
            const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 8),
            Text('Upload Logo',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),
          ],
        ),
      );

  Widget _buildErrorPlaceholder() => Container(
        decoration:
            const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text('Image failed',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),
          ],
        ),
      );

  Widget _buildAccreditationChips(LabsProviderRegistrationController ctrl) {
    final options = [
      'NABH Accredited',
      'ISO 13485',
      'CAP certified',
      'NABL',
      'ICMR Approved',
      'JCI Accredited'
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select all that apply',
            style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 12),
        Obx(() => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: options.map((opt) {
                bool selected = ctrl.selectedAccreditations.contains(opt);
                return FilterChip(
                  label: Text(opt, style: const TextStyle(fontSize: 13)),
                  selected: selected,
                  onSelected: (_) => ctrl.toggleAccreditation(opt),
                  selectedColor: AppConstants.appPrimaryColor.withOpacity(0.15),
                  checkmarkColor: AppConstants.appPrimaryColor,
                  backgroundColor: Colors.grey[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                        color: selected
                            ? AppConstants.appPrimaryColor
                            : Colors.grey.shade300),
                  ),
                );
              }).toList(),
            )),
      ],
    );
  }

  Widget _buildDocumentUploadSection(LabsProviderRegistrationController ctrl) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upload up to 5 documents (PDF, JPG, PNG)',
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 16),
          Obx(() => Column(
                children: [
                  if (ctrl.certificationFiles.isNotEmpty)
                    ...ctrl.certificationFiles.asMap().entries.map((e) {
                      int idx = e.key;
                      String path = e.value;
                      String name = path.contains('blob.core')
                          ? 'Doc ${idx + 1}'
                          : path.split('/').last.split('?').first; // Clean URL
                      bool isPdf = path.split('?')[0].split('.').last == 'pdf'
                          ? true
                          : false;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () {
                            if (isPdf) {
                              // Open PDF Viewer
                              Get.to(() => PdfViewerScreen(pdfUrl: path));
                            } else {
                              // Open Image Viewer (existing behavior)
                              Get.to(() => FullScreenImage(imageUrl: path));
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isPdf
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isPdf
                                    ? Colors.red.shade400
                                    : Colors.green.shade400,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isPdf
                                      ? Icons.picture_as_pdf_rounded
                                      : Icons.image_rounded,
                                  size: 28,
                                  color: isPdf ? Colors.red : Colors.blue,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        isPdf
                                            ? 'Tap to view PDF'
                                            : 'Tap to view image',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isPdf)
                                  const Icon(Icons.zoom_in,
                                      size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  color: Colors.grey[700],
                                  onPressed: () =>
                                      ctrl.removeCertificationFile(idx),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: ctrl.certificationFiles.length < 5
                          ? ctrl.pickCertificationDocuments
                          : null,
                      icon: const Icon(Icons.attach_file),
                      label: Text(
                        'Add Document ${ctrl.certificationFiles.isNotEmpty ? '(${ctrl.certificationFiles.length}/5)' : ''}',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppConstants.appPrimaryColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        foregroundColor: AppConstants.appPrimaryColor,
                      ),
                    ),
                  ),
                ],
              )),
        ],
      );

  Widget _buildCurrentLocationButton(LabsProviderRegistrationController ctrl) =>
      Center(
        child: ElevatedButton.icon(
          onPressed: () async {
            ctrl.isLoadingLocation.value = true;
            try {
              Map<String, String> loc = await getCurrentLocation();
              ctrl.addressController.text = loc['location'] ?? '';
              ctrl.cityController.text = loc['city'] ?? '';
              ctrl.stateController.text = loc['state'] ?? '';
              ctrl.zipController.text = loc['zip'] ?? '';
              ctrl.latitudeController.text = loc['latitude'] ?? '';
              ctrl.longitudeController.text = loc['longitude'] ?? '';
            } catch (e) {
              customToast('Failed to get location');
            } finally {
              ctrl.isLoadingLocation.value = false;
            }
          },
          icon: Obx(() => ctrl.isLoadingLocation.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.my_location)),
          label: const Text('Use Current Location'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );

  Widget _buildSubmitButton(
          String type, LabsProviderRegistrationController ctrl) =>
      Obx(() {
        final bool canSubmit = ctrl.logoPath.value.isNotEmpty &&
            ctrl.certificationFiles.isNotEmpty &&
            ctrl.isAccountNoValid.value &&
            ctrl.isIfscValid.value &&
            !ctrl.bankName.value.contains('Invalid');

        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: ctrl.isLoading.value
                ? null
                : () async {
                    if (labsRegisterformKey.currentState?.validate() != true) {
                      customToast('Please fix form errors');
                      return;
                    }
                    if (type == 'update') {
                      await ctrl.updateProvider();
                    } else {
                      await ctrl.registerAndContinue(); // Two-step registration
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: canSubmit
                  ? AppConstants.appPrimaryColor
                  : Colors.grey.shade400,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: ctrl.isLoading.value
                ? const Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Processing...', style: TextStyle(fontSize: 16)),
                  ])
                : Text(
                    type == 'update'
                        ? 'Update Profile'
                        : 'Complete Registration',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
          ),
        );
      });
}
