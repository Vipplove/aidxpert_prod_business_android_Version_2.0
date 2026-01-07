// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';
import '../labs_provider_dashboard/controllers/labs_provider_dashboard_controller.dart';

class LabBranchFormModal extends StatefulWidget {
  final Map<String, dynamic>? branchData;
  const LabBranchFormModal(this.branchData, {super.key});

  @override
  State<LabBranchFormModal> createState() => _LabBranchFormModalState();
}

class _LabBranchFormModalState extends State<LabBranchFormModal> {
  final ctrl = Get.put(LabsProviderDashboardController());

  late TextEditingController searchCtrl;
  late TextEditingController nameCtrl;
  late TextEditingController descCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController areaCtrl;
  late TextEditingController cityCtrl;
  late TextEditingController stateCtrl;
  late TextEditingController zipCtrl;
  late TextEditingController countryCtrl;
  late TextEditingController latCtrl;
  late TextEditingController lngCtrl;

  final List<File> _pickedImages = [];
  final List<String> _existingPhotos = [];

  bool _isLoadingLocation = false;
  Map<String, dynamic>? _selectedUser;

  // Role-specific values for Labs (Pathologist)
  String get _roleFilter => 'Pathologist';
  String get _prefix => 'PATH';

  @override
  void initState() {
    super.initState();

    // Initialize search field if editing existing lab
    searchCtrl = TextEditingController(
      text: widget.branchData?['user'] != null
          ? 'PATH${widget.branchData!['user']['user_id']} - ${widget.branchData!['user']['first_name']} ${widget.branchData!['user']['last_name']}'
          : '',
    );

    nameCtrl = TextEditingController(text: widget.branchData?['lab_name'] ?? '');
    descCtrl =
        TextEditingController(text: widget.branchData?['lab_description'] ?? '');
    addressCtrl =
        TextEditingController(text: widget.branchData?['lab_address'] ?? '');
    areaCtrl = TextEditingController(text: widget.branchData?['area'] ?? '');
    cityCtrl = TextEditingController(text: widget.branchData?['city'] ?? '');
    stateCtrl = TextEditingController(text: widget.branchData?['state'] ?? '');
    zipCtrl = TextEditingController(text: widget.branchData?['zip_code'] ?? '');
    countryCtrl =
        TextEditingController(text: widget.branchData?['country'] ?? 'India');
    latCtrl = TextEditingController(
        text: widget.branchData?['latitude']?.toString() ?? '');
    lngCtrl = TextEditingController(
        text: widget.branchData?['longitude']?.toString() ?? '');

    final photos = widget.branchData?['lab_photos'] as List<dynamic>? ?? [];
    _existingPhotos.addAll(photos.cast<String>());

    // Pre-select user if editing
    if (widget.branchData?['user'] != null) {
      _selectedUser = widget.branchData!['user'];
    }
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    nameCtrl.dispose();
    descCtrl.dispose();
    addressCtrl.dispose();
    areaCtrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    zipCtrl.dispose();
    countryCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
    super.dispose();
  }

  // Safe prefix (max 8 chars)
  String _safePrefix(int userId) {
    final code = '$_prefix$userId';
    return code.length > 8 ? code.substring(0, 8) : code;
  }

  // Fetch Pathologists only
  Future<List<Map<String, dynamic>>> _fetchUsers(String query) async {
    try {
      final token = await readStr('token') ?? '';
      final response = await http.get(
        Uri.parse('${AppConstants.endpoint}/users?role=$_roleFilter'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          final List users = data['userList'] ?? [];
          return users.cast<Map<String, dynamic>>().where((u) {
            final name = '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'
                .toLowerCase();
            final email = (u['email'] ?? '').toLowerCase();
            final search = query.toLowerCase();
            return name.contains(search) ||
                email.contains(search) ||
                query.isEmpty;
          }).toList();
        }
      }
    } catch (e) {
      print('Search error: $e');
    }
    return [];
  }

  Future<void> _pickImages() async {
    if (_pickedImages.length + _existingPhotos.length >= 3) {
      customToast('Maximum 3 photos allowed', Colors.orange);
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _pickedImages.addAll(picked
            .map((x) => File(x.path))
            .take(3 - (_pickedImages.length + _existingPhotos.length)));
      });
    }
  }

  void _removePicked(int i) => setState(() => _pickedImages.removeAt(i));
  void _removeExisting(int i) => setState(() => _existingPhotos.removeAt(i));

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      customToast('Location service disabled', Colors.red);
      setState(() => _isLoadingLocation = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        customToast('Location permission denied', Colors.red);
        setState(() => _isLoadingLocation = false);
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark p = placemarks[0];
        setState(() {
          addressCtrl.text = [p.street, p.subLocality]
              .where((e) => e != null && e.isNotEmpty)
              .join(', ');
          areaCtrl.text = p.subLocality ?? p.locality ?? '';
          cityCtrl.text = p.locality ?? '';
          stateCtrl.text = p.administrativeArea ?? '';
          zipCtrl.text = p.postalCode ?? '';
          countryCtrl.text = p.country ?? 'India';
          latCtrl.text = position.latitude.toStringAsFixed(6);
          lngCtrl.text = position.longitude.toStringAsFixed(6);
        });
        customToast('Location updated!', Colors.green);
      }
    } catch (e) {
      customToast('Failed to get location', Colors.red);
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstants.appPrimaryColor,
        foregroundColor: Colors.white,
        title: Text(
            widget.branchData == null ? 'Add New Lab Branch' : 'Edit Lab Branch'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back())
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TYPEAHEAD SEARCH - Assign Pathologist
            _sectionTitle('Assign Pathologist (Optional)'),
            TypeAheadField<Map<String, dynamic>>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search Pathologist by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _selectedUser != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _selectedUser = null;
                              searchCtrl.clear();
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: AppConstants.appPrimaryColor, width: 2),
                  ),
                ),
              ),
              suggestionsCallback: _fetchUsers,
              itemBuilder: (context, user) {
                final id = user['user_id'] ?? 0;
                final name =
                    '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'
                        .trim();
                final email = user['email'] ?? 'No email';
                final prefix = _safePrefix(id);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        AppConstants.appPrimaryColor.withOpacity(0.15),
                    child: Text(
                      prefix,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.appPrimaryColor,
                      ),
                    ),
                  ),
                  title: Text('$prefix – $name',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(email,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                );
              },
              onSuggestionSelected: (user) {
                setState(() {
                  _selectedUser = user;
                });
                final displayText =
                    'PATH${user['user_id']} - ${user['first_name']} ${user['last_name']}';
                searchCtrl.text = displayText.trim();
                customToast('Pathologist selected: ${_safePrefix(user['user_id'])}',
                    Colors.green);
              },
              noItemsFoundBuilder: (_) => const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No Pathologist found'),
              ),
              loadingBuilder: (_) => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

            const SizedBox(height: 24),

            _sectionTitle('Basic Information'),
            _buildField(nameCtrl, 'Lab Name', Icons.local_hospital, maxLines: 2),
            const SizedBox(height: 12),
            _buildField(descCtrl, 'Description', Icons.description,
                maxLines: 3),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('Address'),
                _isLoadingLocation
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: _useCurrentLocation,
                        icon: const Icon(Icons.my_location,
                            color: Colors.white, size: 18),
                        label: const Text('Use Current',
                            style:
                                TextStyle(fontSize: 13, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600),
                      ),
              ],
            ),
            const SizedBox(height: 12),
            _buildField(addressCtrl, 'Address Line', Icons.home, maxLines: 3),
            const SizedBox(height: 12),
            _buildField(areaCtrl, 'Area / Locality', Icons.map),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildField(stateCtrl, 'State', Icons.flag)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildField(cityCtrl, 'City', Icons.location_city)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildField(zipCtrl, 'Zip Code', Icons.pin)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildField(countryCtrl, 'Country', Icons.public,
                      enabled: false)),
            ]),

            const SizedBox(height: 20),
            _sectionTitle('Coordinates (Optional)'),
            Row(children: [
              Expanded(
                  child: _buildField(latCtrl, 'Latitude', Icons.gps_fixed,
                      keyboard: const TextInputType.numberWithOptions(
                          decimal: true))),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildField(lngCtrl, 'Longitude', Icons.gps_not_fixed,
                      keyboard: const TextInputType.numberWithOptions(
                          decimal: true))),
            ]),

            const SizedBox(height: 24),
            _sectionTitle('Lab Photos (Max 3)'),
            _photoGrid(),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_a_photo, color: Colors.white),
                label: const Text('Add Photos',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.appPrimaryColor),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('Save Lab Branch',
                    style: TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.appPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      );

  Widget _buildField(TextEditingController c, String label, IconData icon,
      {int maxLines = 1, TextInputType? keyboard, bool enabled = true}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppConstants.appPrimaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppConstants.appPrimaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _photoGrid() {
    final all = [
      ..._existingPhotos.map((u) => {'type': 'url', 'path': u}),
      ..._pickedImages.map((f) => {'type': 'file', 'path': f.path})
    ];

    if (all.isEmpty) {
      return Container(
        height: 130,
        width: double.infinity,
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(12)),
        child: const Center(
            child: Text('No photos added',
                style: TextStyle(color: Colors.grey))),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: all.asMap().entries.map((e) {
        final item = e.value;
        final i = e.key;
        final isNet = item['type'] == 'url';
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isNet
                  ? CachedNetworkImage(
                      imageUrl: item['path']?.toString() ?? '',
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 110,
                        height: 110,
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 110,
                        height: 110,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    )
                  : Image.file(File(item['path'].toString()),
                      width: 110, height: 110, fit: BoxFit.cover),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.red,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, size: 16, color: Colors.white),
                  onPressed: () {
                    if (isNet) {
                      _removeExisting(i);
                    } else {
                      _removePicked(i - _existingPhotos.length);
                    }
                  },
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Future<void> _save() async {
    if (nameCtrl.text.trim().isEmpty || addressCtrl.text.trim().isEmpty) {
      customToast('Lab name and address are required', Colors.red);
      return;
    }

    final payload = {
      'lab_name': nameCtrl.text.trim(),
      'lab_description': descCtrl.text.trim(),
      'lab_address': addressCtrl.text.trim(),
      'area': areaCtrl.text.trim(),
      'city': cityCtrl.text.trim(),
      'state': stateCtrl.text.trim(),
      'zip_code': zipCtrl.text.trim(),
      'country': countryCtrl.text.trim(),
      'latitude': double.tryParse(latCtrl.text) ?? 0.0,
      'longitude': double.tryParse(lngCtrl.text) ?? 0.0,
    };

    // Attach user_id safely (new selection or existing)
    if (_selectedUser != null && _selectedUser!['user_id'] != null) {
      payload['user_id'] = _selectedUser!['user_id'];
    } else if (widget.branchData != null &&
        widget.branchData!['user'] != null &&
        widget.branchData!['user']['user_id'] != null) {
      payload['user_id'] = widget.branchData!['user']['user_id'];
    }

    // For update
    if (widget.branchData != null && widget.branchData!['lab_id'] != null) {
      payload['lab_id'] = widget.branchData!['lab_id'];
    }

    await ctrl.submitBranchWithPhotos(
      payload: payload,
      newImages: _pickedImages,
      context: context,
      onSuccess: () {
        Get.back();
        ctrl.getBranchList();
      },
    );
  }
}