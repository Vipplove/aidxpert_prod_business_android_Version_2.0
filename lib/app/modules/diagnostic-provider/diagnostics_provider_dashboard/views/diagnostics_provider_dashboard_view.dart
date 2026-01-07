// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';
import '../../../../routes/app_pages.dart';
import '../../component/diagnostic_bottom_navbar.dart';
import '../controllers/diagnostics_provider_dashboard_controller.dart';

class DiagnosticsProviderDashboardView extends StatefulWidget {
  const DiagnosticsProviderDashboardView({super.key});

  @override
  State<DiagnosticsProviderDashboardView> createState() =>
      _DiagnosticsProviderDashboardViewState();
}

class _DiagnosticsProviderDashboardViewState
    extends State<DiagnosticsProviderDashboardView>
    with SingleTickerProviderStateMixin {
  final RefreshController _refreshController = RefreshController();
  late TabController _tabController;

  final List<String> _tabs = ['PENDING', 'IN_PROGRESS', 'CONFIRMED'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    Get.put(DiagnosticsProviderDashboardController());

    final ctrl = Get.find<DiagnosticsProviderDashboardController>();
    _loadInitialData(ctrl);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadTabData(ctrl);
      }
    });
  }

  Future<void> _loadInitialData(
      DiagnosticsProviderDashboardController ctrl) async {
    await Future.wait([
      ctrl.fetchAppointmentCounts(),
      _loadTabData(ctrl),
    ]);
  }

  Future<void> _loadTabData(DiagnosticsProviderDashboardController ctrl) async {
    final tab = _tabs[_tabController.index];
    await ctrl.getTestBookingList(tab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => await onWillPop(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7F8),
        appBar: _buildAppBar(),
        body: GetBuilder<DiagnosticsProviderDashboardController>(
          id: 'diagnostic-provider-dashboard',
          builder: (ctrl) {
            return SmartRefresher(
              controller: _refreshController,
              header: const WaterDropHeader(),
              onRefresh: () async {
                await _loadInitialData(ctrl);
                _refreshController.refreshCompleted();
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildMetrics(ctrl)),
                  SliverToBoxAdapter(child: _buildSegmentedTabs()),
                  _buildTaskList(ctrl),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: const DiagnosticProviderBottomNavBar(index: 0),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppConstants.appPrimaryColor,
      elevation: 0,
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
    );
  }

  // ---------- ANIMATED COUNTER ----------
  Widget _animatedCounter(int value, Color color) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, val, _) {
        return Text(
          val.toString(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        );
      },
    );
  }

  // ---------- METRICS ----------
  Widget _buildMetrics(DiagnosticsProviderDashboardController ctrl) {
    return GetBuilder<DiagnosticsProviderDashboardController>(
      id: 'diagnostic-provider-dashboard',
      builder: (_) {
        final metrics = [
          {
            'label': 'Total Patients',
            'value': ctrl.totalPatients.value,
            'icon': Icons.people,
            'color': Colors.blue[600]!
          },
          {
            'label': 'Today\'s Appointments',
            'value': ctrl.todayAppointments.value,
            'icon': Icons.today,
            'color': AppConstants.appPrimaryColor
          },
          {
            'label': 'Pending Tasks',
            'value': ctrl.pendingAppointments.value,
            'icon': Icons.hourglass_top,
            'color': Colors.orange[600]!
          },
          {
            'label': 'Completed Today',
            'value': ctrl.completedAppointments.value,
            'icon': Icons.task_alt,
            'color': Colors.green[600]!
          },
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: metrics
                .map((m) => SizedBox(
                      width: (Get.width - 44) / 2,
                      child: Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['label'] as String,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _animatedCounter(
                                      m['value'] as int, m['color'] as Color),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: (m['color'] as Color)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      m['icon'] as IconData,
                                      color: m['color'] as Color,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildSegmentedTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppConstants.appPrimaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[600],
          labelStyle: const TextStyle(fontSize: 13),
          tabs: _tabs
              .map((t) => Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                    child: Tab(text: t),
                  ))
              .toList(),
        ),
      ),
    );
  }

  // ---------- TASK LIST (per tab) ----------
  Widget _buildTaskList(DiagnosticsProviderDashboardController ctrl) {
    final list = ctrl.appointmentList;

    if (ctrl.isLoading.value) {
      return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()));
    }

    if (list.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No ${_tabs[_tabController.index].toLowerCase()}',
                style: TextStyle(fontSize: 20, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => _buildTaskCard(list[i]),
          childCount: list.length,
        ),
      ),
    );
  }

  // ---------- CARD LAYOUT ----------
  Widget _buildTaskCard(Map<String, dynamic> booking) {
    final patient = booking['patient_details']?['user'] ?? {};
    final patientInfo = booking['patient_info'] ?? {};

    // Updated test list key
    final tests = List.from(booking['diagnostic_test_detail'] ?? []);

    final name =
        '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}'.trim();

    // Updated booking ID key
    final bookingId = booking['diagnostic_test_booking_id']?.toString() ?? '-';
    final bookingRefId = booking['booking_reference_no']?.toString() ?? '-';

    final testCount = tests.length;
    final date = booking['booking_date'] ?? '-';
    final time = booking['booking_time'] ?? '-';

    // Updated payment status logic (based on booking_status)
    final bookingStatus = booking['booking_status']?.toString() ?? 'PENDING';
    final isPaid = bookingStatus.toUpperCase() == 'COMPLETED';

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
              // Row 1 — Patient + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      name.isEmpty ? 'Unknown Patient' : name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      bookingStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPaid ? Colors.green[800] : Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Booking ID
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Booking ID: ',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    TextSpan(
                      text: bookingId,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Reference ID: ',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    TextSpan(
                      text: bookingRefId,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Test Count + Date Time
              Text(
                '$testCount test${testCount == 1 ? '' : 's'} • $date at $time',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),

              const SizedBox(height: 12),

              // Test list (chip style)
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tests.take(2).map((t) {
                        return Chip(
                          label: Text(
                            t['test_name'] ?? 'Test',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          backgroundColor:
                              AppConstants.appPrimaryColor.withOpacity(0.1),
                          side: BorderSide(
                            color:
                                AppConstants.appPrimaryColor.withOpacity(0.3),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (tests.length > 2)
                    Text(
                      '+${tests.length - 2}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
