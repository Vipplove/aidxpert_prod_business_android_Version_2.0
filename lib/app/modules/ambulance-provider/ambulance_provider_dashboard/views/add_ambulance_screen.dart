// ignore_for_file: curly_braces_in_flow_control_structures
// screens/ambulance/add_ambulance_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';

class AddAmbulanceScreen extends StatefulWidget {
  final Map<String, dynamic>? ambulanceData;

  const AddAmbulanceScreen({super.key, this.ambulanceData});

  @override
  State<AddAmbulanceScreen> createState() => _AddAmbulanceScreenState();
}

class _AddAmbulanceScreenState extends State<AddAmbulanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late bool isEditMode;
  int? ambulanceId;

  List<String> existingImages = [];
  List<XFile> newImages = [];

  late final TextEditingController _nameCtrl;
  late final TextEditingController _vehicleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _baseFareCtrl;
  late final TextEditingController _perKmCtrl;
  late final TextEditingController _waitingCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _driverNameCtrl;
  late final TextEditingController _driverContactCtrl;
  late final TextEditingController _customShiftCtrl;

  String? _selectedType;
  String? _selectedShift;
  String _selectedAvailability =
      "AVAILABLE"; // Normal String, updated via setState

  final List<String> _availabilityStatuses = [
    "AVAILABLE",
    "BOOKED",
    "ON_TRIP",
    "MAINTENANCE",
    "OFFLINE",
  ];

  final List<String> _ambulanceTypes = [
    "ICU Ambulance",
    "Basic Life Support (BLS)",
    "Cardiac Ambulance",
    "Advanced Life Support (ALS)",
    "Neonatal Ambulance",
    "Mortuary Van",
    "Specialty Ambulances"
  ];

  final List<String> _shiftTimes = [
    "06:00 - 14:00",
    "14:00 - 22:00",
    "22:00 - 06:00",
    "08:00 - 16:00",
    "16:00 - 00:00",
    "00:00 - 08:00",
    "Full Day (24 Hours)",
    "Custom (Enter manually)",
  ];

  double _depotLat = 18.5204;
  double _depotLng = 73.8567;

  List<Map<String, dynamic>> _pickupLocations = [];
  List<Map<String, dynamic>> _dropLocations = [];

  bool _isLoading = false;
  final String googleApiKey = AppConstants.googleApiKey;

  @override
  void initState() {
    super.initState();
    isEditMode = widget.ambulanceData != null;
    ambulanceId = widget.ambulanceData?['ambulance_id'];

    // Initialize controllers
    _nameCtrl = TextEditingController(
        text: widget.ambulanceData?['ambulance_name'] ?? '');
    _vehicleCtrl = TextEditingController(
        text: widget.ambulanceData?['vehicle_number'] ?? '');
    _descCtrl =
        TextEditingController(text: widget.ambulanceData?['description'] ?? '');
    _locationCtrl = TextEditingController(
        text: widget.ambulanceData?['location_name'] ?? '');
    _driverNameCtrl =
        TextEditingController(text: widget.ambulanceData?['driver_name'] ?? '');
    _driverContactCtrl = TextEditingController(
        text: widget.ambulanceData?['driver_contact'] ?? '');
    _customShiftCtrl = TextEditingController();

    // Safe Type Loading
    final String? apiType = widget.ambulanceData?['ambulance_type'];
    _selectedType = _ambulanceTypes.contains(apiType) ? apiType : null;

    // Safe Shift Loading
    final String? apiShift = widget.ambulanceData?['driver_shift_time'];
    if (_shiftTimes.contains(apiShift)) {
      _selectedShift = apiShift;
    } else if (apiShift != null && apiShift.isNotEmpty) {
      _selectedShift = "Custom (Enter manually)";
      _customShiftCtrl.text = apiShift;
    } else {
      _selectedShift = null;
    }

    // Availability Status from API
    final String? apiStatus = widget.ambulanceData?['availability_status'];
    if (_availabilityStatuses.contains(apiStatus)) {
      _selectedAvailability = apiStatus!;
    }

    // Existing images
    final photos = widget.ambulanceData?['ambulance_photos'] ?? [];
    if (photos is List) {
      existingImages = List<String>.from(photos);
    }

    // Charges
    final charges = widget.ambulanceData?['transport_charges'] ?? {};
    _baseFareCtrl =
        TextEditingController(text: charges['baseFare']?.toString() ?? '');
    _perKmCtrl =
        TextEditingController(text: charges['perKm']?.toString() ?? '');
    _waitingCtrl = TextEditingController(
        text: charges['waitingChargePerMin']?.toString() ?? '');

    // Locations
    _pickupLocations = List<Map<String, dynamic>>.from(
        widget.ambulanceData?['pickup_locations'] ?? []);
    _dropLocations = List<Map<String, dynamic>>.from(
        widget.ambulanceData?['drop_locations'] ?? []);

    // Depot coordinates
    final lat = widget.ambulanceData?['current_latitude'];
    final lng = widget.ambulanceData?['current_longitude'];
    if (lat != null && lng != null) {
      _depotLat = double.tryParse(lat.toString()) ?? _depotLat;
      _depotLng = double.tryParse(lng.toString()) ?? _depotLng;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _vehicleCtrl.dispose();
    _descCtrl.dispose();
    _baseFareCtrl.dispose();
    _perKmCtrl.dispose();
    _waitingCtrl.dispose();
    _locationCtrl.dispose();
    _driverNameCtrl.dispose();
    _driverContactCtrl.dispose();
    _customShiftCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() {
        newImages.addAll(images);
        final total = existingImages.length + newImages.length;
        if (total > 5) {
          newImages = newImages.sublist(0, 5 - existingImages.length);
          customToast("Maximum 5 photos allowed", Colors.orange);
        }
      });
    }
  }

  void _removeExisting(int index) =>
      setState(() => existingImages.removeAt(index));
  void _removeNew(int index) => setState(() => newImages.removeAt(index));

  void _showLocationBottomSheet(bool isPickup) {
    // ... your existing code
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (existingImages.isEmpty && newImages.isEmpty) {
      customToast("At least one photo required", Colors.red);
      return;
    }
    if (_selectedType == null) {
      customToast("Please select ambulance type", Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    final token = await readStr('token');
    final profileId = await readStr('profileId') ?? '1';

    try {
      final url = isEditMode
          ? "${AppConstants.endpoint}/ambulances/details/$ambulanceId"
          : "${AppConstants.endpoint}/ambulances/details";
      var request =
          http.MultipartRequest(isEditMode ? 'PUT' : 'POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';

      request.fields.addAll({
        'amb_provider_id': profileId,
        'ambulance_name': _nameCtrl.text,
        'ambulance_type': _selectedType!,
        'vehicle_number': _vehicleCtrl.text,
        'description': _descCtrl.text,
        'transport_charges': json.encode({
          "baseFare": int.tryParse(_baseFareCtrl.text) ?? 0,
          "perKm": int.tryParse(_perKmCtrl.text) ?? 0,
          if (_waitingCtrl.text.isNotEmpty)
            "waitingChargePerMin": int.tryParse(_waitingCtrl.text) ?? 0,
        }),
        'location_name': _locationCtrl.text,
        'city': "Pune",
        'state': "Maharashtra",
        'country': "India",
        'zip_code': "411038",
        'current_latitude': _depotLat.toString(),
        'current_longitude': _depotLng.toString(),
        'availability_status': _selectedAvailability,
        'driver_name': _driverNameCtrl.text,
        'driver_contact': _driverContactCtrl.text,
        'driver_shift_time': _selectedShift == "Custom (Enter manually)"
            ? _customShiftCtrl.text.trim()
            : (_selectedShift ?? ""),
        'pickup_locations': json.encode(_pickupLocations),
        'drop_locations': json.encode(_dropLocations),
      });

      for (var img in newImages) {
        request.files.add(
            await http.MultipartFile.fromPath('ambulance_photos', img.path));
      }

      final response = await request.send();
      final resp = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back(result: true);

        customToast(
            "Ambulance ${isEditMode ? "updated" : "added"} successfully",
            Colors.green);
      } else {
        customToast("Failed to $resp ambulance", Colors.red);
      }
    } catch (e) {
      customToast("Network error: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? "Edit Ambulance" : "Add New Ambulance"),
        backgroundColor: AppConstants.appPrimaryColor,
        foregroundColor: Colors.white,
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photos
              _sectionTitle(
                  "Ambulance Photos (${existingImages.length + newImages.length}/5)"),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: existingImages.length + newImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == existingImages.length + newImages.length) {
                      return GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey.shade400,
                                width: 2,
                                style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey.shade50,
                          ),
                          child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40),
                                Text("Add Photo")
                              ]),
                        ),
                      );
                    }
                    final isExisting = index < existingImages.length;
                    final path = isExisting
                        ? existingImages[index]
                        : newImages[index - existingImages.length].path;
                    return Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          margin: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: isExisting
                                ? Image.network(path,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.error))
                                : Image.file(File(path), fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => isExisting
                                ? _removeExisting(index)
                                : _removeNew(index - existingImages.length),
                            child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.red,
                                child: Icon(Icons.close,
                                    size: 16, color: Colors.white)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Basic Info
              _sectionTitle("Basic Information"),
              _buildTextField(_nameCtrl, "Ambulance Name", Icons.track_changes),
              DropdownButtonFormField<String>(
                value: _ambulanceTypes.contains(_selectedType)
                    ? _selectedType
                    : null,
                decoration: InputDecoration(
                  labelText: "Ambulance Type",
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: AppConstants.appPrimaryColor, width: 2),
                  ),
                ),
                hint: const Text("Select type"),
                items: _ambulanceTypes
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedType = val),
                validator: (val) => val == null ? "Required" : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                  _vehicleCtrl, "Vehicle Number", Icons.directions_car),
              _buildTextField(_descCtrl, "Description", Icons.description,
                  maxLines: 4),

              const SizedBox(height: 10),

              // Depot Location
              _sectionTitle("Depot Location"),
              GooglePlaceAutoCompleteTextField(
                textEditingController: _locationCtrl,
                googleAPIKey: googleApiKey,
                inputDecoration: InputDecoration(
                  labelText: "Search Depot Address",
                  prefixIcon: const Icon(Icons.location_city),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                debounceTime: 400,
                countries: ["in"],
                isLatLngRequired: true,
                getPlaceDetailWithLatLng: (Prediction prediction) {
                  setState(() {
                    _depotLat =
                        double.tryParse(prediction.lat ?? "18.5204") ?? 18.5204;
                    _depotLng =
                        double.tryParse(prediction.lng ?? "73.8567") ?? 73.8567;
                  });
                },
                itemClick: (Prediction prediction) {
                  _locationCtrl.text = prediction.description ?? "";
                },
              ),
              const SizedBox(height: 12),
              Text(
                  "Coordinates: ${_depotLat.toStringAsFixed(6)}, ${_depotLng.toStringAsFixed(6)}"),

              const SizedBox(height: 24),

              // Pickup & Drop
              _sectionTitle("Pickup Locations (${_pickupLocations.length})"),
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _pickupLocations
                      .asMap()
                      .entries
                      .map((e) => _locationChip(e.value, true, e.key))
                      .toList()),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed: () => _showLocationBottomSheet(true),
                  icon: const Icon(Icons.add_location),
                  label: const Text("Add Pickup")),

              const SizedBox(height: 24),

              _sectionTitle("Drop Locations (${_dropLocations.length})"),
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _dropLocations
                      .asMap()
                      .entries
                      .map((e) => _locationChip(e.value, false, e.key))
                      .toList()),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed: () => _showLocationBottomSheet(false),
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text("Add Drop")),

              const SizedBox(height: 24),

              // Pricing
              _sectionTitle("Pricing"),
              Row(children: [
                Expanded(
                    child: _buildTextField(
                        _baseFareCtrl, "Base Fare", Icons.paid,
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildTextField(_perKmCtrl, "Per KM", Icons.speed,
                        keyboardType: TextInputType.number)),
              ]),
              _buildTextField(
                  _waitingCtrl, "Waiting Charge / min (optional)", Icons.timer,
                  keyboardType: TextInputType.number),

              const SizedBox(height: 10),

              // Driver
              _sectionTitle("Driver Details"),
              _buildTextField(_driverNameCtrl, "Driver Name", Icons.person),
              _buildTextField(_driverContactCtrl, "Contact Number", Icons.phone,
                  keyboardType: TextInputType.phone),

              DropdownButtonFormField<String>(
                value: _shiftTimes.contains(_selectedShift)
                    ? _selectedShift
                    : null,
                decoration: InputDecoration(
                  labelText: "Shift Time",
                  prefixIcon: const Icon(Icons.access_time),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: AppConstants.appPrimaryColor, width: 2),
                  ),
                ),
                hint: const Text("Select shift"),
                items: _shiftTimes
                    .map((shift) =>
                        DropdownMenuItem(value: shift, child: Text(shift)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedShift = val;
                    if (val != "Custom (Enter manually)") {
                      _customShiftCtrl.clear();
                    }
                  });
                },
                validator: (val) => val == null ? "Required" : null,
              ),

              if (_selectedShift == "Custom (Enter manually)")
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildTextField(_customShiftCtrl,
                      "Custom Shift (e.g. 10:00-18:00)", Icons.schedule),
                ),

              const SizedBox(height: 20),

              // Availability Status Dropdown
              _sectionTitle("Availability Status *"),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  value: _selectedAvailability,
                  decoration: InputDecoration(
                    labelText: "Select Availability",
                    prefixIcon: Icon(Icons.access_time_filled,
                        color: AppConstants.appPrimaryColor),
                    border: InputBorder.none,
                  ),
                  items: _availabilityStatuses.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Icon(_getStatusIcon(status),
                              color: _getStatusColor(status), size: 20),
                          const SizedBox(width: 12),
                          Text(status.replaceAll("_", " "),
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(status))),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedAvailability = value);
                    }
                  },
                  validator: (v) =>
                      v == null ? "Please select availability status" : null,
                ),
              ),

              const SizedBox(height: 30),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.appPrimaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEditMode ? "Update Ambulance" : "Add Ambulance",
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.appPrimaryColor)),
    );
  }

  Widget _buildTextField(
      TextEditingController ctrl, String label, IconData icon,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppConstants.appPrimaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: AppConstants.appPrimaryColor, width: 2),
          ),
        ),
        validator: (val) => val?.trim().isEmpty == true ? "Required" : null,
      ),
    );
  }

  Widget _locationChip(Map<String, dynamic> loc, bool isPickup, int index) {
    return Chip(
      label: Text(loc['name'],
          style: const TextStyle(fontSize: 13),
          overflow: TextOverflow.ellipsis),
      backgroundColor: isPickup ? Colors.green.shade100 : Colors.blue.shade100,
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: () => setState(() {
        if (isPickup)
          _pickupLocations.removeAt(index);
        else
          _dropLocations.removeAt(index);
      }),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case "AVAILABLE":
        return Icons.check_circle;
      case "BOOKED":
        return Icons.event_busy;
      case "ON_TRIP":
        return Icons.directions_car;
      case "MAINTENANCE":
        return Icons.build;
      case "OFFLINE":
        return Icons.power_off;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "AVAILABLE":
        return Colors.green.shade700;
      case "BOOKED":
        return Colors.orange.shade700;
      case "ON_TRIP":
        return Colors.blue.shade700;
      case "MAINTENANCE":
        return Colors.purple.shade700;
      case "OFFLINE":
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
