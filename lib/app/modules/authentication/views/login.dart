// ignore_for_file: must_be_immutable, non_constant_identifier_names, avoid_print, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../constants/app_constants.dart';
import '../../../../utils/client_side_validation.dart';
import '../../../../utils/fade_animation.dart';
import '../../../../utils/helper.dart';
import '../../../routes/app_pages.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  LoginView({Key? key}) : super(key: key);

  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    var loginFor = Get.arguments;

    print("LoginView Arguments: $loginFor");

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppConstants.appScaffoldBgColor,
        body: SingleChildScrollView(
          child: SizedBox(
            height: context.height,
            child: Stack(
              children: [
                // Background Image & Logo
                Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/image/bg-image.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -30,
                      left: 10,
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          Image.asset(
                            'assets/logo/logo.png',
                            height: 150,
                            width: 150,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Foreground Content
                Container(
                  margin: const EdgeInsets.only(top: 150),
                  child: GetBuilder<LoginController>(
                    id: 'login-form',
                    init: controller,
                    initState: (state) {
                      if (loginFor == 'Labs') {
                        controller.selectedLabRole.value = "Lab Provider";
                      } else if (loginFor == 'Diagnostic') {
                        controller.selectedLabRole.value =
                            "Diagnostic Provider";
                      }
                    },
                    builder: (ctrl) {
                      return Form(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        key: loginFormKey,
                        onChanged: () {
                          ctrl.formUpdate(
                              loginFormKey.currentState?.validate() == true);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SHOW ROLE BUTTONS ONLY IF LOGIN FOR LABS
                            if (loginFor == 'Labs') ...[
                              FadeAnimation(
                                0.6,
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 6),
                                    child: Obx(
                                      () => Row(
                                        children: [
                                          // Lab Provider Button
                                          Expanded(
                                            child: _roleButton(
                                              title: "Lab Provider",
                                              isActive: controller
                                                      .selectedLabRole.value ==
                                                  "Lab Provider",
                                              onTap: () {
                                                controller.selectedLabRole
                                                    .value = "Lab Provider";
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Pathologist Button
                                          Expanded(
                                            child: _roleButton(
                                              title: "Pathologist",
                                              isActive: controller
                                                      .selectedLabRole.value ==
                                                  "Pathologist",
                                              onTap: () {
                                                controller.selectedLabRole
                                                    .value = "Pathologist";
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],

                            if (loginFor == 'Diagnostic') ...[
                              FadeAnimation(
                                0.6,
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 6),
                                    child: Obx(
                                      () => Row(
                                        children: [
                                          // Diagnostic Provider Button
                                          Expanded(
                                            child: _roleButton(
                                              title: "Diagnostic Provider",
                                              isActive: controller
                                                      .selectedLabRole.value ==
                                                  "Diagnostic Provider",
                                              onTap: () {
                                                controller
                                                        .selectedLabRole.value =
                                                    "Diagnostic Provider";
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Radiologist Button
                                          Expanded(
                                            child: _roleButton(
                                              title: "Radiologist",
                                              isActive: controller
                                                      .selectedLabRole.value ==
                                                  "Radiologist",
                                              onTap: () {
                                                controller.selectedLabRole
                                                    .value = "Radiologist";
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],

                            if (loginFor == 'Ambulance') ...[
                              FadeAnimation(
                                0.6,
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 6),
                                    child: Obx(
                                      () => Row(
                                        children: [
                                          // Ambulance Provider Button
                                          Expanded(
                                            child: _roleButton(
                                              title: "Ambulance Provider",
                                              isActive: controller
                                                      .selectedAmbRole.value ==
                                                  "Ambulance Provider",
                                              onTap: () {
                                                controller
                                                        .selectedAmbRole.value =
                                                    "Ambulance Provider";
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Driver Login Button
                                          Expanded(
                                            child: _roleButton(
                                              title: "Driver Login",
                                              isActive: controller
                                                      .selectedAmbRole.value ==
                                                  "Driver Login",
                                              onTap: () {
                                                controller.selectedAmbRole
                                                    .value = "Driver Login";
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],

                            // Welcome Text
                            FadeAnimation(
                              0.8,
                              Container(
                                padding: const EdgeInsets.only(left: 20),
                                child: Text(
                                  'Welcome',
                                  style: TextStyle(
                                    color: AppConstants.appPrimaryColor,
                                    fontSize: 32.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            // Subtitle
                            // Subtitle
                            FadeAnimation(
                              1.0,
                              Container(
                                padding:
                                    const EdgeInsets.fromLTRB(21, 10, 20, 0),
                                child: Text(
                                  'To create your account, please enter the required information.',
                                  style: TextStyle(
                                    color: AppConstants.appPg1Color,
                                    fontSize: 17.0,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),

                            // Email/Mobile Field
                            FadeAnimation(
                              1.2,
                              Container(
                                padding:
                                    const EdgeInsets.fromLTRB(21, 25, 20, 20),
                                child: TextFormField(
                                  style: const TextStyle(fontSize: 18.0),
                                  keyboardType: TextInputType.name,
                                  controller: ctrl.usernameController,
                                  validator: (v) =>
                                      Validators.validEmailMobile(v!),
                                  decoration: inputFieldDecoration(
                                    'Email ID or Mobile no',
                                    'johndoe@gmail.com / 8888888888',
                                    Icon(
                                      Icons.person_2_outlined,
                                      color: AppConstants.appPrimaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Password Field
                            FadeAnimation(
                              1.3,
                              Container(
                                padding:
                                    const EdgeInsets.fromLTRB(21, 0, 20, 15),
                                child: TextFormField(
                                  enabled: !ctrl.isOtpLogin.value,
                                  style: const TextStyle(fontSize: 18.0),
                                  keyboardType: TextInputType.text,
                                  obscureText: true,
                                  controller: ctrl.passwordController,
                                  validator: (v) => !ctrl.isOtpLogin.value
                                      ? Validators.validPassword(v!)
                                      : null,
                                  decoration: inputFieldDecoration(
                                    'Password',
                                    '********',
                                    Icon(
                                      Icons.lock,
                                      color: AppConstants.appPrimaryColor,
                                    ),
                                    ctrl.isOtpLogin.value,
                                  ),
                                ),
                              ),
                            ),

                            // OTP Checkbox + Forgot Password
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                FadeAnimation(
                                  1.5,
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0),
                                    child: Row(
                                      children: [
                                        Obx(() => Checkbox(
                                              value: ctrl.isOtpLogin.value,
                                              onChanged: ctrl.checkOtpLogin,
                                            )),
                                        const Text(
                                          'Login with OTP',
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                FadeAnimation(
                                  1.4,
                                  TextButton(
                                    onPressed: () {
                                      Get.toNamed(Routes.FORGET_PASSWORD);
                                    },
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Login Button
                            FadeAnimation(
                              1.6,
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 5, 10, 0),
                                child: Container(
                                  height: 75,
                                  padding: const EdgeInsets.all(10),
                                  child: ElevatedButton(
                                    onPressed: ctrl.enableBtn.isTrue
                                        ? () {
                                            FocusScope.of(context)
                                                .requestFocus(FocusNode());
                                            ctrl.loginNow();
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.all(16.0),
                                      foregroundColor: Colors.white,
                                      backgroundColor:
                                          AppConstants.appPrimaryColor,
                                      shadowColor: Colors.redAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      minimumSize: const Size(400, 50),
                                    ),
                                    child: ctrl.isLoading.isFalse
                                        ? const Text(
                                            'Login',
                                            style: TextStyle(fontSize: 20),
                                          )
                                        : const SizedBox(
                                            height: 30,
                                            width: 25,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),

                            FadeAnimation(
                              1.6,
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account?",
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: AppConstants.appPrimaryColor,
                                      ),
                                    ),
                                    TextButton(
                                      child: const Text(
                                        'Sign Up!',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.black,
                                        ),
                                      ),
                                      onPressed: () =>
                                          Get.toNamed(Routes.REGISTER),
                                    )
                                  ],
                                ),
                              ),
                            ),

                            FadeAnimation(
                              1.7,
                              Container(
                                padding:
                                    const EdgeInsets.fromLTRB(25, 3, 25, 0),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                        child: Divider(color: Colors.grey)),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 10),
                                      child: Text('or',
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.grey)),
                                    ),
                                    Expanded(
                                        child: Divider(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),

                            FadeAnimation(
                              1.8,
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Center(
                                  child: ElevatedButton(
                                    onPressed: () => Get.back(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      minimumSize: const Size(50, 50),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                            'assets/logo/ic_launcher.png',
                                            width: 24,
                                            height: 24),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Back to Main menu',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable Role Button
  Widget _roleButton({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppConstants.appPrimaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isActive ? AppConstants.appPrimaryColor : Colors.grey),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppConstants.appPrimaryColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
