// ignore_for_file: must_be_immutable
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../../../../constants/app_constants.dart';
import '../../../../utils/fade_animation.dart';
import '../../../routes/app_pages.dart';
import '../../shared-component/views/constant_widget.dart';

class SuccessMsgView extends GetView {
  const SuccessMsgView({Key? key}) : super(key: key);

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
                  margin: const EdgeInsets.only(top: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FadeAnimation(
                        0.5,
                        Center(
                          child: Lottie.asset(
                            'assets/image/right.json',
                            fit: BoxFit.fill,
                            height: 350,
                            width: 350,
                          ),
                        ),
                      ),
                      FadeAnimation(
                        0.7,
                        Center(
                          child: Text(
                            Get.arguments[0],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppConstants.appPrimaryColor,
                              fontSize: 28.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      FadeAnimation(
                        0.9,
                        Center(
                          child: Text(
                            Get.arguments[1],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppConstants.appPg1Color,
                              fontSize: 20.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      FadeAnimation(
                        1.2,
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                          child: Container(
                            height: 75,
                            padding: const EdgeInsets.all(10),
                            child: ElevatedButton(
                              onPressed: () {
                                Get.toNamed(Routes.LOGIN);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16.0),
                                foregroundColor: Colors.white,
                                backgroundColor: AppConstants.appPrimaryColor,
                                shadowColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                minimumSize: const Size(400, 50),
                              ),
                              child: const Text(
                                'Get Started',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
