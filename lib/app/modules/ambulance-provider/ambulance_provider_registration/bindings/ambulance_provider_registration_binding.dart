import 'package:get/get.dart';
import '../controllers/ambulance_provider_registration_controller.dart';

class AmbulanceProviderRegistrationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AmbulanceProviderRegistrationController>(
      () => AmbulanceProviderRegistrationController(),
    );
  }
}
