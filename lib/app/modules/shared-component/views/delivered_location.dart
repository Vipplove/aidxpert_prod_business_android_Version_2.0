import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../constants/app_constants.dart';
import '../controllers/location_controller.dart';

class DeliveredLocationView extends GetView {
  final Function(Map<String, String>) onLocationSelected;

  const DeliveredLocationView({Key? key, required this.onLocationSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(23.0, -2.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Transform.translate(
          offset: const Offset(-8.0, 0.0),
          child: Icon(
            Icons.location_on,
            size: 25.0,
            color: AppConstants.appPrimaryColor,
          ),
        ),
        Transform.translate(
          offset: const Offset(-8.0, 0.0),
          child: GetBuilder<LocationController>(
            id: 'address-field',
            init: LocationController(),
            builder: (ctrl) {
              return SizedBox(
                width: 300,
                child: InkWell(
                  onTap: () async {
                    // Navigate to location-detect and wait for result
                    final result = await Get.toNamed('location-detect');
                    if (result != null) {
                      onLocationSelected(result);
                    }
                  },
                  child: Text(
                    ctrl.address.value.isEmpty ? 'Pune' : ctrl.address.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
