import 'package:get/get.dart';
import '../controllers/diagnostics_provider_registration_controller.dart';

class DiagnosticsRegistrationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DiagnosticsProviderRegistrationController>(
      () => DiagnosticsProviderRegistrationController(),
    );
  }
}
