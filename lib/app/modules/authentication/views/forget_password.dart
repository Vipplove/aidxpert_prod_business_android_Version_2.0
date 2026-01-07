// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../constants/app_constants.dart';
import '../../../../utils/client_side_validation.dart';
import '../../../../utils/fade_animation.dart';
import '../../../../utils/helper.dart';
import '../../shared-component/views/constant_widget.dart';
import '../controllers/login_controller.dart';

class ForgetPasswordView extends GetView {
  ForgetPasswordView({Key? key}) : super(key: key);
  final GlobalKey<FormState> ForgetFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppConstants.appScaffoldBgColor,
        body: SingleChildScrollView(
          child: SizedBox(
            height: context.height - 30,
            child: Stack(
              children: [
                enrollAppHeader,
                Container(
                  margin: const EdgeInsets.only(top: 200),
                  child: GetBuilder<LoginController>(
                    id: 'forget-form',
                    init: LoginController(),
                    builder: (ctrl) {
                      return Form(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        key: ForgetFormKey,
                        onChanged: () {
                          if (ForgetFormKey.currentState?.validate() == true) {
                            ctrl.formUpdate(true);
                          } else {
                            ctrl.formUpdate(false);
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeAnimation(
                              0.4,
                              Container(
                                padding: const EdgeInsets.only(left: 20),
                                child: Text(
                                  'Forgot Password',
                                  style: TextStyle(
                                    color: AppConstants.appPrimaryColor,
                                    fontSize: 32.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            FadeAnimation(
                              0.6,
                              Container(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 12, 20, 0),
                                child: Text(
                                  'Please provide us with the email address or mobile number associated with your AidXpert account, and we will send you an email or OTP with instructions to reset your password.',
                                  style: TextStyle(
                                    color: AppConstants.appPg1Color,
                                    fontSize: 17.0,
                                  ),
                                ),
                              ),
                            ),
                            FadeAnimation(
                              0.8,
                              Container(
                                padding:
                                    const EdgeInsets.fromLTRB(21, 30, 20, 20),
                                child: TextFormField(
                                  style: const TextStyle(fontSize: 18.0),
                                  keyboardType: TextInputType.name,
                                  controller: ctrl.emailOrMobileController,
                                  validator: (v) =>
                                      Validators.validEmailMobile(v!),
                                  decoration: inputFieldDecoration(
                                    'Email ID / Mobile Number',
                                    '',
                                    Icon(
                                      Icons.send_rounded,
                                      color: AppConstants.appPrimaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            FadeAnimation(
                              1.0,
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                child: Container(
                                  height: 75,
                                  padding: const EdgeInsets.all(10),
                                  child: ElevatedButton(
                                    onPressed: ctrl.enableBtn.isTrue
                                        ? () => {
                                              FocusScope.of(context)
                                                  .requestFocus(FocusNode()),
                                              ctrl.resetPassword()
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
                                            'Send now',
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
}
