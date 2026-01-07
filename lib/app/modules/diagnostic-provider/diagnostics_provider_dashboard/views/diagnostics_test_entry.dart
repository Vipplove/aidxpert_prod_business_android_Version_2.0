// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/client_side_validation.dart';
import '../../../../../utils/helper.dart';
import '../../../../data/static_data.dart';
import '../../../../routes/app_pages.dart';
import '../../component/diagnostic_bottom_navbar.dart';
import '../controllers/diagnostics_provider_dashboard_controller.dart';

// Turnaround Time Options - EXACT VALUES
final turnaroundOptions = [
  '12 hours',
  '24 hours',
  '48 hours',
  '72 hours',
  '> 3 days',
];

class DiagnosticsTestEntry
    extends GetView<DiagnosticsProviderDashboardController> {
  DiagnosticsTestEntry({super.key});

  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.isClosed) {
        controller.getDiagnosticTestList('');
      }
    });

    return WillPopScope(
      onWillPop: () async {
        Get.offNamed(Routes.DIAGNOSTIC_PROVIDER_DASHBOARD);
        return false;
      },
      child: RefreshConfiguration(
        headerTriggerDistance: MediaQuery.of(context).size.height / 8,
        child: Scaffold(
          appBar: _buildAppBar(),
          floatingActionButton: _buildFAB(),
          body: GetBuilder<DiagnosticsProviderDashboardController>(
            id: 'diagnostic-test-list',
            builder: (ctrl) => _buildBody(ctrl, context),
          ),
          bottomNavigationBar: const DiagnosticProviderBottomNavBar(index: 3),
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
          DiagnosticTestFormModal(
            initialData: null,
            onSubmit: (data) => controller.getDiagnosticTestList(''),
          ),
        );
      },
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  Widget _buildBody(
      DiagnosticsProviderDashboardController ctrl, BuildContext context) {
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
                        ctrl.getDiagnosticTestList('');
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
            onChanged: (value) => ctrl.searchDiagnosticTests(value.trim()),
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
              await ctrl.getDiagnosticTestList('');
              _searchController.clear();
              _refreshController.refreshCompleted();
            },
            child: ctrl.isLoading.isTrue
                ? const Center(child: CircularProgressIndicator())
                : ctrl.diagnosticTestList.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemCount: ctrl.diagnosticTestList.length,
                        itemBuilder: (context, index) {
                          final test = ctrl.diagnosticTestList[index];
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
    final serviceCharge = (test['service_charge'] as num?)?.toDouble() ?? 0.0;
    final totalPrice = newPrice + serviceCharge;

    // Calculate discount percentage
    final discountPercent =
        oldPrice > 0 ? ((oldPrice - newPrice) / oldPrice * 100) : 0.0;

    final isActive = test['is_active'] == true;
    final requiresPrescription = test['prescription_required'] == true;
    final List centerDetails = test['center_details'] as List? ?? [];
    final branchCount = centerDetails.length;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: isActive
                ? [Colors.white, Colors.blue.shade50]
                : [Colors.grey.shade100, Colors.grey.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name + Status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          test['test_name']?.toString().capitalizeFirst ??
                              'Unknown Test',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Code: ${test['test_code'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Active / Inactive Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.redAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Category & Type Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _infoChip(Icons.category, test['category'] ?? 'N/A',
                      color: Colors.purple.shade600),
                  _infoChip(Icons.science, test['test_type'] ?? 'Standard',
                      color: Colors.orange.shade700),
                  if (requiresPrescription)
                    _infoChip(Icons.receipt_long, 'Prescription Required',
                        color: Colors.red.shade600),
                ],
              ),

              const SizedBox(height: 12),

              // Preparation Instructions
              if (test['preparation_instructions'] != null &&
                  test['preparation_instructions'].toString().trim().isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: Colors.amber.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          test['preparation_instructions'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.brown.shade800,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // Turnaround Time
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Report in: ${test['turnaround_time'] ?? 'Not specified'}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Pricing Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '₹${newPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${oldPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.appPrimaryColor,
                        ),
                      ),
                      if (serviceCharge > 0)
                        Text(
                          ' + ₹$serviceCharge service',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                        ),
                      const Spacer(),
                      if (discountPercent > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${discountPercent.toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (totalPrice != newPrice)
                    Text(
                      'Total: ₹${totalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Branch Count
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 16, color: Colors.blue.shade600),
                  const SizedBox(width: 6),
                  Text(
                    '$branchCount ${branchCount == 1 ? 'Branch' : 'Branches'} Available',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Edit Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.dialog(
                      DiagnosticTestFormModal(
                        initialData: test,
                        onSubmit: (data) =>
                            controller.getDiagnosticTestList(''),
                      ),
                      barrierDismissible: false,
                    );
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.appPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Helper chip widget
  Widget _infoChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue.shade600).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color ?? Colors.blue.shade600),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.blue.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

// =================================== DIAGNOSTIS TEST FORM MODAL ===================================
class DiagnosticTestFormModal extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map) onSubmit;

  const DiagnosticTestFormModal(
      {Key? key, this.initialData, required this.onSubmit})
      : super(key: key);

  @override
  State<DiagnosticTestFormModal> createState() =>
      _DiagnosticTestFormModalState();
}

class _DiagnosticTestFormModalState extends State<DiagnosticTestFormModal> {
  late final bool isEdit;
  final ctrl = Get.put(DiagnosticsProviderDashboardController());
  final diagnosticformKey = GlobalKey<FormState>();

  late final TextEditingController testNameCtrl;
  late final TextEditingController testCodeCtrl;
  late final TextEditingController testTypeCtrl;
  late final TextEditingController catgCtrl;
  late final TextEditingController prepCtrl;
  late final TextEditingController oldPriceCtrl;
  late final TextEditingController newPriceCtrl;

  String? selectedTurnaroundTime;
  bool prescriptionRequired = false;
  List selectedDignostic = [];
  List allDiagnostic = [];

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
    catgCtrl =
        TextEditingController(text: widget.initialData?['category'] ?? '');

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

    _loadDiagnostic();
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

  Future<void> _loadDiagnostic() async {
    final providerId = await readStr('profileId') ?? '1';
    final token = await readStr('token');

    try {
      final response = await http.get(
        Uri.parse(
          '${AppConstants.endpoint}/diagnostics/provider-dashboard/$providerId/centers',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final res = json.decode(response.body);

        if (res['status'] == true) {
          final List<dynamic> list = res['list'] ?? [];
          final diagnostics = List<Map<String, dynamic>>.from(list);

          setState(() {
            allDiagnostic = diagnostics;

            // === FIXED: Correct key matching for Edit mode ===
            if (isEdit && widget.initialData != null) {
              final List centerDetails =
                  widget.initialData!['center_details'] ?? [];
              final Set selectedIds =
                  centerDetails.map((e) => e['diagnostic_center_id']).toSet();

              selectedDignostic = diagnostics
                  .where((center) =>
                      selectedIds.contains(center['diagnostic_center_id']))
                  .toList();
            }
          });
        }
      }
    } catch (e) {
      customToast('Failed to load centers', Colors.red);
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
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(0))),
            title: Text(isEdit ? 'Edit Diagnostic Test' : 'Add Diagnostic Test',
                style: const TextStyle(fontSize: 20)),
            centerTitle: true,
            actions: [
              IconButton(
                  icon: const Icon(Icons.close), onPressed: () => Get.back())
            ],
          ),
          body: Form(
            key: diagnosticformKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(testNameCtrl, 'Test Name', Icons.science,
                      validator: (v) =>
                          Validators.validRequired(v!, 'Test Name', min: 3)),
                  const SizedBox(height: 16),
                  _buildMultiSelectDiagnostics(),
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

                  DropdownButtonFormField<String>(
                    decoration: _decoration(
                      'Category',
                      Icons.health_and_safety_outlined,
                    ),
                    value: catgCtrl.text.isNotEmpty ? catgCtrl.text : null,
                    items: testCategoryEnum.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      catgCtrl.text = value!;
                    },
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),

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
    if (!diagnosticformKey.currentState!.validate()) return;
    if (selectedDignostic.isEmpty) {
      customToast('Please select at least one dignostic', Colors.red);
      return;
    }
    if (selectedTurnaroundTime == null) {
      customToast('Please select turnaround time', Colors.red);
      return;
    }

    final payload = {
      if (isEdit)
        'diagnostic_test_id': widget.initialData!['diagnostic_test_id'],
      'diagnostic_center_ids':
          selectedDignostic.map((e) => e['diagnostic_center_id']).toList(),
      'test_name': testNameCtrl.text.trim(),
      'test_code': testCodeCtrl.text.trim(),
      'test_type': testTypeCtrl.text.trim(),
      'category': catgCtrl.text.trim(),
      'preparation_instructions': prepCtrl.text.trim(),
      'turnaround_time': selectedTurnaroundTime,
      'new_test_charges': double.tryParse(newPriceCtrl.text) ?? 0.0,
      'old_test_charges': double.tryParse(oldPriceCtrl.text) ?? 0.0,
      'prescription_required': prescriptionRequired,
    };

    await ctrl.submitTest(payload);
    Get.back();
    widget.onSubmit(payload);
  }

  Widget _buildMultiSelectDiagnostics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Assigned Diagnostic Centers',
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
              hint: const Text('Select Diagnostic Centers'),
              value: null,
              items: allDiagnostic
                  .map<DropdownMenuItem<Map<String, dynamic>>>((center) {
                final isSelected = selectedDignostic.any((s) =>
                    s['diagnostic_center_id'] ==
                    center['diagnostic_center_id']);
                return DropdownMenuItem(
                  value: center,
                  child: Row(children: [
                    Icon(
                      isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 20,
                      color: AppConstants.appPrimaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(center['center_name'] ?? 'Unknown')),
                  ]),
                );
              }).toList(),
              onChanged: (center) {
                if (center != null) {
                  setState(() {
                    final id = center['diagnostic_center_id'];
                    if (selectedDignostic
                        .any((s) => s['diagnostic_center_id'] == id)) {
                      selectedDignostic
                          .removeWhere((s) => s['diagnostic_center_id'] == id);
                    } else {
                      selectedDignostic.add(center);
                    }
                  });
                }
              },
            ),
          ),
        ),
        if (selectedDignostic.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              children: selectedDignostic
                  .map((center) => Chip(
                        label: Text(center['center_name']),
                        backgroundColor:
                            AppConstants.appPrimaryColor.withOpacity(0.2),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () =>
                            setState(() => selectedDignostic.remove(center)),
                      ))
                  .toList(),
            ),
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
