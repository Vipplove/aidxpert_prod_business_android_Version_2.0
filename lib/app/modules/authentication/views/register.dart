// ignore_for_file: non_constant_identifier_names, avoid_print, unused_import, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../constants/app_constants.dart';
import '../../../../utils/client_side_validation.dart';
import '../../../../utils/fade_animation.dart';
import '../../../../utils/helper.dart';
import '../../../data/static_data.dart';
import '../../../routes/app_pages.dart';
import '../../shared-component/views/constant_widget.dart';
import '../components/select_register_type.dart';
import '../controllers/register_controller.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterView extends GetView<RegisterController> {
  RegisterView({Key? key}) : super(key: key);
  final GlobalKey<FormState> RegisterFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppConstants.appScaffoldBgColor,
        body: GetBuilder<RegisterController>(
          id: 'register-form',
          init: RegisterController(),
          builder: (ctrl) {
            return SingleChildScrollView(
              child: Container(
                height: context.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppConstants.appPrimaryColor.withOpacity(0.1),
                      AppConstants.appScaffoldBgColor,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    enrollAppHeader,
                    Padding(
                      padding: const EdgeInsets.only(top: 110),
                      child: Form(
                        key: RegisterFormKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onChanged: () {
                          if (RegisterFormKey.currentState?.validate() ==
                              true) {
                            ctrl.formUpdate(true);
                          } else {
                            ctrl.formUpdate(false);
                          }
                        },
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FadeAnimation(
                                0.4,
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Text(
                                    'Create Account',
                                    style: TextStyle(
                                      color: AppConstants.appPrimaryColor,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              FadeAnimation(
                                0.6,
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 12, 24, 0),
                                  child: Text(
                                    'Join us by filling in your details below',
                                    style: TextStyle(
                                      color: AppConstants.appPg1Color,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              FadeAnimation(
                                0.7,
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 12, 24, 0),
                                  child: Obx(() =>
                                      DropdownButtonFormField<String>(
                                        value: controller
                                                .selectedRoleId.value.isEmpty
                                            ? null
                                            : controller.selectedRoleId.value,
                                        decoration: InputDecoration(
                                          labelText: "Select Role",
                                          prefixIcon: Icon(
                                              Icons.local_hospital_outlined,
                                              color:
                                                  AppConstants.appPrimaryColor),
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide.none),
                                          enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: Colors.grey.shade300)),
                                          focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: AppConstants
                                                      .appPrimaryColor,
                                                  width: 2)),
                                        ),
                                        hint: const Text("Choose your role"),
                                        validator: (value) => value == null
                                            ? "Please select a role"
                                            : null,
                                        items: roles.map((role) {
                                          return DropdownMenuItem(
                                            value: role["id"],
                                            child: Text(role["name"]!),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          controller.selectedRoleId.value =
                                              value!;
                                          if (value == "2" &&
                                              controller
                                                  .firstNameController.text
                                                  .trim()
                                                  .isEmpty) {
                                            controller.firstNameController
                                                .text = "Dr. ";
                                          }
                                        },
                                      )),
                                ),
                              ),
                              const SizedBox(height: 8),
                              FadeAnimation(
                                0.8,
                                _buildTextField(
                                  controller: ctrl.firstNameController,
                                  label: ctrl.isDoctor.isTrue
                                      ? 'Doctor Name'
                                      : 'First Name',
                                  hint: ctrl.isDoctor.isTrue
                                      ? 'Dr. John'
                                      : 'John',
                                  icon: Icons.person_2_outlined,
                                  validator: (value) =>
                                      Validators.validName(value, 'First name'),
                                  keyboardType: TextInputType.name,
                                ),
                              ),
                              FadeAnimation(
                                0.9,
                                _buildTextField(
                                  controller: ctrl.lastNameController,
                                  label: 'Last Name',
                                  hint: 'Doe',
                                  icon: Icons.person_2_outlined,
                                  validator: (value) =>
                                      Validators.validName(value, 'Last Name'),
                                  keyboardType: TextInputType.name,
                                ),
                              ),
                              FadeAnimation(
                                1.0,
                                _buildTextField(
                                  controller: ctrl.emailController,
                                  label: 'Email ID',
                                  hint: 'johndoe@gmail.com',
                                  icon: Icons.email_outlined,
                                  validator: Validators.validEmail,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ),
                              FadeAnimation(
                                1.1,
                                _buildTextField(
                                  controller: ctrl.phoneNumberController,
                                  label: 'Phone Number',
                                  hint: '9999999999',
                                  icon: Icons.phone_android_outlined,
                                  validator: Validators.validMobileno,
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                              FadeAnimation(
                                1.2,
                                _buildTextField(
                                  controller: ctrl.passwordController,
                                  label: 'Password',
                                  hint: '********',
                                  icon: Icons.lock,
                                  validator: Validators.validPassword,
                                  obscureText: true,
                                  keyboardType: TextInputType.text,
                                ),
                              ),
                              FadeAnimation(
                                1.3,
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 12, 24, 0),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: ctrl.isTermsChecked.value,
                                        onChanged: (value) {
                                          ctrl.acceptTerms(value);
                                        },
                                      ),
                                      SizedBox(
                                        width: Get.width * 0.7,
                                        child: Text.rich(
                                          TextSpan(
                                            text: 'I agree to the ',
                                            style: const TextStyle(
                                              fontSize: 17,
                                            ),
                                            children: [
                                              WidgetSpan(
                                                child: InkWell(
                                                  onTap: () {
                                                    Get.toNamed(
                                                        Routes.TERMSCONDITION);
                                                  },
                                                  child: const Text(
                                                    'Terms and conditions',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      decoration: TextDecoration
                                                          .underline,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const TextSpan(
                                                text: ' and ',
                                                style: TextStyle(fontSize: 17),
                                              ),
                                              WidgetSpan(
                                                child: InkWell(
                                                  onTap: () {
                                                    Get.toNamed(Routes
                                                        .PRIVACYCONDITION);
                                                  },
                                                  child: const Text(
                                                    'Privacy and policy',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      decoration: TextDecoration
                                                          .underline,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              FadeAnimation(
                                1.3,
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                  child: ElevatedButton(
                                    onPressed: ctrl.enableBtn.isTrue
                                        ? () {
                                            FocusScope.of(context)
                                                .requestFocus(FocusNode());
                                            ctrl.registerNow();
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppConstants.appPrimaryColor,
                                      minimumSize:
                                          const Size(double.infinity, 56),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: ctrl.isLoading.isTrue
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'Register',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              FadeAnimation(
                                1.5,
                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Already have an account? ',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppConstants.appPrimaryColor,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Get.back(),
                                        child: const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    required TextInputType keyboardType,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppConstants.appPrimaryColor),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppConstants.appPrimaryColor),
          ),
        ),
      ),
    );
  }
}
