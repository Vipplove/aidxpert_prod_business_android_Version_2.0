import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../controllers/otp_authentication_controller.dart';
import '../controllers/register_controller.dart';

class AuthenticationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(
      () => LoginController(),
    );
    Get.lazyPut<RegisterController>(
      () => RegisterController(),
    );
    Get.lazyPut<OtpAuthenticationController>(
      () => OtpAuthenticationController(),
    );
  }
}
