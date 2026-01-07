import 'package:get/get.dart';
import '../controllers/labs_provider_registration_controller.dart';

class LabsRegistrationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LabsProviderRegistrationController>(
      () => LabsProviderRegistrationController(),
    );
  }
}
