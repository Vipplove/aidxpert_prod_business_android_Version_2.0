// ignore_for_file: unnecessary_overrides, avoid_print
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../constants/app_constants.dart';
import '../../../../utils/helper.dart';
import '../../../routes/app_pages.dart';

class RegisterController extends GetxController {
  RxBool enableBtn = false.obs;
  RxBool isLoading = false.obs;
  RxBool selectRegisterType = true.obs;
  RxBool isDoctor = false.obs;
  RxBool isTermsChecked = false.obs;

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  var selectedRoleId = "".obs;

  registerType(data) async {
    selectRegisterType.value = false;
    await saveStr('register_type', data);
    data == 'doctor' ? isDoctor(true) : isDoctor(false);
    update(['register-form']);
  }

  formUpdate(val) {
    enableBtn.value = val;
    update(['register-form']);
  }

  Future<void> registerNow() async {
    try {
      isLoading(true);
      update(['register-form']);

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.endpoint}/users'),
      );

      // Add form fields
      request.fields['first_name'] = firstNameController.text.trim();
      request.fields['last_name'] = lastNameController.text.trim();
      request.fields['email'] = emailController.text.trim();
      request.fields['phone_number'] = phoneNumberController.text.trim();
      request.fields['password'] = passwordController.text.trim();
      request.fields['role_id'] = selectedRoleId.value;

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        customToast('OTP sent to mobile number / Email ID.');
        Get.toNamed(Routes.OTP_AUTHENTICATION, arguments: ['register']);
      } else {
        final error =
            jsonDecode(responseBody)['message'] ?? 'Registration failed';
        customToast(error);
      }
    } catch (e) {
      print('Register Error: $e');
      customToast('An error occurred during registration');
    } finally {
      isLoading(false);
      update(['register-form']);
    }
  }

  signInData(data) {
    firstNameController.text = data?.displayName?.split(' ').first ?? '';
    lastNameController.text = data?.displayName?.split(' ').last ?? '';
    emailController.text = data?.email ?? '';
    update(['register-form']);
  }

  acceptTerms(data) {
    if (!isClosed) {
      isTermsChecked.value = data;
      update(['register-form']);
    }
  }

  @override
  void onClose() {
    super.onClose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    passwordController.dispose();
  }
}
