import 'package:get/get.dart';
import '../controllers/ambulance_controller.dart';

class AmbulanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AmbulanceController>(
      () => AmbulanceController(),
    );
  }
}
