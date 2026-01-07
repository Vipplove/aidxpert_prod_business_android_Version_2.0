// ignore_for_file: depend_on_referenced_packages, deprecated_member_use, must_be_immutable
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:custom_date_range_picker/custom_date_range_picker.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import '../../../../../../constants/app_constants.dart';
import '../../../../../routes/app_pages.dart';
import '../../../component/lab_bottom_navbar.dart';
import '../../controllers/labs_provider_dashboard_controller.dart';

class LabsBookingHistoryView extends StatefulWidget {
  const LabsBookingHistoryView({super.key});

  @override
  State<LabsBookingHistoryView> createState() => _LabsBookingHistoryViewState();
}

class _LabsBookingHistoryViewState extends State<LabsBookingHistoryView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LabsProviderDashboardController ctrl =
      Get.put(LabsProviderDashboardController());
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
    _tabController.addListener(_onTabChanged);
    ctrl.fetchBookingsByTab('today');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    for (var rc in _refreshControllers) {
      rc.dispose();
    }
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final tab = _tabs[_tabController.index].toLowerCase();
    _searchController.clear();
    _startDate = null;
    _endDate = null;
    ctrl.fetchBookingsByTab(tab);
  }

  String _formatDate(DateTime date) => date.toIso8601String().split('T').first;

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
        ctrl.fetchBookingsByTab(
          _tabs[_tabController.index].toLowerCase(),
          startDate: _formatDate(start),
          endDate: _formatDate(end),
        );
      },
      onCancelClick: () {
        setState(() {
          _startDate = null;
          _endDate = null;
        });
        ctrl.fetchBookingsByTab(_tabs[_tabController.index].toLowerCase());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return WillPopScope(
      onWillPop: () async {
        Get.offNamed(Routes.LABS_PROVIDER_DASHBOARD);
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
        bottomNavigationBar: const LabProviderBottomNavBar(index: 1),
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
        onTap: (_) => _onTabChanged(),
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
                    _onTabChanged();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide:
                  BorderSide(color: AppConstants.appPrimaryColor, width: 2)),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            ctrl.searchTestBookingList(value);
          } else {
            _onTabChanged();
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
    final RefreshController rc = _refreshControllers[tabIndex];
    return SmartRefresher(
      controller: rc,
      enablePullDown: true,
      header: const WaterDropHeader(),
      onRefresh: () async {
        await _refreshCurrentTab();
        rc.refreshCompleted();
      },
      child: Obx(() {
        final bookings = ctrl.getBookingsForTab(tab.toLowerCase());
        final loading = ctrl.isLoading.value && bookings.isEmpty;

        if (loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (bookings.isEmpty) {
          return _buildEmptyState(tab);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: bookings.length,
          itemBuilder: (c, i) => _buildBookingCard(bookings[i], ctrl, tabIndex),
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
          Text('No $tab bookings',
              style: TextStyle(fontSize: 20, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Pull down to refresh',
              style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  // Helper to refresh current tab with filters
  Future<void> _refreshCurrentTab() async {
    final currentTab = _tabs[_tabController.index].toLowerCase();
    await ctrl.fetchBookingsByTab(
      currentTab,
      startDate: _startDate != null ? _formatDate(_startDate!) : null,
      endDate: _endDate != null ? _formatDate(_endDate!) : null,
    );
  }

  /* --------------------------------------------------------------------- */
  /*                         FIXED BOOKING CARD                           */
  /* --------------------------------------------------------------------- */
  Widget _buildBookingCard(
      Map<String, dynamic> booking, dynamic ctrl, int tabIndex) {
    final patient = booking['patient_details']?['user'] ?? {};
    final patientInfo = booking['patient_info'] ?? {};
    final tests = List.from(booking['lab_test_details'] ?? []);
    final status = (booking['booking_status'] ?? '').toString().toUpperCase();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Get.toNamed(Routes.LABS_TEST_DETAILS, arguments: booking),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: patient['profile_image_name'] != null
                        ? NetworkImage(patient['profile_image_name'])
                        : const AssetImage('assets/images/user_placeholder.png')
                            as ImageProvider,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patientInfo['name'].toString().capitalizeFirst ??
                              'Unknown Patient',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Booking ID: ${booking['lab_test_booking_id']}',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          children: tests
                              .take(2)
                              .map<Widget>(
                                (t) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Chip(
                                    label: Text(t['test_name'],
                                        style: const TextStyle(fontSize: 12)),
                                    backgroundColor: AppConstants
                                        .appPrimaryColor
                                        .withOpacity(0.1),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        if (tests.length > 2)
                          Text('+${tests.length - 2} more',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              _buildInfoRow(Icons.calendar_today,
                  '${booking['booking_date']} at ${booking['booking_time']}'),
              _buildInfoRow(Icons.location_on,
                  '${booking['patient_address']?['city']}, ${booking['patient_address']?['state']}'),
              _buildInfoRow(Icons.phone, patient['phone_number'] ?? 'N/A'),
              _buildInfoRow(Icons.bloodtype, patient['blood_group'] ?? 'N/A'),
              const Divider(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ── Status Chip ──────────────────────────────
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.capitalizeFirst!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // ── Popup Menu – NAMED + TAB REFRESH ────────
                  if (status != 'COMPLETED' && status != 'CANCELLED')
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        final currentTab =
                            _tabs[_tabController.index].toLowerCase();
                        await ctrl.updateBookingStatus(
                          bookingId: booking['lab_test_booking_id'],
                          status: value,
                          remark:
                              "Booking marked as ${value.replaceAll('_', ' ').toLowerCase()} by provider",
                          tab: currentTab, // Pass current tab
                        );
                        // Auto-refresh current tab
                        _refreshCurrentTab();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'CONFIRMED',
                          child: Text('Mark as Confirmed'),
                        ),
                        PopupMenuItem(
                          value: 'IN_PROGRESS',
                          child: Text('Mark as In Progress'),
                        ),
                        PopupMenuItem(
                          value: 'COMPLETED',
                          child: Text('Mark as Completed'),
                        ),
                        PopupMenuItem(
                          value: 'CANCELLED',
                          child: Text('Mark as Cancelled'),
                        ),
                      ],
                    ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppConstants.appPrimaryColor),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]))),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'CONFIRMED':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
}
