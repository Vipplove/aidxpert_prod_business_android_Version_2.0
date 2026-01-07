import 'package:get/get.dart';
import '../controllers/caretaker_controller.dart';

class CaretakerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CaretakerController>(
      () => CaretakerController(),
    );
  }
}
