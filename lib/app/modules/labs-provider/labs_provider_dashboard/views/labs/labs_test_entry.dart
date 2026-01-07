// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import '../../../../../../constants/app_constants.dart';
import '../../../../../../utils/client_side_validation.dart';
import '../../../../../../utils/helper.dart';
import '../../../../../data/static_data.dart';
import '../../../../../routes/app_pages.dart';
import '../../../component/lab_bottom_navbar.dart';
import '../../controllers/labs_provider_dashboard_controller.dart';

// Turnaround Time Options - EXACT VALUES
final turnaroundOptions = [
  '12 hours',
  '24 hours',
  '48 hours',
  '72 hours',
  '> 3 days',
];

class LabsTestEntry extends GetView<LabsProviderDashboardController> {
  LabsTestEntry({super.key});

  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.isClosed) {
        controller.getLabTestList('');
      }
    });

    return WillPopScope(
      onWillPop: () async {
        Get.offNamed(Routes.LABS_PROVIDER_DASHBOARD);
        return false;
      },
      child: RefreshConfiguration(
        headerTriggerDistance: MediaQuery.of(context).size.height / 8,
        child: Scaffold(
          appBar: _buildAppBar(),
          floatingActionButton: _buildFAB(),
          body: GetBuilder<LabsProviderDashboardController>(
            id: 'labs-test-list',
            builder: (ctrl) => _buildBody(ctrl, context),
          ),
          bottomNavigationBar: const LabProviderBottomNavBar(index: 3),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppConstants.appPrimaryColor,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: Image.asset('assets/logo/logo.png',
          height: 150, width: 150, color: Colors.white),
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      backgroundColor: AppConstants.appPrimaryColor,
      mini: true,
      elevation: 0,
      onPressed: () {
        Get.dialog(
          LabTestFormModal(
            initialData: null,
            onSubmit: (data) => controller.getLabTestList(''),
          ),
        );
      },
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  Widget _buildBody(
      LabsProviderDashboardController ctrl, BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search test name, code, or type...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ctrl.getLabTestList('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[50],
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppConstants.appPrimaryColor),
                  borderRadius: BorderRadius.circular(20)),
              focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: AppConstants.appPrimaryColor, width: 2),
                  borderRadius: BorderRadius.circular(20)),
            ),
            onChanged: (value) => ctrl.searchLabTests(value.trim()),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SmartRefresher(
            controller: _refreshController,
            enablePullDown: true,
            enablePullUp: false,
            header: const WaterDropHeader(),
            onRefresh: () async {
              await ctrl.getLabTestList('');
              _searchController.clear();
              _refreshController.refreshCompleted();
            },
            child: ctrl.isLoading.isTrue
                ? const Center(child: CircularProgressIndicator())
                : ctrl.labTestList.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemCount: ctrl.labTestList.length,
                        itemBuilder: (context, index) {
                          final test = ctrl.labTestList[index];
                          return _buildTestCard(test, context);
                        },
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No tests found',
              style: TextStyle(fontSize: 20, color: Colors.grey[600])),
          const SizedBox(height: 8),
          const Text('Tap + to add your first test'),
        ],
      ),
    );
  }

  Widget _buildTestCard(Map<String, dynamic> test, BuildContext context) {
    final oldPrice = (test['old_test_charges'] as num?)?.toDouble() ?? 0.0;
    final newPrice = (test['new_test_charges'] as num?)?.toDouble() ?? 0.0;
    final discount =
        oldPrice > 0 ? ((oldPrice - newPrice) / oldPrice * 100) : 0.0;
    final isActive = test['is_active'] == true;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isActive
                ? [Colors.white, Colors.blue[50]!]
                : [Colors.grey[100]!, Colors.grey[200]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            test['test_name'].toString().capitalizeFirst ??
                                'Unknown Test',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text('Code: ${test['test_code'] ?? 'N/A'}',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[700])),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(isActive ? 'Active' : 'Inactive',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  _infoChip(Icons.category, test['test_type'] ?? 'N/A'),
                  const SizedBox(width: 8),
                  _infoChip(
                      Icons.health_and_safety, test['organ_system'] ?? 'N/A'),
                ],
              ),
              const SizedBox(height: 12),
              Text(test['test_description'] ?? 'No description',
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (oldPrice > 0)
                    Text('₹${oldPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                            decoration: TextDecoration.lineThrough)),
                  const SizedBox(width: 8),
                  Text('₹${newPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                  const SizedBox(width: 8),
                  if (discount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12)),
                      child: Text('${discount.toStringAsFixed(0)}% OFF',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text('${test['lab_details']?.length ?? 0} Branches',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.dialog(
                      LabTestFormModal(
                        initialData: test,
                        onSubmit: (data) => controller.getLabTestList(''),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.appPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.blue[700]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.blue[900])),
      ]),
    );
  }
}

// =================================== LAB TEST FORM MODAL ===================================
class LabTestFormModal extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map) onSubmit;

  const LabTestFormModal({Key? key, this.initialData, required this.onSubmit})
      : super(key: key);

  @override
  State<LabTestFormModal> createState() => _LabTestFormModalState();
}

class _LabTestFormModalState extends State<LabTestFormModal> {
  late final bool isEdit;
  final ctrl = Get.put(LabsProviderDashboardController());
  final labsformKey = GlobalKey<FormState>();

  late final TextEditingController testNameCtrl;
  late final TextEditingController testCodeCtrl;
  late final TextEditingController testTypeCtrl;
  late final TextEditingController organCtrl;
  late final TextEditingController sampleCtrl;
  late final TextEditingController descCtrl;
  late final TextEditingController prepCtrl;
  late final TextEditingController oldPriceCtrl;
  late final TextEditingController newPriceCtrl;

  String? selectedTurnaroundTime;
  bool prescriptionRequired = false;
  List selectedLabs = [];
  List allLabs = [];

  @override
  void initState() {
    super.initState();
    isEdit = widget.initialData != null;

    testNameCtrl =
        TextEditingController(text: widget.initialData?['test_name'] ?? '');
    testCodeCtrl =
        TextEditingController(text: widget.initialData?['test_code'] ?? '');
    testTypeCtrl =
        TextEditingController(text: widget.initialData?['test_type'] ?? '');
    organCtrl =
        TextEditingController(text: widget.initialData?['organ_system'] ?? '');
    sampleCtrl = TextEditingController(
        text: widget.initialData?['sample_required'] ?? '');
    descCtrl = TextEditingController(
        text: widget.initialData?['test_description'] ?? '');
    prepCtrl = TextEditingController(
        text: widget.initialData?['preparation_instructions'] ?? '');
    oldPriceCtrl = TextEditingController(
        text: widget.initialData?['old_test_charges']?.toString() ?? '');
    newPriceCtrl = TextEditingController(
        text: widget.initialData?['new_test_charges']?.toString() ?? '');

    // FIXED: Normalize turnaround time safely
    final rawTime = widget.initialData?['turnaround_time']?.toString().trim();
    selectedTurnaroundTime = _normalizeTurnaroundTime(rawTime);

    prescriptionRequired = widget.initialData?['prescription_required'] == true;

    _loadLabs();
  }

  String? _normalizeTurnaroundTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final lower = value.toLowerCase().trim();

    if (lower.contains('12')) return '12 hours';
    if (lower.contains('24')) return '24 hours';
    if (lower.contains('48')) return '48 hours';
    if (lower.contains('72')) return '72 hours';
    if (lower.contains('> 3') ||
        lower.contains('more than 3') ||
        lower.contains('3 days')) return '> 3 days';

    return turnaroundOptions
        .firstWhereOrNull((opt) => opt.toLowerCase() == lower);
  }

  Future<void> _loadLabs() async {
    final providerId = await readStr('profileId') ?? '1';
    final token = await readStr('token');
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConstants.endpoint}/labs/provider-dashboard/$providerId/lab-branches'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['status'] == true) {
          setState(() {
            allLabs = List<Map<String, dynamic>>.from(res['list']);
            if (isEdit && widget.initialData?['lab_details'] != null) {
              final selectedIds = (widget.initialData!['lab_details'] as List)
                  .map((e) => e['lab_id'].toString())
                  .toSet();
              selectedLabs = allLabs
                  .where(
                      (lab) => selectedIds.contains(lab['lab_id'].toString()))
                  .toList();
            }
          });
        }
      }
    } catch (e) {
      customToast('Failed to load labs', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 850),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(0)),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: AppConstants.appPrimaryColor,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(0))),
            title: Text(isEdit ? 'Edit Lab Test' : 'Add Lab Test',
                style: const TextStyle(fontSize: 20)),
            centerTitle: true,
            actions: [
              IconButton(
                  icon: const Icon(Icons.close), onPressed: () => Get.back())
            ],
          ),
          body: Form(
            key: labsformKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(testNameCtrl, 'Test Name', Icons.science,
                      validator: (v) =>
                          Validators.validRequired(v!, 'Test Name', min: 3)),
                  const SizedBox(height: 16),
                  _buildMultiSelectLabs(),
                  const SizedBox(height: 16),
                  _buildTextField(testCodeCtrl, 'Test Code', Icons.tag,
                      validator: (v) =>
                          Validators.validRequired(v!, 'Test Code')),
                  const SizedBox(height: 16),

                  TypeAheadFormField<String>(
                    textFieldConfiguration: TextFieldConfiguration(
                        controller: testTypeCtrl,
                        decoration:
                            _decoration('Test Type', Icons.category_outlined)),
                    suggestionsCallback: (pattern) {
                      final matches = <String>[];
                      for (var cat in labTestCategories) {
                        if (cat['category']
                            .toString()
                            .toLowerCase()
                            .contains(pattern.toLowerCase())) {
                          matches.add(cat['category']);
                        }
                        for (var test in cat['tests']) {
                          if (test
                              .toString()
                              .toLowerCase()
                              .contains(pattern.toLowerCase())) {
                            matches.add(test);
                          }
                        }
                      }
                      return matches;
                    },
                    itemBuilder: (context, suggestion) => ListTile(
                        leading: Icon(Icons.science,
                            color: AppConstants.appPrimaryColor),
                        title: Text(suggestion)),
                    onSuggestionSelected: (s) => testTypeCtrl.text = s,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),

                  const SizedBox(height: 16),

                  TypeAheadFormField<String>(
                    textFieldConfiguration: TextFieldConfiguration(
                        controller: organCtrl,
                        decoration: _decoration(
                            'Organ System', Icons.health_and_safety_outlined)),
                    suggestionsCallback: (pattern) => organSystemList
                        .where((s) =>
                            s.toLowerCase().contains(pattern.toLowerCase()))
                        .toList(),
                    itemBuilder: (context, suggestion) =>
                        ListTile(title: Text(suggestion)),
                    onSuggestionSelected: (s) => organCtrl.text = s,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),

                  const SizedBox(height: 16),
                  _buildTextField(sampleCtrl, 'Sample Required', Icons.biotech),
                  const SizedBox(height: 16),
                  _buildTextField(
                      descCtrl, 'Test Description', Icons.description,
                      maxLines: 3),
                  const SizedBox(height: 16),
                  _buildTextField(
                      prepCtrl, 'Preparation Instructions', Icons.info_outline,
                      maxLines: 3),
                  const SizedBox(height: 16),

                  // FIXED: Safe Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedTurnaroundTime,
                    decoration: _decoration('Turnaround Time', Icons.timer),
                    hint: const Text('Select turnaround time'),
                    items: turnaroundOptions
                        .map((time) =>
                            DropdownMenuItem(value: time, child: Text(time)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedTurnaroundTime = value),
                    validator: (v) =>
                        v == null ? 'Please select turnaround time' : null,
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                          child: _buildTextField(
                              newPriceCtrl, 'old Price', Icons.local_hospital,
                              keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildTextField(
                              oldPriceCtrl, 'New Price', Icons.home,
                              keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                          value: prescriptionRequired,
                          onChanged: (v) =>
                              setState(() => prescriptionRequired = v!),
                          activeColor: AppConstants.appPrimaryColor),
                      const Text('Prescription Required',
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: ctrl.isLoading.isTrue ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.appPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                      ),
                      child: Text(isEdit ? 'Update Test' : 'Add Test',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!labsformKey.currentState!.validate()) return;
    if (selectedLabs.isEmpty) {
      customToast('Please select at least one lab', Colors.red);
      return;
    }
    if (selectedTurnaroundTime == null) {
      customToast('Please select turnaround time', Colors.red);
      return;
    }

    final atLab = double.tryParse(newPriceCtrl.text);
    final atHome = double.tryParse(oldPriceCtrl.text);

    final payload = {
      if (isEdit) 'lab_test_id': widget.initialData!['lab_test_id'],
      'lab_ids': selectedLabs.map((e) => e['lab_id']).toList(),
      'test_name': testNameCtrl.text.trim(),
      'test_code': testCodeCtrl.text.trim(),
      'test_type': testTypeCtrl.text.trim(),
      'organ_system': organCtrl.text.trim(),
      'sample_required': sampleCtrl.text.trim(),
      'test_description': descCtrl.text.trim(),
      'preparation_instructions': prepCtrl.text.trim(),
      'turnaround_time': selectedTurnaroundTime,
      'new_test_charges': atLab,
      'old_test_charges': atHome,
      'prescription_required': prescriptionRequired,
    };

    await ctrl.submitTest(payload);
    Get.back();
    widget.onSubmit(payload);
  }

  Widget _buildMultiSelectLabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Assigned Labs',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50]),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              isExpanded: true,
              hint: const Text('Select labs'),
              value: null,
              items: allLabs.map<DropdownMenuItem<Map<String, dynamic>>>((lab) {
                final isSelected =
                    selectedLabs.any((s) => s['lab_id'] == lab['lab_id']);
                return DropdownMenuItem(
                    value: lab,
                    child: Row(children: [
                      Icon(
                          isSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(lab['lab_name'] ?? 'Unknown')),
                    ]));
              }).toList(),
              onChanged: (lab) {
                if (lab != null) {
                  setState(() {
                    selectedLabs.any((s) => s['lab_id'] == lab['lab_id'])
                        ? selectedLabs
                            .removeWhere((s) => s['lab_id'] == lab['lab_id'])
                        : selectedLabs.add(lab);
                  });
                }
              },
            ),
          ),
        ),
        if (selectedLabs.isNotEmpty)
          Wrap(
            spacing: 8,
            children: selectedLabs
                .map((lab) => Chip(
                      label: Text(lab['lab_name']),
                      backgroundColor:
                          AppConstants.appPrimaryColor.withOpacity(0.2),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => setState(() => selectedLabs.remove(lab)),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController c, String label, IconData icon,
      {TextInputType? keyboardType,
      int maxLines = 1,
      String? hint,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator ?? (v) => v!.trim().isEmpty ? 'Required' : null,
      decoration: _decoration(label, icon, hint: hint),
    );
  }

  InputDecoration _decoration(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint ?? 'Enter $label',
      prefixIcon: Icon(icon, color: AppConstants.appPrimaryColor),
      filled: true,
      fillColor: Colors.grey[50],
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
