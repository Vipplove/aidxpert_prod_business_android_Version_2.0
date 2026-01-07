import 'package:get/get.dart';
import '../controllers/location_controller.dart';
import '../controllers/shared_component_controller.dart';

class SharedComponentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SharedComponentController>(
      () => SharedComponentController(),
    );
    Get.lazyPut<LocationController>(
      () => LocationController(),
    );
  }
}
