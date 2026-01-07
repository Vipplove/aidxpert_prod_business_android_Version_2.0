// ignore_for_file: depend_on_referenced_packages, deprecated_member_use, must_be_immutable
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:custom_date_range_picker/custom_date_range_picker.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import '../../../../../constants/app_constants.dart';
import '../../../../routes/app_pages.dart';
import '../../component/diagnostic_bottom_navbar.dart';
import '../controllers/diagnostics_provider_dashboard_controller.dart';

class DiagnosticsBookingHistoryView extends StatefulWidget {
  const DiagnosticsBookingHistoryView({super.key});

  @override
  State<DiagnosticsBookingHistoryView> createState() =>
      _DiagnosticsBookingHistoryViewState();
}

class _DiagnosticsBookingHistoryViewState
    extends State<DiagnosticsBookingHistoryView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DiagnosticsProviderDashboardController ctrl =
      Get.put(DiagnosticsProviderDashboardController());

  // One RefreshController per tab
  final List<RefreshController> _refreshControllers = [
    RefreshController(initialRefresh: false),
    RefreshController(initialRefresh: false),
    RefreshController(initialRefresh: false),
  ];

  final TextEditingController _searchController = TextEditingController();
  final List<String> _tabs = ['Today', 'Upcoming', 'Completed'];

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    ctrl.fetchBookingsByTab('today'); // Initial load
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    for (var rc in _refreshControllers) {
      rc.dispose();
    }
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final tab = _tabs[_tabController.index].toLowerCase();
      _searchController.clear();
      _refreshBookings(tab);
    }
  }

  String _formatDate(DateTime date) => date.toIso8601String().split('T').first;

  void _refreshBookings(String tab) {
    ctrl.fetchBookingsByTab(
      tab,
      startDate: _startDate != null ? _formatDate(_startDate!) : null,
      endDate: _endDate != null ? _formatDate(_endDate!) : null,
    );
  }

  void _showDateRangePicker() {
    showCustomDateRangePicker(
      context,
      dismissible: true,
      minimumDate: DateTime.now().subtract(const Duration(days: 365)),
      maximumDate: DateTime.now().add(const Duration(days: 365)),
      startDate: _startDate,
      endDate: _endDate,
      backgroundColor: Colors.white,
      primaryColor: AppConstants.appPrimaryColor,
      onApplyClick: (start, end) {
        setState(() {
          _startDate = start;
          _endDate = end;
        });
        final currentTab = _tabs[_tabController.index].toLowerCase();
        _refreshBookings(currentTab);
      },
      onCancelClick: () {
        setState(() {
          _startDate = null;
          _endDate = null;
        });
        final currentTab = _tabs[_tabController.index].toLowerCase();
        _refreshBookings(currentTab);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return WillPopScope(
      onWillPop: () async {
        Get.offNamed(Routes.DIAGNOSTIC_PROVIDER_DASHBOARD);
        return false;
      },
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF101822) : const Color(0xFFF6F7F8),
        appBar: _buildAppBar(),
        floatingActionButton: _buildFilterFAB(),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabs
                    .asMap()
                    .entries
                    .map((e) => _buildTabContent(e.value, e.key))
                    .toList(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const DiagnosticProviderBottomNavBar(index: 1),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppConstants.appPrimaryColor,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: Image.asset(
        'assets/logo/logo.png',
        height: 150,
        width: 150,
        color: Colors.white,
      ),
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: _tabs
            .map((tab) => Tab(
                  child: Text(
                    tab,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: TextField(
        controller: _searchController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Search by Booking ID...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _handleTabChange();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide:
                BorderSide(color: AppConstants.appPrimaryColor, width: 2),
          ),
        ),
        onChanged: (value) {
          final currentTab = _tabs[_tabController.index].toLowerCase();
          if (value.isNotEmpty) {
            ctrl.searchTestBookingList(value);
          } else {
            _refreshBookings(currentTab);
          }
        },
      ),
    );
  }

  Widget _buildFilterFAB() {
    return FloatingActionButton(
      backgroundColor: AppConstants.appPrimaryColor,
      mini: true,
      onPressed: _showDateRangePicker,
      child: const Icon(Icons.filter_alt, color: Colors.white),
    );
  }

  Widget _buildTabContent(String tab, int tabIndex) {
    final RefreshController refreshController = _refreshControllers[tabIndex];

    return SmartRefresher(
      controller: refreshController,
      enablePullDown: true,
      header: WaterDropHeader(
        waterDropColor: AppConstants.appPrimaryColor,
      ),
      onRefresh: () async {
        final currentTab = tab.toLowerCase();
        await ctrl.fetchBookingsByTab(
          currentTab,
          startDate: _startDate != null ? _formatDate(_startDate!) : null,
          endDate: _endDate != null ? _formatDate(_endDate!) : null,
        );
        refreshController.refreshCompleted();
      },
      child: Obx(() {
        final bookings = ctrl.getBookingsForTab(tab.toLowerCase());
        final isLoading = ctrl.isLoading.value;

        if (isLoading && bookings.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (bookings.isEmpty) {
          return _buildEmptyState(tab);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: bookings.length,
          itemBuilder: (context, index) => _buildBookingCard(bookings[index]),
        );
      }),
    );
  }

  Widget _buildEmptyState(String tab) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No $tab bookings',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final patientInfo = booking['patient_info'] ?? {};
    final patientName = patientInfo['name']?.toString().trim();

    final fallbackUser = booking['patient_details']?['user'] ?? {};
    final fallbackName =
        '${fallbackUser['first_name'] ?? ''} ${fallbackUser['last_name'] ?? ''}'
            .trim();

    final name = patientName?.isNotEmpty == true
        ? patientName!
        : (fallbackName.isNotEmpty ? fallbackName : 'Unknown Patient');

    final bookingId = booking['diagnostic_test_booking_id']?.toString() ?? '-';
    final bookingRefId = booking['booking_reference_no']?.toString() ?? '-';
    final List tests = booking['diagnostic_test_detail'] ?? [];
    final testCount = tests.length;
    final date = booking['booking_date'] ?? '-';
    final time = booking['booking_time'] ?? '-';

    final paymentId = booking['payment_id'];
    final finalCharges = (booking['final_charges'] as num?)?.toDouble() ?? 0.0;
    final isPaid = paymentId != null && finalCharges > 0;

    return InkWell(
      onTap: () {
        Get.toNamed(Routes.DIAGNOSTIC_TEST_DETAILS, arguments: booking);
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPaid ? 'Paid' : 'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPaid ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                        text: 'Booking ID: ',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13)),
                    TextSpan(
                        text: bookingId,
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                        text: 'Reference ID: ',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13)),
                    TextSpan(
                        text: bookingRefId,
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$testCount test${testCount == 1 ? '' : 's'} • $date at $time',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tests.take(2).map((t) {
                        final testName = t['test_name']?.toString() ?? 'Test';
                        return Chip(
                          label: Text(
                            testName,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          backgroundColor:
                              AppConstants.appPrimaryColor.withOpacity(0.1),
                          side: BorderSide(
                              color: AppConstants.appPrimaryColor
                                  .withOpacity(0.3)),
                        );
                      }).toList(),
                    ),
                  ),
                  if (tests.length > 2)
                    Text('+${tests.length - 2}',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
