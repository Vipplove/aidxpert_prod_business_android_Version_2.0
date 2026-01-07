// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DiagnosticPriceTable extends StatefulWidget {
  const DiagnosticPriceTable({super.key});

  @override
  State<DiagnosticPriceTable> createState() => _DiagnosticPriceTableState();
}

class _DiagnosticPriceTableState extends State<DiagnosticPriceTable> {
  final DiagnosticBranchController controller =
      Get.put(DiagnosticBranchController());

  @override
  void initState() {
    super.initState();
    controller.fetchBranches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstants.appPrimaryColor,
        title: const Text("Branch & Schedule",
            style: TextStyle(color: Colors.white, fontSize: 18)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoadingBranches.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.branches.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text("No branches found",
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: controller.branches.length,
          itemBuilder: (context, index) {
            final branch = controller.branches[index];
            return _buildBranchCard(branch);
          },
        );
      }),
    );
  }

  Widget _buildBranchCard(Map<String, dynamic> branch) {
    final name = branch['center_name'] ?? 'Unknown Center';
    final address = branch['center_address'] ?? '';
    final area = branch['area'] ?? '';
    final city = branch['city'] ?? '';
    final state = branch['state'] ?? '';

    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showScheduleBottomSheet(branch),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.appPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.local_hospital,
                        color: AppConstants.appPrimaryColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$area, $city",
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "$address • $state",
                      style: TextStyle(fontSize: 13.5, color: Colors.grey[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScheduleBottomSheet(Map<String, dynamic> branch) {
    final diagnosticId = branch['diagnostic_center_id'].toString();
    final branchName = branch['center_name'] ?? 'Lab Branch';
    final initialDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    Get.bottomSheet(
      ScheduleBottomSheet(
        diagnosticId: diagnosticId,
        branchName: branchName,
        initialDate: initialDate,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      persistent: false,
      enableDrag: true,
    );
  }
}

// ====================== BOTTOM SHEET ======================
class ScheduleBottomSheet extends StatefulWidget {
  final String diagnosticId;
  final String branchName;
  final String initialDate;

  const ScheduleBottomSheet({
    super.key,
    required this.diagnosticId,
    required this.branchName,
    required this.initialDate,
  });

  @override
  State<ScheduleBottomSheet> createState() => _ScheduleBottomSheetState();
}

class _ScheduleBottomSheetState extends State<ScheduleBottomSheet> {
  late String selectedDate;
  final ScheduleController scheduleCtrl = Get.put(ScheduleController());
  final List<int> patientOptions = [1, 2, 3, 4, 5];
  late RxInt selectedPatients;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    selectedPatients = 3.obs;
    scheduleCtrl.fetchSchedule(widget.diagnosticId, selectedDate);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.7,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppConstants.appPrimaryColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.branchName,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),

              // Date Picker
              Padding(
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.parse(selectedDate),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                                primary: AppConstants.appPrimaryColor),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      selectedDate = DateFormat('yyyy-MM-dd').format(date);
                      setState(() {});
                      scheduleCtrl.fetchSchedule(
                          widget.diagnosticId, selectedDate);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppConstants.appPrimaryColor),
                      borderRadius: BorderRadius.circular(14),
                      color: AppConstants.appPrimaryColor.withOpacity(0.05),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color: AppConstants.appPrimaryColor),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEEE, dd MMM yyyy')
                              .format(DateTime.parse(selectedDate)),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Add Schedule Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showAddScheduleDialog,
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                    ),
                    label: const Text("Add New Time Slot",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.appPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1),
              ),
              const SizedBox(height: 8),

              // Schedule List
              Expanded(
                child: Obx(() {
                  if (scheduleCtrl.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (scheduleCtrl.schedule.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule,
                              size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text("No slots added for this date",
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          Text("Tap + Add New Time Slot",
                              style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: scheduleCtrl.schedule.length,
                    itemBuilder: (context, index) {
                      final slot = scheduleCtrl.schedule[index];
                      return _buildSlotCard(slot);
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlotCard(Map<String, dynamic> slot) {
    final booked = slot['booked_count'] ?? 0;
    final total = slot['no_of_patient'] ?? 1;
    final available = total - booked;

    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          slot['slot'] ?? 'Unknown Slot',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text("₹${slot['price']} • ${slot['km_range']}Km"),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildChip(
                    "Booked: $booked", booked > 0 ? Colors.red : Colors.grey),
                const SizedBox(width: 12),
                _buildChip("Available: $available",
                    available > 0 ? Colors.green : Colors.orange),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.edit_calendar, color: Colors.blue, size: 28),
        onTap: () => _showAddScheduleDialog(slot: slot),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.bold)),
    );
  }

  void _showAddScheduleDialog({Map<String, dynamic>? slot}) {
    final isEdit = slot != null;
    final kmCtrl = TextEditingController(text: slot?['km_range'] ?? '');
    final priceCtrl =
        TextEditingController(text: slot?['price']?.toString() ?? '');
    String? selectedSlot = slot?['slot'];
    selectedPatients.value = slot?['no_of_patient'] ?? 3;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(isEdit ? Icons.edit : Icons.add,
                color: AppConstants.appPrimaryColor),
            const SizedBox(width: 10),
            Text(isEdit ? "Edit Schedule" : "Add New Slot"),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedSlot,
                  decoration: InputDecoration(
                    labelText: "Select Time Slot",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: scheduleCtrl.slots
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => selectedSlot = v,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: kmCtrl,
                  decoration: InputDecoration(
                    labelText: "KM Range (e.g. 5km, 10km)",
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Price (₹)",
                    prefixIcon: const Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() => DropdownButtonFormField<int>(
                      value: selectedPatients.value,
                      decoration: InputDecoration(
                        labelText: "Max Patients per Slot",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: patientOptions
                          .map((v) => DropdownMenuItem(
                              value: v, child: Text("$v patients")))
                          .toList(),
                      onChanged: (v) => selectedPatients.value = v!,
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.appPrimaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            onPressed: () {
              if (selectedSlot == null ||
                  kmCtrl.text.isEmpty ||
                  priceCtrl.text.isEmpty) {
                customToast("Please fill all fields", Colors.red);
                return;
              }

              final payload = {
                "diagnostic_center_id": int.parse(widget.diagnosticId),
                "slot": selectedSlot!,
                "km_range": kmCtrl.text.trim(),
                "price": int.parse(priceCtrl.text.trim()),
                "no_of_patient": selectedPatients.value,
              };

              if (isEdit) {
                scheduleCtrl.updateSchedule(slot['id'], payload);
              } else {
                scheduleCtrl.addSchedule(payload);
              }
              Get.back();
            },
            child: Text(isEdit ? "Update" : "Add Slot",
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ====================== CONTROLLERS ======================

class DiagnosticBranchController extends GetxController {
  var branches = <Map<String, dynamic>>[].obs;
  var isLoadingBranches = true.obs;

  @override
  void onInit() {
    fetchBranches();
    super.onInit();
  }

  Future<void> fetchBranches() async {
    isLoadingBranches.value = true;
    try {
      final token = await readStr('token') ?? '';
      final profileId = await readStr('profileId') ?? '1';

      final url = '${AppConstants.endpoint}/diagnostics/centers/$profileId';

      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['status'] == true) {
          final details = res['diagnosticCenterDetails'];

          // FIXED: Handle single object OR list
          if (details is Map<String, dynamic>) {
            branches.assign(details); // Single branch
          } else if (details is List) {
            branches.assignAll(details.cast<Map<String, dynamic>>());
          } else {
            branches.clear();
          }
        } else {
          customToast("No branches found");
          branches.clear();
        }
      } else {
        customToast("Server error: ${response.statusCode}");
        branches.clear();
      }
    } catch (e) {
      customToast("Network error: $e");
      branches.clear();
    } finally {
      isLoadingBranches.value = false;
    }
  }
}

class ScheduleController extends GetxController {
  var schedule = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  final List<String> slots = [
    "07:00 AM - 08:00 AM",
    "08:00 AM - 09:00 AM",
    "09:00 AM - 10:00 AM",
    "10:00 AM - 11:00 AM",
    "11:00 AM - 12:00 PM",
    "12:00 PM - 01:00 PM",
    "01:00 PM - 02:00 PM",
    "02:00 PM - 03:00 PM",
    "03:00 PM - 04:00 PM",
    "04:00 PM - 05:00 PM",
    "05:00 PM - 06:00 PM",
    "06:00 PM - 07:00 PM",
    "07:00 PM - 08:00 PM",
    "08:00 PM - 09:00 PM",
    "09:00 PM - 10:00 PM",
  ];

  Future<void> fetchSchedule(String diagnosticId, String date) async {
    isLoading.value = true;
    schedule.clear();

    try {
      final token = await readStr('token') ?? '';
      final url =
          '${AppConstants.endpoint}/diagnostics/centers/$diagnosticId/schedule-pricing?date=$date';

      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['status'] == true && res['data'] is List) {
          schedule.assignAll(List<Map<String, dynamic>>.from(res['data']));
        }
      }
    } catch (e) {
      customToast("Failed to load schedule");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addSchedule(Map<String, dynamic> payload) async {
    if (schedule.any((s) => s['slot'] == payload['slot'])) {
      customToast("This time slot already exists!", Colors.orange);
      return;
    }

    EasyLoading.show(status: 'Adding slot...');
    try {
      final token = await readStr('token') ?? '';
      final response = await http.post(
        Uri.parse(
            '${AppConstants.endpoint}/diagnostics/centers/schedule-pricing'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        customToast("Slot added successfully!", Colors.green);
        fetchSchedule(payload['diagnostic_center_id'].toString(),
            DateTime.now().toIso8601String().split('T').first);
      } else {
        customToast("Failed to add slot");
      }
    } catch (e) {
      customToast("Error: $e");
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> updateSchedule(int id, Map<String, dynamic> payload) async {
    EasyLoading.show(status: 'Updating...');
    try {
      final token = await readStr('token') ?? '';
      final response = await http.put(
        Uri.parse(
            '${AppConstants.endpoint}/diagnostics/centers/schedule-pricing/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        customToast("Updated successfully!", Colors.green);
        fetchSchedule(payload['diagnostic_center_id'].toString(),
            DateTime.now().toIso8601String().split('T').first);
      } else {
        customToast("Update failed");
      }
    } catch (e) {
      customToast("Error: $e");
    } finally {
      EasyLoading.dismiss();
    }
  }
}
