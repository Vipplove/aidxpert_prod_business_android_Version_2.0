// screens/caretaker/caretaker_add_staff.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';

class CareTakerAddStaff extends StatefulWidget {
  const CareTakerAddStaff({super.key});

  @override
  State<CareTakerAddStaff> createState() => _CareTakerAddStaffState();
}

class _CareTakerAddStaffState extends State<CareTakerAddStaff> {
  final _formKey = GlobalKey<FormState>();

  // Edit mode data
  Map<String, dynamic>? editData;
  bool get isEditMode => editData != null;

  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _biographyController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _postalCodeController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  String? _gender;
  DateTime? _birthday;
  bool _termsAccepted = false;
  bool _isLoading = false;

  String? _existingProfileUrl;
  PlatformFile? _newProfileImage;

  List<String> _existingDocuments = [];
  List<PlatformFile> _newDocuments = [];

  final List<String> _availableTypes = [
    'Elderly Care',
    'Baby Care',
    'Post-Surgery Care',
    'Patient Attendant',
    'Home Nurse',
    'Child Care Helper',
    'Maternity Support',
  ];
  List<String> _selectedTypes = [];

  final Map<String, TextEditingController> _chargeControllers = {};

  // Daily Status
  bool _isAvailable = true;
  String _selectedShift = 'morning';

  final List<Map<String, dynamic>> _shifts = [
    {'value': 'morning', 'label': 'Morning Shift', 'icon': Icons.wb_sunny},
    {'value': 'afternoon', 'label': 'Afternoon Shift', 'icon': Icons.wb_cloudy},
    {'value': 'night', 'label': 'Night Shift', 'icon': Icons.nightlight_round},
    {
      'value': 'full_day',
      'label': 'Full Day',
      'icon': Icons.access_time_filled
    },
  ];

  final String baseUrl = '${AppConstants.endpoint}/caretakers/details';
  late String token;
  late String providerId;

  @override
  void initState() {
    super.initState();

    // Get passed data for edit mode
    editData = Get.arguments as Map<String, dynamic>?;

    final user = editData?['user'] ?? {};
    final caretakerData = editData ?? {};

    // Initialize all controllers
    _firstNameController =
        TextEditingController(text: user['first_name'] ?? '');
    _lastNameController = TextEditingController(text: user['last_name'] ?? '');
    _phoneController = TextEditingController(text: user['phone_number'] ?? '');
    _emailController = TextEditingController(text: user['email'] ?? '');
    _passwordController = TextEditingController(); // Only used in Add mode
    _biographyController = TextEditingController(text: user['biography'] ?? '');
    _addressController = TextEditingController(text: user['address'] ?? '');
    _cityController = TextEditingController(text: user['city'] ?? '');
    _stateController = TextEditingController(text: user['state'] ?? '');
    _countryController =
        TextEditingController(text: user['country'] ?? 'India');
    _postalCodeController =
        TextEditingController(text: user['postal_code'] ?? '');
    _descriptionController =
        TextEditingController(text: caretakerData['description'] ?? '');
    _locationController =
        TextEditingController(text: caretakerData['location'] ?? '');

    _gender = user['gender'];
    if (user['birthday'] != null) {
      _birthday = DateTime.tryParse(user['birthday']);
    }

    // Profile photo
    _existingProfileUrl = user['profile_image_name'];

    // Documents
    _existingDocuments =
        List<String>.from(caretakerData['upload_documents'] ?? []);

    // Specializations
    _selectedTypes = List<String>.from(caretakerData['caretaker_type'] ?? []);
    final charges = List<Map>.from(caretakerData['service_charges'] ?? []);
    for (var type in _selectedTypes) {
      final match = charges.firstWhere((c) => c['type'] == type,
          orElse: () => {'daily': 0});
      _chargeControllers[type] =
          TextEditingController(text: match['daily'].toString());
    }

    // Daily Status
    final dailyStatus = caretakerData['daily_status'] ??
        {'available': true, 'shift': 'morning'};
    _isAvailable = dailyStatus['available'] ?? true;
    _selectedShift = dailyStatus['shift'] ?? 'morning';

    // Terms accepted by default in edit mode
    if (isEditMode) _termsAccepted = true;

    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    token = await readStr('token') ?? '';
    providerId = await readStr('profileId') ?? '1';
    setState(() {});
  }

  void _onPlaceSelected(Prediction prediction) {
    _addressController.text = prediction.description ?? '';
    List<String> parts = (prediction.description ?? '').split(',');
    if (parts.length >= 4) {
      _cityController.text = parts[parts.length - 4].trim();
      _stateController.text = parts[parts.length - 3].trim();
      _postalCodeController.text =
          parts[parts.length - 2].trim().split(' ').last;
    }
  }

  Future<void> _pickAndCropProfileImage() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      String path = result.files.single.path!;
      CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: path,
        aspectRatioPresets: [CropAspectRatioPreset.square],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: AppConstants.appPrimaryColor,
            toolbarWidgetColor: Colors.white,
          ),
          IOSUiSettings(title: 'Crop Photo'),
        ],
      );
      if (mounted && cropped != null) {
        setState(() {
          _newProfileImage = PlatformFile(
            name: result.files.single.name,
            path: cropped.path,
            size: File(cropped.path).lengthSync(),
          );
        });
      }
    }
  }

  Future<void> _pickNewDocuments() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _newDocuments.addAll(result.files.where((f) => f.path != null));
      });
    }
  }

  void _removeNewDocument(int index) {
    setState(() => _newDocuments.removeAt(index));
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      customToast('Please fix the errors', Colors.red);
      return;
    }
    if (_selectedTypes.isEmpty) {
      customToast('Select at least one specialization', Colors.red);
      return;
    }
    if (_newProfileImage == null && _existingProfileUrl == null) {
      customToast('Upload a profile photo', Colors.red);
      return;
    }
    if (_newDocuments.isEmpty && _existingDocuments.isEmpty) {
      customToast('Upload at least one document', Colors.red);
      return;
    }
    if (!isEditMode && !_termsAccepted) {
      customToast('Accept terms and conditions', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url =
          isEditMode ? '$baseUrl/${editData!['caretaker_id']}' : baseUrl;

      var request = http.MultipartRequest(
        isEditMode ? 'PUT' : 'POST',
        Uri.parse(url),
      );
      request.headers['Authorization'] = 'Bearer $token';

      request.fields.addAll({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        if (!isEditMode) 'password': _passwordController.text,
        'gender': _gender ?? '',
        'birthday': _birthday != null
            ? DateFormat('yyyy-MM-dd').format(_birthday!)
            : '',
        'biography': _biographyController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'country': _countryController.text,
        'postal_code': _postalCodeController.text,
        'platform': (Platform.operatingSystem).toUpperCase(),
        'role_id': '10',
        'term_condition': 'true',
        'work_for': 'CareTakerServiceProvider',
        'caretaker_service_provider_id': providerId,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'caretaker_type': jsonEncode(_selectedTypes),
        'service_charges': jsonEncode(_selectedTypes.map((type) {
          return {
            'type': type,
            'daily': int.tryParse(_chargeControllers[type]?.text ?? '0') ?? 0,
          };
        }).toList()),
        'daily_status':
            jsonEncode({'available': _isAvailable, 'shift': _selectedShift}),
      });

      if (_newProfileImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'profile_image', _newProfileImage!.path!));
      }
      for (var doc in _newDocuments) {
        request.files.add(
            await http.MultipartFile.fromPath('upload_documents', doc.path!));
      }

      var response = await request.send();
      var respData = await response.stream.bytesToString();
      var jsonResp = jsonDecode(respData);

      print(jsonResp);

      if (response.statusCode == 200 || response.statusCode == 201) {
        customToast(isEditMode ? 'Caretaker updated!' : 'Caretaker added!',
            Colors.green);
        Get.back();
      } else {
        customToast(jsonResp['message'] ?? 'Operation failed', Colors.red);
      }
    } catch (e) {
      customToast('Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppConstants.appPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isEditMode ? 'Edit Caretaker' : 'Add New Caretaker',
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection('Personal Information'),
              _buildTextField(_firstNameController, 'First Name',
                  required: true),
              _buildTextField(_lastNameController, 'Last Name', required: true),
              _buildTextField(_phoneController, 'Phone Number',
                  required: true,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v!.length != 10 ? '10 digits required' : null),
              _buildTextField(_emailController, 'Email',
                  required: true, keyboardType: TextInputType.emailAddress),
              if (!isEditMode)
                _buildTextField(_passwordController, 'Password',
                    required: true,
                    obscureText: true,
                    validator: (v) =>
                        v!.length < 8 ? 'Minimum 8 characters' : null),
              _buildGenderDropdown(),
              _buildBirthdayPicker(),
              _buildTextField(_biographyController, 'Biography', maxLines: 3),
              _buildSection('Address'),
              GooglePlaceAutoCompleteTextField(
                textEditingController: _addressController,
                googleAPIKey: AppConstants.googleApiKey,
                inputDecoration: InputDecoration(
                  labelText: 'Address *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                debounceTime: 600,
                countries: const ["in"],
                itemClick: _onPlaceSelected,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _buildTextField(_cityController, 'City',
                        required: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildTextField(_stateController, 'State',
                        required: true)),
              ]),
              Row(children: [
                Expanded(
                    child: _buildTextField(_countryController, 'Country',
                        required: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildTextField(_postalCodeController, 'PIN Code',
                        required: true,
                        validator: (v) =>
                            v!.length != 6 ? '6 digits required' : null)),
              ]),
              _buildSection('Work Profile'),
              _buildMultiSelect(
                  'Specializations *', _availableTypes, _selectedTypes, (val) {
                setState(() {
                  if (_selectedTypes.contains(val)) {
                    _selectedTypes.remove(val);
                    _chargeControllers.remove(val);
                  } else {
                    _selectedTypes.add(val);
                    _chargeControllers[val] = TextEditingController();
                  }
                });
              }),
              if (_selectedTypes.isNotEmpty) ...[
                const Text('Daily Charges (₹)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ..._selectedTypes.map((type) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _buildTextField(
                          _chargeControllers[type]!, '$type Rate',
                          keyboardType: TextInputType.number),
                    )),
              ],
              _buildTextField(_descriptionController, 'Description',
                  maxLines: 3),
              _buildTextField(_locationController, 'Service Area'),
              _buildSection('Availability & Shift'),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Availability',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isAvailable = true),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _isAvailable
                                      ? Colors.green.shade100
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: _isAvailable
                                          ? Colors.green
                                          : Colors.transparent),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: _isAvailable
                                            ? Colors.green
                                            : Colors.grey),
                                    const SizedBox(width: 8),
                                    Text('Available',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _isAvailable
                                                ? Colors.green
                                                : Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isAvailable = false),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: !_isAvailable
                                      ? Colors.red.shade100
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: !_isAvailable
                                          ? Colors.red
                                          : Colors.transparent),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cancel,
                                        color: !_isAvailable
                                            ? Colors.red
                                            : Colors.grey),
                                    const SizedBox(width: 8),
                                    Text('Not Available',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: !_isAvailable
                                                ? Colors.red
                                                : Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('Preferred Shift',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _shifts.map((shift) {
                          final isSelected = _selectedShift == shift['value'];
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedShift = shift['value']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppConstants.appPrimaryColor
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: isSelected
                                        ? AppConstants.appPrimaryColor
                                        : Colors.grey.shade300),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4))
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(shift['icon'],
                                      color: isSelected
                                          ? Colors.white
                                          : AppConstants.appPrimaryColor,
                                      size: 24),
                                  const SizedBox(width: 8),
                                  Text(shift['label'],
                                      style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              _buildSection('Profile Photo'),
              Center(
                child: GestureDetector(
                  onTap: _pickAndCropProfileImage,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _newProfileImage != null
                        ? Image.file(File(_newProfileImage!.path!),
                            height: 160, width: 160, fit: BoxFit.cover)
                        : (_existingProfileUrl != null &&
                                _existingProfileUrl!.isNotEmpty
                            ? Image.network(_existingProfileUrl!,
                                height: 160,
                                width: 160,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.person, size: 80)))
                            : Container(
                                color: Colors.grey.shade300,
                                height: 160,
                                width: 160,
                                child: const Icon(Icons.person, size: 80))),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                  child: Text(
                      _newProfileImage != null
                          ? 'New photo selected'
                          : 'Tap to change photo',
                      style: TextStyle(color: Colors.grey.shade600))),
              _buildSection('Documents'),
              if (_existingDocuments.isNotEmpty) ...[
                const Text('Current Documents',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ..._existingDocuments.map((url) => Card(
                      child: ListTile(
                        leading:
                            const Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: Text(url.split('/').last.split('?').first,
                            style: const TextStyle(fontSize: 14)),
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () async {
                            final uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                      ),
                    )),
              ],
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickNewDocuments,
                icon: const Icon(Icons.add),
                label: Text('Add New Documents (${_newDocuments.length})'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50),
              ),
              if (_newDocuments.isNotEmpty) ...[
                const SizedBox(height: 12),
                ..._newDocuments.map((file) => Card(
                      child: ListTile(
                        leading:
                            const Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: Text(file.name),
                        trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _removeNewDocument(
                                _newDocuments.indexOf(file))),
                      ),
                    )),
              ],
              if (!isEditMode) ...[
                const SizedBox(height: 20),
                CheckboxListTile(
                  title: const Text('I accept terms and conditions *',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  value: _termsAccepted,
                  onChanged: (v) => setState(() => _termsAccepted = v!),
                ),
              ],
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.appPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEditMode ? 'Update Caretaker' : 'Add Caretaker',
                          style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(title,
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.appPrimaryColor)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool required = false,
      int maxLines = 1,
      bool obscureText = false,
      TextInputType? keyboardType,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        maxLines: maxLines,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator ??
            (required ? (v) => v!.isEmpty ? 'Required' : null : null),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Gender *',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        value: _gender,
        items: ['Male', 'Female', 'Other']
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (v) => setState(() => _gender = v),
        validator: (v) => v == null ? 'Required' : null,
      ),
    );
  }

  Widget _buildBirthdayPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(1990),
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
          );
          if (picked != null) setState(() => _birthday = picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Birthday *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          child: Text(_birthday == null
              ? 'Select date'
              : DateFormat('dd MMM yyyy').format(_birthday!)),
        ),
      ),
    );
  }

  Widget _buildMultiSelect(String title, List<String> options,
      List<String> selected, Function(String) onToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((type) {
            final isSelected = selected.contains(type);
            return FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (_) => onToggle(type),
              backgroundColor: Colors.grey.shade200,
              selectedColor: AppConstants.appPrimaryColor.withOpacity(0.2),
              checkmarkColor: AppConstants.appPrimaryColor,
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _biographyController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    for (var ctrl in _chargeControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }
}
