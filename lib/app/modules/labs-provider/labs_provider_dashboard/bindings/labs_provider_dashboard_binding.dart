import 'package:get/get.dart';
import '../controllers/labs_provider_dashboard_controller.dart';
import '../controllers/pathologist_dashboard_controller.dart.dart';

class LabsProviderDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LabsProviderDashboardController>(
      () => LabsProviderDashboardController(),
    );
    Get.lazyPut<PathologistDashboardController>(
      () => PathologistDashboardController(),
    );
  }
}
