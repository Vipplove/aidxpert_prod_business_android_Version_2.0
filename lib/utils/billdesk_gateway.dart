// // ignore_for_file: deprecated_member_use
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../../constants/app_constants.dart';
// import '../app/modules/patients/controllers/appointment_controller.dart';
// import '../app/modules/patients/controllers/consult_controller.dart';
// import '../app/modules/patients/controllers/diagnostic_controller.dart';
// import '../app/modules/patients/controllers/doctors_controller.dart';
// import '../app/modules/patients/controllers/labs_controller.dart';
// import 'helper.dart';

// String orderid = '';
// var isLoading = false.obs;
// var redirectScreen = ''.obs;

// // Generate a unique order ID
// String generateOrderId() {
//   String dateTime = DateTime.now()
//       .toUtc()
//       .toIso8601String()
//       .replaceAll(RegExp(r'[-:]'), '')
//       .split('.')[0];
//   return "ORDUBX73${dateTime.substring(0, 15)}";
// }

// // Generate the order time
// String generateTime(DateTime dateTime) {
//   String offsetSign = dateTime.timeZoneOffset.isNegative ? "-" : "+";
//   String offset =
//       "$offsetSign${dateTime.timeZoneOffset.inHours.abs().toString().padLeft(2, '0')}:${(dateTime.timeZoneOffset.inMinutes.remainder(60)).abs().toString().padLeft(2, '0')}";
//   return "${dateTime.toIso8601String().split('.')[0]}$offset";
// }

// // Create an order and launch BillDesk SDK
// billDeskPaymentGateway(amount, type) async {
//   orderid = generateOrderId();
//   redirectScreen.value = type;
//   final orderData = {
//     "mercid": AppConstants.merchantId,
//     "orderid": orderid,
//     "amount": (double.tryParse(amount.toString()) ?? 0.0).ceil().toString(),
//     "order_date": generateTime(DateTime.now()),
//     "currency": "356",
//     "ru": AppConstants.redirectUrl,
//     "additional_info": {
//       "additional_info1": "Test",
//       "additional_info2": "Test1"
//     },
//     "itemcode": "DIRECT",
//     "device": {
//       "init_channel": "internet",
//       "ip": "76.76.21.21",
//       "user_agent": "Mozilla/5.0(WindowsNT10.0;WOW64;rv:51.0)Gecko/20",
//       "accept_header": "text/html",
//       "browser_tz": "-330",
//       "browser_color_depth": "32",
//       "browser_java_enabled": "false",
//       "browser_screen_height": "601",
//       "browser_screen_width": "657",
//       "browser_language": "en-US",
//       "browser_javascript_enabled": "true"
//     }
//   };

//   try {
//     isLoading.value = true;

//     final response = await http.post(
//       Uri.parse(AppConstants.createOrderAPIUrl),
//       headers: {
//         'Content-Type': 'application/json',
//         'Accept': '*/*',
//       },
//       body: jsonEncode(orderData),
//     );

//     if (response.statusCode == 200) {
//       var data = jsonDecode(response.body);
//       String rdata = '';

//       for (var link in data['links']) {
//         if (link['rel'] == 'redirect' && link['parameters'] != null) {
//           if (link['parameters']['rdata'] != null) {
//             rdata = link['parameters']['rdata'];
//           }
//         }
//         if (link['headers'] != null &&
//             link['headers']['authorization'] != null) {}
//       }

//       await handleSubmit(data['bdorderid'], rdata);
//     } else {
//       customToast('Failed to create order. Please try again.');
//     }
//   } catch (e) {
//     customToast('An error occurred while creating the order.');
//   } finally {
//     isLoading.value = false;
//   }
// }

// Future<void> handleSubmit(String bdorderID, String rdata) async {
//   try {
//     final response = await http.post(
//       Uri.parse(AppConstants.billdeskGatewayUrl),
//       headers: {
//         'Content-Type': 'application/x-www-form-urlencoded',
//       },
//       body: {
//         'merchantid': AppConstants.merchantId,
//         'bdorderid': bdorderID,
//         'rdata': rdata,
//       },
//     );

//     if (response.statusCode == 200) {
//       loadHtmlInWebView(response.body);
//     } else {
//       customToast('Failed to complete payment.');
//     }
//   } catch (e) {
//     customToast('An error occurred during payment.');
//   }
// }

// void loadHtmlInWebView(String htmlContent) {
//   Get.dialog(
//     Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         backgroundColor: AppConstants.appPrimaryColor,
//         title: const Text(
//           'Payment',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 20,
//           ),
//         ),
//         centerTitle: true,
//         elevation: 0,
//         shape: const ContinuousRectangleBorder(
//           borderRadius: BorderRadius.only(
//             bottomLeft: Radius.circular(50),
//             bottomRight: Radius.circular(50),
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.close, color: Colors.white),
//             onPressed: () {
//               Get.put(AppointmentController()).updateScreen();
//               Get.put(DoctorsController()).updateScreen();
//               Get.put(ConsultController()).updateScreen();
//               Get.put(LabsController()).updateScreen();
//               Get.put(DiagnosticController()).updateScreen();
//               Get.back();
//             },
//           ),
//         ],
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(6.0),
//           child: LinearProgressIndicator(
//             backgroundColor: Colors.white.withOpacity(0.3),
//             valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
//           ),
//         ),
//       ),
//       body: WebViewWidget(
//         controller: WebViewController()
//           ..setJavaScriptMode(JavaScriptMode.unrestricted)
//           ..loadRequest(
//             Uri.dataFromString(
//               htmlContent,
//               mimeType: 'text/html',
//               encoding: Encoding.getByName('utf-8'),
//             ),
//           )
//           ..setNavigationDelegate(
//             NavigationDelegate(
//               onPageFinished: (String url) async {
//                 if (url == "https://aidxpert.in/response") {
//                   Get.dialog(
//                     const AlertDialog(
//                       title: Text('Payment Processing...'),
//                       content: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             'Your payment is being processed. Please wait for confirmation.',
//                           ),
//                           SizedBox(height: 20),
//                           CircularProgressIndicator(),
//                         ],
//                       ),
//                     ),
//                     barrierDismissible: false,
//                   );
//                   fetchPaymentTransactionDetails();
//                 }
//               },
//             ),
//           ),
//       ),
//     ),
//     barrierDismissible: false,
//   );
// }

// Future<void> fetchPaymentTransactionDetails() async {
//   try {
//     final response = await http.post(
//       Uri.parse(AppConstants.getTransDetailsUrl),
//       headers: {
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode({
//         'mercid': AppConstants.merchantId,
//         'orderid': orderid,
//         'refund_details': true,
//       }),
//     );

//     var data = jsonDecode(response.body);

//     if (response.statusCode == 200) {
//       Get.back();
//       Get.dialog(
//         AlertDialog(
//           title: const Text('Payment Status'),
//           content: Text(
//             textAlign: TextAlign.center,
//             data['transaction_error_desc'],
//             style: TextStyle(
//               fontSize: 18,
//               color: data['transaction_error_type'] == 'success'
//                   ? Colors.green
//                   : Colors.red,
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Get.back();
//                 Get.back();
//                 if (redirectScreen.value == 'Appointment') {
//                   Get.put(AppointmentController()).getBilldeskResponse(data);
//                 } else if (redirectScreen.value == 'Doctor') {
//                   Get.put(DoctorsController()).getBilldeskResponse(data);
//                 } else if (redirectScreen.value == 'Consultation') {
//                   Get.put(ConsultController()).getBilldeskResponse(data);
//                 } else if (redirectScreen.value == 'LabTest') {
//                   Get.put(LabsController()).getBilldeskResponse(data);
//                 } else if (redirectScreen.value == 'Diagnostic') {
//                   Get.put(DiagnosticController()).getBilldeskResponse(data);
//                 } else {}
//               },
//               child: const Text('OK'),
//             ),
//           ],
//         ),
//       );
//     } else {
//       Get.dialog(
//         AlertDialog(
//           title: const Text('Error'),
//           content: Text('Failed Status: ${response.statusCode}'),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Get.back();
//                 Get.back();
//               },
//               child: const Text('OK'),
//             ),
//           ],
//         ),
//       );
//     }
//   } catch (e) {
//     customToast('An error occurred during the payment: $e');
//   }
// }
