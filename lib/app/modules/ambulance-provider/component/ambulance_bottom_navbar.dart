// ignore_for_file: prefer_typing_uninitialized_variables
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';

class AmbulanceProviderBottomNavBar extends StatelessWidget {
  final index;

  const AmbulanceProviderBottomNavBar({
    super.key,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: index,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      showUnselectedLabels: true,
      unselectedItemColor: Colors.black,
      onTap: (value) {
        if (value != index) {
          if (value == 0) {
            Get.offAndToNamed(Routes.AMBULANCE_PROVIDER_DASHBOARD);
          } else if (value == 1) {
            Get.offAndToNamed(Routes.AMBULANCE_BOOKING_HISTORY);
          } else if (value == 2) {
            Get.offAndToNamed(Routes.AMBULANCE_LIST);
          } else if (value == 3) {
            Get.offAndToNamed(Routes.AMBULANCE_DRIVER);
          } else if (value == 4) {
            Get.offAndToNamed(Routes.AMBULANCE_ACCOUNT);
          }
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(
            icon: Icon(Icons.local_hospital_outlined), label: 'Ambulance'),
        BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined), label: 'Drivers'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}
