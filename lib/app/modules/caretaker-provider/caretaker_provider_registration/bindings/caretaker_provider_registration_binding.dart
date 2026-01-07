import 'package:get/get.dart';
import '../controllers/caretaker_provider_registration_controller.dart';

class CaretakerProviderRegistrationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CaretakerProviderRegistrationController>(
      () => CaretakerProviderRegistrationController(),
    );
  }
}
