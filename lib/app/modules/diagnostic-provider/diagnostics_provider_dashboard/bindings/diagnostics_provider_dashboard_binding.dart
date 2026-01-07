import 'package:get/get.dart';
import '../controllers/diagnostics_provider_dashboard_controller.dart';
import '../controllers/radiologist_dashboard_controller.dart.dart';

class DiagnosticsProviderDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DiagnosticsProviderDashboardController>(
      () => DiagnosticsProviderDashboardController(),
    );
    Get.lazyPut<RadiologistDashboardController>(
      () => RadiologistDashboardController(),
    );
  }
}
