// screens/ambulance/ambulance_driver.dart
// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path/path.dart' as path;

import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';
import '../../../../routes/app_pages.dart';
import '../../component/ambulance_bottom_navbar.dart';

class AmbulanceDriverController extends GetxController {
  RxList<dynamic> drivers = <dynamic>[].obs;
  RxList<dynamic> ambulances = <dynamic>[].obs;
  RxBool isLoading = true.obs;
  RxBool isSubmitting = false.obs;
  RxBool isLoadingAmbulances = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDrivers();
    fetchAmbulances();
  }

  Future<void> fetchDrivers() async {
    try {
      isLoading.value = true;
      final token = await readStr('token');
      final providerId = await readStr('profileId');

      final response = await http.get(
        Uri.parse(
            '${AppConstants.endpoint}/ambulances/drivers/provider/$providerId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          drivers.assignAll(data['list']);
        }
      }
    } catch (e) {
      customToast('Failed to load drivers ${e.toString()}', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAmbulances() async {
    try {
      isLoadingAmbulances.value = true;
      final token = await readStr('token');
      final providerId = await readStr('profileId');

      final response = await http.get(
        Uri.parse(
            '${AppConstants.endpoint}/ambulances/details/provider/$providerId/all'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          ambulances.assignAll(data['list']);
        }
      }
    } catch (e) {
      customToast('Failed to load ambulances ${e.toString()}', Colors.red);
    } finally {
      isLoadingAmbulances.value = false;
    }
  }

  Future<void> addOrUpdateDriver({
    required bool isUpdate,
    int? ambDriverId,
    required Map<String, dynamic> formData,
    File? profileImage,
    List<PlatformFile>? documentFiles,
    required int? selectedAmbulanceId,
    required String currentStatus,
  }) async {
    try {
      isSubmitting.value = true;
      final token = await readStr('token');
      final providerId = await readStr('profileId');

      String url = isUpdate
          ? '${AppConstants.endpoint}/ambulances/drivers/$ambDriverId'
          : '${AppConstants.endpoint}/ambulances/drivers';

      var request =
          http.MultipartRequest(isUpdate ? 'PUT' : 'POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';

      formData.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          request.fields[key] = value.toString();
        }
      });

      request.fields['role_id'] = '23';
      request.fields['platform'] = (Platform.operatingSystem).toUpperCase();
      request.fields['term_condition'] = 'true';
      request.fields['amb_provider_id'] = providerId.toString();

      if (selectedAmbulanceId != null) {
        request.fields['ambulance_id'] = selectedAmbulanceId.toString();
      }

      request.fields['current_status'] = currentStatus;

      if (profileImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'profile_image', profileImage.path));
      }

      if (documentFiles != null && documentFiles.isNotEmpty) {
        for (var doc in documentFiles) {
          if (doc.path != null) {
            request.files.add(await http.MultipartFile.fromPath(
                'document_uploads', doc.path!));
          } else if (doc.bytes != null) {
            request.files.add(http.MultipartFile.fromBytes(
              'document_uploads',
              doc.bytes!,
              filename: doc.name,
            ));
          }
        }
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final responseData = json.decode(responseBody);

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        customToast(
            isUpdate
                ? 'Driver updated successfully'
                : 'Driver created successfully',
            Colors.green);
        fetchDrivers();
        Get.back();
      } else {
        throw Exception(responseData['message'] ?? 'Request failed');
      }
    } catch (e) {
      customToast('Failed to submit driver: ${e.toString()}', Colors.red);
    } finally {
      isSubmitting.value = false;
    }
  }
}

class AmbulanceDriver extends GetView<AmbulanceDriverController> {
  const AmbulanceDriver({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => AmbulanceDriverController());

    return WillPopScope(
      onWillPop: () async {
        Get.offNamed(Routes.AMBULANCE_PROVIDER_DASHBOARD);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text("Ambulance Drivers"),
          backgroundColor: AppConstants.appPrimaryColor,
          centerTitle: true,
          foregroundColor: Colors.white,
          shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50)),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 28),
                onPressed: () => _showDriverForm(isUpdate: false),
              ),
            ),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return Center(child: loading);
          }

          if (controller.drivers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No drivers found',
                      style:
                          TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.fetchDrivers,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: controller.drivers.length,
              itemBuilder: (context, index) {
                final driver = controller.drivers[index];
                final user = driver['user'];
                final ambulance = driver['ambulance_details'] ?? {};
                final List<dynamic> documents =
                    driver['document_uploads'] ?? [];

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage:
                                  user['profile_image_name'] != null
                                      ? NetworkImage(user['profile_image_name'])
                                      : null,
                              child: user['profile_image_name'] == null
                                  ? const Icon(Icons.person,
                                      size: 40, color: Colors.grey)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(user['email'] ?? 'No email',
                                      style: TextStyle(color: Colors.grey[700]),
                                      overflow: TextOverflow.ellipsis),
                                  Text(user['phone_number'] ?? 'No phone',
                                      style: TextStyle(color: Colors.grey[700]),
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit,
                                  color: AppConstants.appPrimaryColor),
                              onPressed: () => _showDriverForm(
                                  isUpdate: true, driverData: driver),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        _infoRow('Status', driver['current_status'] ?? 'N/A',
                            Icons.access_time),
                        _infoRow(
                            'Ambulance',
                            ambulance['ambulance_name'] ?? 'Not Assigned',
                            Icons.local_hospital),
                        _infoRow('Type', ambulance['ambulance_type'] ?? 'N/A',
                            Icons.category),
                        _infoRow(
                            'Vehicle No.',
                            ambulance['vehicle_number'] ?? 'N/A',
                            Icons.directions_car),
                        _infoRow(
                            'Location',
                            ambulance['location_name'] ?? 'N/A',
                            Icons.location_on),
                        if (user['biography']?.toString().isNotEmpty == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text('Bio: ${user['biography']}',
                                style: TextStyle(
                                    color: Colors.grey[700],
                                    fontStyle: FontStyle.italic),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2),
                          ),
                        if (documents.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: InkWell(
                              onTap: () => _showDocumentViewer(
                                  context,
                                  documents,
                                  '${user['first_name']} ${user['last_name']}'),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.folder_open,
                                        color: Colors.blue.shade700),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                          'Documents: ${documents.length}',
                                          style: TextStyle(
                                              color: Colors.blue.shade900,
                                              fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    Icon(Icons.arrow_forward_ios,
                                        size: 16, color: Colors.blue.shade700),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),
        bottomNavigationBar: const AmbulanceProviderBottomNavBar(index: 3),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value,
                  style: TextStyle(color: Colors.grey[800]),
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  // Fixed Document Viewer
  void _showDocumentViewer(
      BuildContext context, List<dynamic> documents, String driverName) {
    Get.to(() => Scaffold(
          appBar: AppBar(
            title: Text("$driverName's Documents"),
            backgroundColor: AppConstants.appPrimaryColor,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Get.back(),
            ),
          ),
          body: documents.isEmpty
              ? const Center(child: Text('No documents available'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final String docUrl = documents[index].toString().trim();
                    final String extension =
                        path.extension(docUrl).toLowerCase();
                    final bool isPdf = extension == '.pdf';
                    final bool isImage = [
                      '.jpg',
                      '.jpeg',
                      '.png',
                      '.gif',
                      '.bmp',
                      '.webp'
                    ].contains(extension);
                    final String fileName =
                        path.basename(docUrl.split('?').first);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isPdf
                                ? Colors.red.shade100
                                : isImage
                                    ? Colors.blue.shade100
                                    : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isPdf
                                ? Icons.picture_as_pdf
                                : isImage
                                    ? Icons.image
                                    : Icons.insert_drive_file,
                            size: 30,
                            color: isPdf
                                ? Colors.red.shade700
                                : isImage
                                    ? Colors.blue.shade700
                                    : Colors.grey.shade700,
                          ),
                        ),
                        title: Text(
                          fileName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          isPdf
                              ? 'PDF Document'
                              : isImage
                                  ? 'Image File'
                                  : 'Other File',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing:
                            const Icon(Icons.open_in_new, color: Colors.blue),
                        onTap: () async {
                          if (isPdf) {
                            // Open PDF with better error handling
                            Get.to(() => Scaffold(
                                  appBar: AppBar(
                                    title: Text(fileName),
                                    backgroundColor:
                                        AppConstants.appPrimaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  body: SfPdfViewer.network(
                                    docUrl,
                                    canShowScrollHead: false,
                                    canShowPaginationDialog: true,
                                    canShowScrollStatus: true,
                                    onDocumentLoaded: (details) {
                                      // Success - optional
                                    },
                                    onDocumentLoadFailed: (details) {
                                      Get.back(); // Close viewer

                                      customToast('Failed to load PDF document',
                                          Colors.red);
                                    },
                                  ),
                                ));
                          } else if (isImage) {
                            // Open Image in full screen
                            Get.to(() => Scaffold(
                                  backgroundColor: Colors.black,
                                  appBar: AppBar(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    title: Text(fileName),
                                    actions: [
                                      IconButton(
                                        icon: const Icon(Icons.share),
                                        onPressed: () {
                                          // Optional: Add share functionality
                                        },
                                      )
                                    ],
                                  ),
                                  body: Center(
                                    child: InteractiveViewer(
                                      panEnabled: true,
                                      boundaryMargin: const EdgeInsets.all(20),
                                      minScale: 0.5,
                                      maxScale: 4,
                                      child: Image.network(
                                        docUrl,
                                        fit: BoxFit.contain,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return const Center(
                                              child: CircularProgressIndicator(
                                                  color: Colors.white));
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.error,
                                                    color: Colors.red,
                                                    size: 60),
                                                SizedBox(height: 16),
                                                Text(
                                                  'Failed to load image',
                                                  style: TextStyle(
                                                      color: Colors.white70),
                                                ),
                                                Text(
                                                  'Link may be expired',
                                                  style: TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ));
                          } else {
                            customToast(
                                'Cannot preview this file type', Colors.orange);
                          }
                        },
                      ),
                    );
                  },
                ),
        ));
  }

  void _showDriverForm({required bool isUpdate, dynamic driverData}) {
    final formKey = GlobalKey<FormState>();

    final firstNameCtrl = TextEditingController(
        text: isUpdate ? driverData['user']['first_name'] ?? '' : '');
    final lastNameCtrl = TextEditingController(
        text: isUpdate ? driverData['user']['last_name'] ?? '' : '');
    final emailCtrl = TextEditingController(
        text: isUpdate ? driverData['user']['email'] ?? '' : '');
    final phoneCtrl = TextEditingController(
        text: isUpdate ? driverData['user']['phone_number'] ?? '' : '');
    final addressCtrl = TextEditingController(
        text: isUpdate ? driverData['user']['address'] ?? '' : '');
    final cityCtrl = TextEditingController(
        text: isUpdate ? driverData['user']['city'] ?? '' : '');
    final stateCtrl = TextEditingController(
        text: isUpdate
            ? driverData['user']['state'] ?? 'Maharashtra'
            : 'Maharashtra');
    final countryCtrl = TextEditingController(
        text: isUpdate ? driverData['user']['country'] ?? 'India' : 'India');
    final zipCtrl = TextEditingController(
        text: isUpdate ? driverData['user']['postal_code'] ?? '' : '');
    final latCtrl = TextEditingController(
        text: isUpdate ? driverData['user']['latitude'] ?? '' : '');
    final longCtrl = TextEditingController(
        text: isUpdate ? driverData['user']['longitude'] ?? '' : '');
    final socialCtrl = TextEditingController(
        text: isUpdate
            ? driverData['user']['social_media_based_login'] ?? ''
            : '');
    final bioCtrl = TextEditingController(
        text: isUpdate ? driverData['user']['biography'] ?? '' : '');

    final passwordCtrl = TextEditingController();
    String selectedGender =
        isUpdate ? (driverData['user']['gender'] ?? 'Male') : 'Male';
    String selectedStatus =
        isUpdate ? (driverData['current_status'] ?? 'AVAILABLE') : 'AVAILABLE';

    Rx<DateTime?> selectedBirthday = Rx<DateTime?>(null);
    if (isUpdate && driverData['user']['birthday'] != null) {
      try {
        selectedBirthday.value =
            DateFormat('yyyy-MM-dd').parse(driverData['user']['birthday']);
      } catch (_) {}
    }

    Rx<File?> selectedProfileImage = Rx<File?>(null);
    RxList<PlatformFile> selectedDocuments = <PlatformFile>[].obs;
    List<dynamic> existingDocuments =
        isUpdate ? driverData['document_uploads'] ?? [] : [];

    int? selectedAmbulanceId =
        isUpdate && driverData['ambulance_details'] != null
            ? driverData['ambulance_details']['ambulance_id']
            : null;

    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      Container(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 20),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isUpdate ? 'Update Driver' : 'Add New Driver',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Get.back()),
                  ],
                ),
                const SizedBox(height: 20),

                Center(
                  child: Stack(
                    children: [
                      Obx(() => CircleAvatar(
                            radius: 50,
                            backgroundImage: selectedProfileImage.value != null
                                ? FileImage(selectedProfileImage.value!)
                                : (isUpdate &&
                                        driverData['user']
                                                ['profile_image_name'] !=
                                            null
                                    ? NetworkImage(driverData['user']
                                        ['profile_image_name'])
                                    : null) as ImageProvider?,
                            child: selectedProfileImage.value == null &&
                                    (isUpdate
                                        ? driverData['user']
                                                ['profile_image_name'] ==
                                            null
                                        : true)
                                ? const Icon(Icons.person,
                                    size: 50, color: Colors.white)
                                : null,
                          )),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppConstants.appPrimaryColor,
                          child: IconButton(
                            iconSize: 18,
                            color: Colors.white,
                            icon: const Icon(Icons.camera_alt),
                            onPressed: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(
                                  source: ImageSource.gallery);
                              if (picked != null) {
                                selectedProfileImage.value = File(picked.path);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Ambulance Assignment
                Obx(() => controller.isLoadingAmbulances.value
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<int>(
                        value: selectedAmbulanceId,
                        decoration: const InputDecoration(
                            labelText: 'Assign Ambulance *',
                            border: OutlineInputBorder()),
                        hint: const Text('Select ambulance'),
                        items: controller.ambulances
                            .map<DropdownMenuItem<int>>((amb) {
                          return DropdownMenuItem<int>(
                              value: amb['ambulance_id'] as int,
                              child: Text(
                                  '${amb['ambulance_name']} (${amb['vehicle_number']})'));
                        }).toList(),
                        onChanged: (value) => selectedAmbulanceId = value,
                        validator: (value) => value == null ? 'Required' : null,
                      )),
                const SizedBox(height: 16),

                _buildTextField(firstNameCtrl, 'First Name', required: true),
                _buildTextField(lastNameCtrl, 'Last Name', required: true),
                _buildTextField(emailCtrl, 'Email',
                    required: true, keyboardType: TextInputType.emailAddress),
                _buildTextField(phoneCtrl, 'Phone Number',
                    required: true, keyboardType: TextInputType.phone),

                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(
                      labelText: 'Gender', border: OutlineInputBorder()),
                  items: ['Male', 'Female', 'Other']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => selectedGender = v ?? 'Male',
                ),
                const SizedBox(height: 16),

                if (!isUpdate)
                  _buildTextField(passwordCtrl, 'Password',
                      required: true, obscureText: true),

                _buildTextField(addressCtrl, 'Address'),
                _buildTextField(cityCtrl, 'City'),
                _buildTextField(stateCtrl, 'State'),
                _buildTextField(countryCtrl, 'Country'),
                _buildTextField(zipCtrl, 'Postal Code'),
                _buildTextField(latCtrl, 'Latitude',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true)),
                _buildTextField(longCtrl, 'Longitude',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true)),
                _buildTextField(socialCtrl, 'Social Media Login'),

                // Current Status
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                      labelText: 'Current Status *',
                      border: OutlineInputBorder()),
                  items: ['AVAILABLE', 'ON_TRIP', 'OFF_DUTY', 'SUSPENDED']
                      .map((status) =>
                          DropdownMenuItem(value: status, child: Text(status)))
                      .toList(),
                  onChanged: (value) => selectedStatus = value ?? 'AVAILABLE',
                ),
                const SizedBox(height: 10),

                Obx(() => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(selectedBirthday.value != null
                          ? 'Birthday: ${DateFormat('dd MMM yyyy').format(selectedBirthday.value!)}'
                          : 'Select Birthday'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: Get.context!,
                          initialDate: selectedBirthday.value ?? DateTime.now(),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) selectedBirthday.value = picked;
                      },
                    )),
                const SizedBox(height: 10),

                _buildTextField(bioCtrl, 'Biography', maxLines: 3),

                const SizedBox(height: 15),
                const Text('Upload Documents',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform
                        .pickFiles(allowMultiple: true, type: FileType.any);
                    if (result != null && result.files.isNotEmpty) {
                      selectedDocuments.addAll(result.files);
                    }
                  },
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Select Documents'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.white60),
                ),

                const SizedBox(height: 12),
                Obx(() => selectedDocuments.isEmpty && existingDocuments.isEmpty
                    ? const Text('No documents',
                        style: TextStyle(color: Colors.grey))
                    : Column(
                        children: [
                          if (existingDocuments.isNotEmpty)
                            ...existingDocuments.map((docUrl) => Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    dense: true,
                                    leading: Icon(docUrl
                                            .toString()
                                            .toLowerCase()
                                            .endsWith('.pdf')
                                        ? Icons.picture_as_pdf
                                        : Icons.insert_drive_file),
                                    title: Text(
                                        path.basename(docUrl.toString()),
                                        overflow: TextOverflow.ellipsis),
                                    trailing: const Icon(Icons.visibility,
                                        color: Colors.blue),
                                    onTap: () => _showDocumentViewer(
                                        Get.context!, [docUrl], ''),
                                  ),
                                )),
                          ...selectedDocuments.map((doc) => Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(
                                      doc.extension?.toLowerCase() == 'pdf'
                                          ? Icons.picture_as_pdf
                                          : Icons.insert_drive_file),
                                  title: Text(doc.name,
                                      overflow: TextOverflow.ellipsis),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_circle,
                                        color: Colors.red),
                                    onPressed: () =>
                                        selectedDocuments.remove(doc),
                                  ),
                                ),
                              )),
                        ],
                      )),

                const SizedBox(height: 30),

                Obx(() => SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: controller.isSubmitting.value ||
                                selectedAmbulanceId == null
                            ? null
                            : () {
                                if (formKey.currentState!.validate()) {
                                  final formData = {
                                    'first_name': firstNameCtrl.text.trim(),
                                    'last_name': lastNameCtrl.text.trim(),
                                    'email': emailCtrl.text.trim(),
                                    'phone_number': phoneCtrl.text.trim(),
                                    'gender': selectedGender,
                                    if (!isUpdate)
                                      'password': passwordCtrl.text,
                                    'address': addressCtrl.text.trim(),
                                    'city': cityCtrl.text.trim(),
                                    'state': stateCtrl.text.trim(),
                                    'country': countryCtrl.text.trim(),
                                    'postal_code': zipCtrl.text.trim(),
                                    'latitude': latCtrl.text.trim(),
                                    'longitude': longCtrl.text.trim(),
                                    'social_media_based_login':
                                        socialCtrl.text.trim(),
                                    if (selectedBirthday.value != null)
                                      'birthday': DateFormat('yyyy-MM-dd')
                                          .format(selectedBirthday.value!),
                                    'biography': bioCtrl.text.trim(),
                                  };

                                  controller.addOrUpdateDriver(
                                    isUpdate: isUpdate,
                                    ambDriverId: isUpdate
                                        ? driverData['amb_driver_id']
                                        : null,
                                    formData: formData,
                                    profileImage: selectedProfileImage.value,
                                    documentFiles: selectedDocuments,
                                    selectedAmbulanceId: selectedAmbulanceId,
                                    currentStatus: selectedStatus,
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.appPrimaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: controller.isSubmitting.value
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(isUpdate ? 'Update Driver' : 'Add Driver',
                                style: const TextStyle(
                                    fontSize: 18, color: Colors.white)),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool required = false,
      bool obscureText = false,
      TextInputType? keyboardType,
      int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return 'Required';
          }
          if (label == 'Email' && !GetUtils.isEmail(value?.trim() ?? '')) {
            return 'Invalid email';
          }
          if (label == 'Phone Number' && (value?.length ?? 0) != 10) {
            return '10 digits required';
          }
          if (label == 'Postal Code' && (value?.length ?? 0) != 6) {
            return '6 digits required';
          }
          return null;
        },
      ),
    );
  }
}
