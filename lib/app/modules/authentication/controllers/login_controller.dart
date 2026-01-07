// ignore_for_file: unnecessary_overrides, avoid_print
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../utils/helper.dart';
import '../../../routes/app_pages.dart';
import '../../../../constants/app_constants.dart';
import '../../../../utils/client_side_validation.dart';

class LoginController extends GetxController {
  RxBool isRememberMe = false.obs;
  RxBool enableBtn = false.obs;
  RxBool isLoading = false.obs;
  RxBool isOtpLogin = false.obs;

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController emailOrMobileController = TextEditingController();

  final RxString selectedLabRole = 'Lab Provider'.obs;
  final RxString selectedDiagnosticRole = 'Diagnostic Provider'.obs;
  final RxString selectedAmbRole = "Ambulance Provider".obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await saveStr('loginType', Get.arguments ?? 'normal');
    print(await readStr('loginType'));
  }

  void checkOtpLogin(bool? val) {
    isOtpLogin.value = val ?? false;
    passwordController.clear();
    enableBtn.value = val ?? false;
    update(['login-form']);
  }

  void formUpdate(bool val) {
    enableBtn.value = val;
    update(['login-form', 'forget-form']);
  }

  bool _isEmail(String input) {
    return Validators.validEmail(input) == null && input.contains('@');
  }

  bool _isPhoneNumber(String input) {
    return Validators.validMobileno(input) == null;
  }

  Future<void> loginNow() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || (password.isEmpty && !isOtpLogin.value)) {
      customToast('Please enter username and password', Colors.red);
      return;
    }

    isLoading.value = true;
    update(['login-form']);

    try {
      String? endpoint;
      Map<String, String> body = {};

      if (isOtpLogin.value) {
        if (!_isPhoneNumber(username)) {
          customToast(
              'Please enter a valid phone number for OTP login', Colors.red);
          isLoading.value = false;
          update(['login-form']);
          return;
        }
        endpoint = '${AppConstants.endpoint}/auth/otp/mobile/send';
        body['phoneNo'] = username;
      } else {
        if (_isEmail(username)) {
          endpoint = '${AppConstants.endpoint}/auth/email';
          body['email'] = username;
          body['password'] = password;
        } else if (_isPhoneNumber(username)) {
          endpoint = '${AppConstants.endpoint}/auth/phone';
          body['phoneNo'] = username;
          body['password'] = password;
        } else {
          customToast('Please enter a valid email or phone number', Colors.red);
          isLoading.value = false;
          update(['login-form']);
          return;
        }
      }

      print('Calling API: $endpoint with body: $body');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('API Response: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (isOtpLogin.value) {
          // OTP login flow
          customToast('OTP sent to mobile number.', Colors.green);
          Get.toNamed(Routes.OTP_AUTHENTICATION,
              arguments: ['OTP', usernameController.text.trim()]);
        } else {
          // Decode response
          final responseBody = jsonDecode(response.body);

          final String token = responseBody['token'] ?? '';
          final Map<String, dynamic> user = responseBody['user'] ?? {};
          final Map<String, dynamic>? profileId = responseBody['profile_id'];

          // Save all user/session details
          await saveStr('token', token);
          await saveStr('user_id', user['user_id']?.toString() ?? '');
          await saveStr('user_name', user['user_name'] ?? '');
          await saveStr('email', user['email'] ?? '');
          await saveStr('first_name', user['first_name'] ?? '');
          await saveStr('last_name', user['last_name'] ?? '');
          await saveStr('phone_number', user['phone_number'] ?? '');
          await saveStr('gender', user['gender'] ?? '');
          await saveStr('birthday', user['birthday'] ?? '');
          await saveStr('biography', user['biography'] ?? '');
          await saveStr('address', user['address'] ?? '');
          await saveStr('city', user['city'] ?? '');
          await saveStr('state', user['state'] ?? '');
          await saveStr('country', user['country'] ?? '');
          await saveStr('profile_image_name', user['profile_image_name'] ?? '');
          await saveStr('postal_code', user['postal_code'] ?? '');
          await saveStr('role_id', user['role_id']?.toString() ?? '');
          await saveStr('fcm_token', user['fcm_token']?.toString() ?? '');
          await saveStr('platform', user['platform']?.toString() ?? '');
          await saveStr('latitude', user['latitude']?.toString() ?? '');
          await saveStr('longitude', user['longitude']?.toString() ?? '');
          await saveStr('isActive', user['is_active']?.toString() ?? '');
          await saveStr('isVerified', user['isVerified']?.toString() ?? '');
          await saveStr(
              'profileId', profileId?['provider_id']?.toString() ?? '');
          await saveStr('roleType', user['role']?['role_type'] ?? 'User');
          await saveStr('isFirstTime', 'false');

          // Determine dashboard route based on role_id
          final int roleId = user['role_id'] ?? 0;
          String route;

          switch (roleId) {
            case 4:
              route = Routes.AMBULANCE_PROVIDER_DASHBOARD;
              await saveStr('userType', 'Ambulance');
              break;
            case 5:
              route = Routes.LABS_PROVIDER_DASHBOARD;
              await saveStr('userType', 'Labs');
              break;
            case 7:
              route = Routes.DIAGNOSTIC_PROVIDER_DASHBOARD;
              await saveStr('userType', 'Diagnostic');
              break;
            case 9:
              route = Routes.CARETAKER_PROVIDER_DASHBOARD;
              await saveStr('userType', 'Caretaker');
              break;
            case 6:
              route = Routes.PATHOLOGIST_DASHBOARD;
              await saveStr('userType', 'Pathologist');
              break;
            case 8:
              route = Routes.RADIOLOGIST_DASHBOARD;
              await saveStr('userType', 'Radiologist');
              break;
            case 21:
              route = Routes.RADIOLOGIST_DASHBOARD;
              await saveStr('userType', 'Support');
              break;
            case 22:
              route = Routes.SALES_DASHBOARD;
              await saveStr('userType', 'Sales');
              break;
            case 23:
              route = Routes.DRIVER_DASHBOARD;
              await saveStr(
                  'profileId', profileId?['amb_driver_id']?.toString() ?? '');
              await saveStr('userType', 'Driver');
              break;
            case 1:
              route = Routes.ADMIN;
              await saveStr('userType', 'Admin');
              break;
            default:
              route = Routes.LOGIN;
          }

          // Success toast + navigation
          customToast('Login Successful', Colors.green);
          usernameController.clear();
          passwordController.clear();
          Get.offAllNamed(route);
        }
      } else {
        // Error handling
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody['error'] is List
            ? (responseBody['error'] as List).join(', ')
            : responseBody['message'] ?? 'Login failed';
        customToast(errorMessage, Colors.red);
      }
    } catch (e) {
      print('Error during login: $e');
      customToast('An error occurred during login: $e', Colors.red);
    } finally {
      isLoading.value = false;
      update(['login-form']);
    }
  }

  Future<void> resetPassword() async {
    final username = emailOrMobileController.text.trim();

    if (username.isEmpty) {
      customToast('Please enter email or phone number', Colors.red);
      return;
    }

    isLoading.value = true;
    update(['forget-form']);

    try {
      String endpoint;
      Map<String, String> body = {};

      if (_isEmail(username)) {
        endpoint = '${AppConstants.endpoint}/user/reset-password/email';
        body['email'] = username;
      } else if (_isPhoneNumber(username)) {
        endpoint = '${AppConstants.endpoint}/user/reset-password/phone';
        body['phoneNo'] = username;
      } else {
        customToast('Please enter a valid email or phone number', Colors.red);
        isLoading.value = false;
        update(['forget-form']);
        return;
      }

      print('Reset Password API: $endpoint, Response body: $body');

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      print(
          'Reset Password API Response: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        customToast('Password reset link/OTP sent to $username', Colors.green);
        if (_isPhoneNumber(username)) {
          Get.toNamed(Routes.OTP_AUTHENTICATION,
              arguments: ['forget', username]);
        } else {
          Get.back();
        }
      } else {
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody['error'] is List
            ? (responseBody['error'] as List).join(', ')
            : responseBody['message'] ?? 'Password reset failed';
        customToast(errorMessage, Colors.red);
      }
    } catch (e) {
      print('Error during password reset: $e');
      customToast('An error occurred during password reset: $e', Colors.red);
    } finally {
      isLoading.value = false;
      update(['forget-form']);
    }
  }

  @override
  void onClose() {
    super.onClose();
    usernameController.dispose();
    passwordController.dispose();
    emailOrMobileController.dispose();
  }
}
