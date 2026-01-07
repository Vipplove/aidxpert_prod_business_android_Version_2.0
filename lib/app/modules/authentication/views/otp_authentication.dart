// otp_authentication.dart
import 'package:aidxpert_business/utils/helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_verification_code/flutter_verification_code.dart';
import '../../../../constants/app_constants.dart';
import '../../../../utils/fade_animation.dart';
import '../controllers/otp_authentication_controller.dart';

class OtpAuthenticationView extends GetView<OtpAuthenticationController> {
  const OtpAuthenticationView({super.key});

  // Mask mobile number: XXXXXXXX1234
  String maskMobileNumber(String mobileNo) {
    if (mobileNo.length < 4) return mobileNo;
    return 'X' * (mobileNo.length - 4) +
        mobileNo.substring(mobileNo.length - 4);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.setMobileNo();
    });

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppConstants.appScaffoldBgColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppConstants.appScaffoldBgColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Get.back(),
          ),
          title: const Text(''),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 100),
    
              /// Title
              FadeAnimation(
                0.4,
                Text(
                  'OTP Authentication',
                  style: TextStyle(
                    color: AppConstants.appPrimaryColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
    
              const SizedBox(height: 16),
    
              /// Subtitle (FadeAnimation OUTSIDE Obx)
              FadeAnimation(
                0.6,
                Obx(() => Text(
                      'An authentication code has been sent to your mobile number ${maskMobileNumber(controller.mobileNo.value)}',
                      style: TextStyle(
                        fontSize: 17,
                        color: AppConstants.appPg1Color,
                      ),
                    )),
              ),
    
              const SizedBox(height: 40),
    
              /// OTP Input Field
              FadeAnimation(
                0.8,
                Center(
                  child: VerificationCode(
                    textStyle: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                    keyboardType: TextInputType.number,
                    length: 4,
                    itemSize: 58,
                    underlineColor: AppConstants.appPrimaryColor,
                    underlineUnfocusedColor: Colors.grey,
                    fullBorder: true,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    cursorColor: AppConstants.appPrimaryColor,
                    onCompleted: (value) {
                      controller.otpCode.value = value;
                      controller.enableBtn.value = true;
                    },
                    onEditing: (bool value) {
                      if (!value) {
                        if (controller.otpCode.value.length != 4) {
                          controller.enableBtn.value = false;
                        }
                      }
                      if (controller.otpCode.value.length == 4) {
                        FocusScope.of(context).unfocus();
                      }
                    },
                  ),
                ),
              ),
    
              const SizedBox(height: 30),
    
              /// Resend Code
              FadeAnimation(
                1.0,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Didn't receive the code? ",
                      style: TextStyle(fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () => controller.resendOtp(),
                      child: const Text(
                        'Resend',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    
              const SizedBox(height: 40),
    
              /// VERIFY BUTTON (FadeAnimation OUTSIDE Obx)
              FadeAnimation(
                1.2,
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: controller.enableBtn.value
                          ? () {
                              FocusScope.of(context).unfocus();
                              controller.verifyOTP();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.appPrimaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 28,
                              width: 28,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'Verify OTP',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
              ),
    
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
