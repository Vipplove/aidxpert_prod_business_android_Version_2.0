import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../constants/app_constants.dart';
import '../../../../utils/fade_animation.dart';
import '../controllers/register_controller.dart';

class SelectRegisterType extends GetView {
  const SelectRegisterType({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          const Spacer(),
          FadeAnimation(
            0.6,
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppConstants.appPrimaryColor,
                ),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Card(
                elevation: 0,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                  leading: Image.asset(
                    'assets/image/patient.png',
                    width: 80,
                    height: 80,
                  ),
                  title: const Text(
                    'Register as a Patient',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    Get.put(RegisterController()).registerType('patient');
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeAnimation(
            0.8,
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppConstants.appPrimaryColor,
                ),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Card(
                elevation: 0,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                  leading: Image.asset(
                    'assets/image/doctor.png',
                    width: 80,
                    height: 80,
                  ),
                  title: const Text(
                    'Register as a Doctor',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    Get.put(RegisterController()).registerType('doctor');
                  },
                ),
              ),
            ),
          ),
          const Spacer()
        ],
      ),
    );
  }
}
