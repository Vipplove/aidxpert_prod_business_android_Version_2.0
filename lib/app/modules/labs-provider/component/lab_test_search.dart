import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../constants/app_constants.dart';
import '../labs_provider_dashboard/controllers/labs_provider_dashboard_controller.dart';

labTestSearch(
  BuildContext context,
  testList,
  subtotal,
  payAmt,
  testData,
  LabsProviderDashboardController ctrl,
) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(10),
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            // <-- Wrap Column with this
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search Bar
                Card(
                  elevation: 2,
                  child: TextField(
                    autofocus: false,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      hintText: 'Search test...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      ctrl.getLabTestList(value);
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // List of Tests
                SizedBox(
                  height: 300, // Reduce height to prevent overflow
                  child: Obx(() => ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                        itemCount: ctrl.labTestList.length,
                        itemBuilder: (context, index) {
                          var data = ctrl.labTestList[index];
                          double oldPrice = data['old_price'].toDouble();
                          double newPrice = data['new_price'].toDouble();
                          double discount =
                              ((oldPrice - newPrice) / oldPrice) * 100;

                          return Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['test_name'],
                                          style: const TextStyle(
                                            fontSize: 15,
                                          ),
                                          maxLines: 5,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              '₹${oldPrice.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.red,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '₹${newPrice.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '(${discount.toStringAsFixed(0)}% OFF)',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 26,
                                      color: Colors.green,
                                    ),
                                    tooltip: 'Add',
                                    onPressed: () {
                                      testList.add(data);
                                      calculate(testList, subtotal, payAmt,
                                          testData, ctrl);
                                      ctrl.updateSearchTest();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Close',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    },
  );
}

Card prescriptionCard(BuildContext context, data) {
  return Card(
    elevation: 2,
    child: GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: InteractiveViewer(
                            panEnabled: true, // Enable drag to move
                            boundaryMargin: const EdgeInsets.all(20),
                            minScale: 1.0,
                            maxScale: 4.0,
                            child: Image.network(
                              '${AppConstants}/prescriptions/' +
                                  data['upload_prescription'],
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Text('Failed to load image'),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: const ListTile(
        leading: Icon(
          Icons.file_present_outlined,
          size: 30,
        ),
        title: Text(
          'Upload Prescription',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Click here to see the prescription',
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    ),
  );
}

removeTest(
  test,
  testList,
  subtotal,
  payAmt,
  data,
  LabsProviderDashboardController ctrl,
) {
  testList.remove(test);

  subtotal.value = testList.fold(
    0.0,
    (sum, test) => sum + (test['new_price'] ?? 0.0),
  );

  double servicePlatformCharge =
      double.tryParse(data['service_platform_charges'].toString()) ?? 0.0;
  double testPickupCharge =
      double.tryParse(data['test_pickup_charge'].toString()) ?? 0.0;
  double serviceChargeAmt = (subtotal.value * servicePlatformCharge) / 100;
  payAmt.value = subtotal.value + serviceChargeAmt + testPickupCharge;
  payAmt.value = subtotal.value == 0.0 ? 0.0 : payAmt.value;
  ctrl.update(['lab-test-details']);
}

calculate(testList, subtotal, payAmt, data, ctrl) {
  subtotal.value = testList.fold(
    0.0,
    (sum, test) => sum + (double.tryParse(test['new_price'].toString()) ?? 0.0),
  );
  double servicePlatformCharge =
      double.tryParse(data['service_platform_charges'].toString()) ?? 0.0;
  double testPickupCharge =
      double.tryParse(data['test_pickup_charge'].toString()) ?? 0.0;
  double serviceChargeAmt = (subtotal.value * servicePlatformCharge) / 100;
  payAmt.value = subtotal.value + serviceChargeAmt + testPickupCharge;
  ctrl.update(['lab-test-details']);
}
