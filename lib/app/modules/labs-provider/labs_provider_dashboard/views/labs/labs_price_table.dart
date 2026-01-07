// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../../constants/app_constants.dart';
import '../../../../../../utils/helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LabPriceTable extends StatefulWidget {
  const LabPriceTable({super.key});

  @override
  State<LabPriceTable> createState() => _LabPriceTableState();
}

class _LabPriceTableState extends State<LabPriceTable> {
  final LabBranchController controller = Get.put(LabBranchController());

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
        title: const Text("Lab Branches & Schedule",
            style: TextStyle(color: Colors.white)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoadingBranches.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.branches.isEmpty) {
          return const Center(
            child: Text(
              "No branches found",
              style: TextStyle(fontSize: 16, color: Colors.grey),
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
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showScheduleBottomSheet(branch),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                branch['lab_name'].toString().capitalizeFirst ?? 'Unknown Lab',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "${branch['lab_address']}, ${branch['area']}, ${branch['city']}",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    branch['state'] ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
    final labId = branch['lab_id'].toString();
    final initialDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    Get.bottomSheet(
      ScheduleBottomSheet(
        labId: labId,
        branchName: branch['lab_name'].toString().capitalizeFirst ?? 'Lab',
        initialDate: initialDate,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }
}

// ====================== BOTTOM SHEET ======================
class ScheduleBottomSheet extends StatefulWidget {
  final String labId;
  final String branchName;
  final String initialDate;

  const ScheduleBottomSheet({
    super.key,
    required this.labId,
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
    selectedPatients = 1.obs;
    scheduleCtrl.fetchSchedule(widget.labId, selectedDate);
  }

  @override
  void dispose() {
    Get.delete<ScheduleController>();
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
                padding: const EdgeInsets.all(16),
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
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) {
                      selectedDate = DateFormat('yyyy-MM-dd').format(date);
                      scheduleCtrl.fetchSchedule(widget.labId, selectedDate);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 8),
                        Text(DateFormat('dd MMM, yyyy')
                            .format(DateTime.parse(selectedDate))),
                      ],
                    ),
                  ),
                ),
              ),

              // Add Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddScheduleDialog(),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text("Add Schedule",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.appPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Schedule List
              Expanded(
                child: Obx(() {
                  if (scheduleCtrl.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (scheduleCtrl.schedule.isEmpty) {
                    return const Center(
                      child: Text("No schedule found for this date",
                          style: TextStyle(color: Colors.grey)),
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
    final total = slot['no_of_patient'] ?? 0;
    final available = total - booked;

    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          slot['slot'] ?? 'Unknown Slot',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text("₹${slot['price']} • ${slot['km_range']}Km"),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildChip("Booked: $booked", Colors.red),
                const SizedBox(width: 8),
                _buildChip("Available: $available", Colors.green),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.edit, color: Colors.blue),
        onTap: () => _showAddScheduleDialog(slot: slot),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
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
    selectedPatients.value = slot?['no_of_patient'] ?? 1;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? "Edit Schedule" : "Add Schedule"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: "Time Slot", border: OutlineInputBorder()),
                value: selectedSlot,
                items: scheduleCtrl.slots
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => selectedSlot = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: kmCtrl,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: "KM Range (e.g. 5km)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Price (₹)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Obx(() => DropdownButtonFormField<int>(
                    value: selectedPatients.value,
                    decoration: const InputDecoration(
                      labelText: "Max Patients",
                      border: OutlineInputBorder(),
                    ),
                    items: patientOptions
                        .map((v) => DropdownMenuItem<int>(
                            value: v, child: Text(v.toString())))
                        .toList(),
                    onChanged: (v) => selectedPatients.value = v!,
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.appPrimaryColor),
            onPressed: () {
              if (selectedSlot == null ||
                  kmCtrl.text.isEmpty ||
                  priceCtrl.text.isEmpty) {
                customToast("Please fill all fields");
                return;
              }

              final payload = {
                "lab_id": int.parse(widget.labId),
                "slot": selectedSlot!,
                "km_range": kmCtrl.text.trim(),
                "price": priceCtrl.text.trim(),
                "no_of_patient": selectedPatients.value,
              };

              if (isEdit) {
                scheduleCtrl.updateSchedule(slot['id'], payload);
              } else {
                scheduleCtrl.addSchedule(payload);
              }
              Get.back();
            },
            child: Text(isEdit ? "Update" : "Add",
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ====================== CONTROLLERS ======================

class LabBranchController extends GetxController {
  var branches = <Map<String, dynamic>>[].obs;
  var isLoadingBranches = true.obs;

  Future<void> fetchBranches() async {
    isLoadingBranches.value = true;
    try {
      final token = await readStr('token') ?? '';
      final profileId = await readStr('profileId') ?? '1';

      final response = await http.get(
        Uri.parse(
            '${AppConstants.endpoint}/labs/provider-dashboard/$profileId/lab-branches'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['status'] == true) {
          branches.value = List<Map<String, dynamic>>.from(res['list'] ?? []);
        } else {
          customToast("No branches found");
        }
      } else {
        customToast("Failed to load branches");
      }
    } catch (e) {
      customToast("Error: $e");
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

  Future<void> fetchSchedule(String labId, String date) async {
    isLoading.value = true;
    schedule.clear();

    try {
      final token = await readStr('token') ?? '';
      final response = await http.get(
        Uri.parse(
            '${AppConstants.endpoint}/labs/$labId/schedule-pricing?date=$date'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['status'] == true) {
          schedule.value = List<Map<String, dynamic>>.from(res['data'] ?? []);
        }
      } else {
        customToast("No schedule found");
      }
    } catch (e) {
      customToast("Error loading schedule: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addSchedule(Map<String, dynamic> payload) async {
    final ScheduleController scheduleCtrl = Get.find<ScheduleController>();

    String newSlot = payload['slot'];
    bool slotExists =
        scheduleCtrl.schedule.any((item) => item['slot'] == newSlot);

    if (slotExists) {
      customToast("Slot Already Exists", Colors.red);
      return;
    }

    EasyLoading.show(status: 'Saving Slot...');
    try {
      final token = await readStr('token') ?? '';
      final response = await http.post(
        Uri.parse('${AppConstants.endpoint}/labs/schedule-pricing'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        customToast("Schedule added!", Colors.green);
        fetchSchedule(payload['lab_id'].toString(),
            DateTime.now().toString().split(' ')[0]);
      } else {
        customToast("Failed to add schedule");
      }
    } catch (e) {
      customToast("Error: $e");
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> updateSchedule(int id, Map<String, dynamic> payload) async {
    EasyLoading.show(status: 'Saving Slot...');
    try {
      final token = await readStr('token') ?? '';
      final response = await http.put(
        Uri.parse('${AppConstants.endpoint}/labs/schedule-pricing/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        customToast("Schedule updated!", Colors.green);
        fetchSchedule(payload['lab_id'].toString(),
            DateTime.now().toString().split(' ')[0]);
      } else {
        customToast("Failed to update");
      }
    } catch (e) {
      customToast("Error: $e");
    } finally {
      EasyLoading.dismiss();
    }
  }
}
