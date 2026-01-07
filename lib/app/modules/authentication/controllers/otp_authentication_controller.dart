// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../utils/helper.dart';
import '../../../routes/app_pages.dart';
import '../../../../constants/app_constants.dart';
import '../controllers/register_controller.dart';

class OtpAuthenticationController extends GetxController {
  RxBool enableBtn = false.obs;
  RxBool isLoading = false.obs;
  RxString otpCode = ''.obs;
  RxString mobileNo = ''.obs;

  @override
  void onInit() {
    super.onInit();
    setMobileNo();
  }

  void setMobileNo() {
    final args = Get.arguments;
    if (args != null && args.length > 1) {
      mobileNo.value = args[1];
    } else {
      final registerController = Get.find<RegisterController>();
      mobileNo.value = registerController.phoneNumberController.text;
    }
    update(['verify-otp-btn']);
  }

  void checkOtp(String data) {
    if (data.isEmpty) {
      otpCode.value = '';
    } else {
      otpCode.value = data;
    }
    enableBtn.value = otpCode.value.length == 4;
    update(['verify-otp-btn']);
  }

  Future<void> verifyOTP() async {
    try {
      isLoading.value = true;
      update(['verify-otp-btn']);

      final response = await http.post(
        Uri.parse('${AppConstants.endpoint}/auth/otp/mobile/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobileNo': mobileNo.value,
          'otp': otpCode.value,
        }),
      );

      print('${AppConstants.endpoint}/auth/otp/mobile/verify');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final args = Get.arguments;
        final redirect = args != null ? args[0] : '';
        final responseBody = jsonDecode(response.body);

        final String token = responseBody['token'] ?? '';
        final Map<String, dynamic> user = responseBody['user'] ?? {};
        final Map<String, dynamic>? profileId = responseBody['profile_id'];

        // Save token & user details
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
        await saveStr('profileId', profileId?['provider_id']?.toString() ?? '');
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
            await saveStr('userType', 'Driver');
            await saveStr(
                'profileId', profileId?['amb_driver_id']?.toString() ?? '');
            break;
          case 1:
            route = Routes.ADMIN;
            await saveStr('userType', 'Admin');
            break;
          default:
            route = Routes.LOGIN;
        }

        // Redirect logic
        if (redirect == 'register') {
          Get.toNamed(Routes.SUCCESS_MSG, arguments: [
            'Registered Successfully!',
            'Congratulations! Your account has been successfully created.'
          ]);
        } else if (redirect == 'forget') {
          Get.toNamed(Routes.SUCCESS_MSG, arguments: [
            'Password Reset Successfully!',
            'Your password has been reset successfully.'
          ]);
        } else {
          customToast('Login Successful', Colors.green);
          Get.offAllNamed(route);
        }
      } else {
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody['error'] is List
            ? (responseBody['error'] as List).join(', ')
            : responseBody['message'] ?? 'OTP verification failed';
        customToast(errorMessage);
      }
    } catch (e) {
      print('Error during OTP verification: $e');
      customToast('An error occurred during OTP verification');
    } finally {
      isLoading.value = false;
      update(['verify-otp-btn']);
    }
  }

  Future<void> resendOtp() async {
    try {
      isLoading.value = true;
      update(['verify-otp-btn']);

      // Send POST request to resend OTP
      final response = await http.post(
        Uri.parse('${AppConstants.endpoint}/auth/otp/mobile/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNo': mobileNo.value,
        }),
      );

      print('${AppConstants.endpoint}/auth/otp/mobile/send');
      print('Resend OTP Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        customToast('OTP resent to mobile number', Colors.green);
      } else {
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody['error'] is List
            ? (responseBody['error'] as List).join(', ')
            : responseBody['message'] ?? 'Failed to resend OTP';
        customToast(errorMessage);
      }
    } catch (e) {
      print('Error during OTP resend: $e');
      customToast('An error occurred while resending OTP');
    } finally {
      isLoading.value = false;
      update(['verify-otp-btn']);
    }
  }
}
