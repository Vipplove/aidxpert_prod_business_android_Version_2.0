// ignore_for_file: unused_local_variable, unused_element, non_constant_identifier_names, deprecated_member_use
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/routes/app_pages.dart';
import '../constants/app_constants.dart';

onWillPop(contexts) async {
  return (await showDialog(
        context: contexts,
        builder: (context) => AlertDialog(
          title: const Text('Are you sure ?'),
          content: const Text('Do you want to exit an App'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => SystemNavigator.pop(),
              child: const Text('Yes'),
            ),
          ],
        ),
      )) ??
      false;
}

InputDecoration inputFieldDecoration(txtLabel, txtHint, preFixIcon, [disable]) {
  return InputDecoration(
    labelStyle: const TextStyle(
      color: Colors.black,
    ),
    border: const OutlineInputBorder(
      borderSide: BorderSide(width: 1.0, color: Colors.white),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(width: 1.0, color: Colors.green),
    ),
    labelText: txtLabel,
    hintText: txtHint,
    enabled: true,
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: AppConstants.appPrimaryColor,
        width: 0.8,
      ),
      borderRadius: const BorderRadius.all(
        Radius.circular(10),
      ),
    ),
    prefixIcon: preFixIcon,
    errorStyle: const TextStyle(
      fontSize: 15.5,
    ),
    filled: disable, // Set filled property to true
  );
}

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

// Image capture and picker
final ImagePicker _imagePicker = ImagePicker();

Future captureImage({
  ImageSource source = ImageSource.camera,
  int imageQuality = 100,
  bool multiple = false,
}) async {
  return await _imagePicker.pickImage(
    source: source,
    imageQuality: imageQuality,
  );
}

Future pickImage({
  ImageSource source = ImageSource.gallery,
  int imageQuality = 100,
  bool multiple = false,
}) async {
  return await _imagePicker.pickImage(
    source: source,
    imageQuality: imageQuality,
  );
}
// End

// PDF select
Future<String> pickPDF() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );

  if (result != null && result.files.isNotEmpty) {
    File file = File(result.files.first.path!);
    return file.path;
  } else {
    return '';
  }
}

bool hasPdfExtension(String text) {
  RegExp regex = RegExp(r'\.pdf$', caseSensitive: false);
  return regex.hasMatch(text);
}
// End

//Shared Preferences
final storage = GetStorage();

saveStr(String key, String message) async {
  storage.write(key, message);
}

readStr(String key) async {
  return storage.read(key);
}

clearStr(String key) async {
  storage.remove(key);
}

clearAllStore() async {
  var fcmToken = await readStr('fcm_token');
  await storage.erase();
  await saveStr('fcm_token', fcmToken);
  Get.deleteAll();
  Get.offAllNamed(Routes.ONBOARDING);
}
// End

// Toast Message
void customToast(String message, [Color? backgroundColor]) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: backgroundColor ?? Colors.red,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

// Random color generate
generateRandomColor() {
  Random random = Random();
  int minColorValue = 50; // Minimum value for each RGB channel (0-255).
  int maxColorValue = 150; // Maximum value for each RGB channel (0-255).

  int red = minColorValue + random.nextInt(maxColorValue - minColorValue + 1);
  int green = minColorValue + random.nextInt(maxColorValue - minColorValue + 1);
  int blue = minColorValue + random.nextInt(maxColorValue - minColorValue + 1);

  return Color.fromARGB(255, red, green, blue);
}

//Status Color
Color getStatusColor(String status) {
  switch (status) {
    case 'Pending':
      return Colors.blue;
    case 'Request':
      return Colors.green;
    case 'Accept':
      return Colors.green;
    case 'Completed':
      return Colors.teal;
    case 'Canceled':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

// Loading
var loading = Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset(
        'assets/logo/logo.png',
        height: 60,
        width: 100,
      ),
      const SizedBox(
        height: 6,
        width: 160,
        child: LinearProgressIndicator(),
      ),
    ],
  ),
);

// Adjustable card content
Card AdjustableCard(widgets) {
  return Card(
    color: Colors.white,
    elevation: 0,
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            child: widgets,
          );
        },
      ),
    ),
  );
}

// Alert Popup
Dialog alertDialog(BuildContext context, title, message, navigate, [text]) {
  return Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0),
    ),
    child: IntrinsicHeight(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (navigate == 'Back') {
                  Get.back();
                } else if (navigate == '') {
                  return;
                } else {
                  Get.toNamed(navigate);
                }
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
              child: Text(
                text ?? 'Done',
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Image upload Button in prescription and lab
Container imageUploadBtn(icon, text) {
  return Container(
    width: 75,
    height: 70,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      shape: BoxShape.rectangle,
      color: Colors.white,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: AppConstants.appPrimaryColor,
          size: 40,
        ),
        Text(text)
      ],
    ),
  );
}

// Array of object value is exist
isArrValExist(arr, val) {
  var contain = arr.where((v) => v['id'] == val);
  return contain.isEmpty ? false : true;
}

//remove word from string
removeWord(str, word) {
  return str.replaceAll(word, "");
}

getFormatedDate(date, formate) {
  var inputFormat = DateFormat('yyyy-MM-dd HH:mm');
  var inputDate = inputFormat.parse(date);
  var outputFormat = DateFormat(formate);
  return outputFormat.format(inputDate);
}

// Word Parent
bool wordExists(String text, String word) {
  return text.contains(word);
}

// Star Rating
StarRating(val) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: List.generate(
      5,
      (index) {
        return Icon(
          index < val ? Icons.star : Icons.star_border,
          size: 22,
          color: index < val ? AppConstants.appPrimaryColor : Colors.blue,
        );
      },
    ),
  );
}

// Calling
void launchPhoneCall(String phoneNumber) async {
  final url = 'tel:$phoneNumber';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

String generateUniqueTimestamp() {
  final now = DateTime.now().millisecondsSinceEpoch;
  final random = Random().nextInt(9000) + 1000; // 4-digit random
  return '${now % 10000000000}$random'; // last 10 digits of time + random
}

String getMonthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return months[month - 1];
}

String formatDate(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return 'Unknown';
  try {
    final date = DateTime.parse(isoDate);
    return '${date.day} ${getMonthName(date.month)} ${date.year}';
  } catch (e) {
    return 'Invalid date';
  }
}

Widget buildOptionCard({
  required IconData icon,
  required String text,
  required String highlight,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 110,
      height: 95,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: Colors.black87),
          const SizedBox(height: 5),
          Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          ),
          Text(
            highlight,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}

String capitalize(String? text) {
  if (text == null || text.isEmpty) return '';
  return text
      .split(' ')
      .map((word) => word.isEmpty
          ? ''
          : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');
}

String convertDateTime(dateTimeString) {
  DateTime utcDateTime = DateTime.parse(dateTimeString);
  DateTime istDateTime = utcDateTime.add(const Duration(hours: 5, minutes: 30));
  String formattedDate = DateFormat('dd-MM-yyyy | hh:mm a').format(istDateTime);
  return formattedDate;
}

String convertDate(String dateTimeString) {
  DateTime dateTime = DateTime.parse(dateTimeString);
  String formattedDate = DateFormat('dd-MM-yyyy').format(dateTime);
  return formattedDate;
}

String getTestNames(tests) {
  return tests.map((test) => test['test_name'] as String).join(', ');
}

showInactiveAccountAlert(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Account Status'),
          content: const Text(
              'Your account is currently under review. Once our verification process is completed, our team will reach out to you. If you need immediate support, please contact our customer service team'),
          actions: <Widget>[
            TextButton(
              child: const Text('Call Now'),
              onPressed: () async {
                if (await canLaunch(AppConstants.teleCall)) {
                  await launch(AppConstants.teleCall);
                } else {
                  throw 'Could not launch';
                }
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () {
                clearAllStore();
              },
            ),
            TextButton(
              child: const Text('Exit App'),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
          ],
        );
      },
    );
  });
}

// Reusable Success Dialog
Widget buildSuccessDialog({
  required String title,
  required String description,
  required VoidCallback onClose,
}) {
  return Material(
    color: Colors.transparent,
    child: Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 60),
          const SizedBox(height: 16),
          Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onClose,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

// Reusable Error Dialog
Widget buildErrorDialog({required String title, required String description}) {
  return Material(
    color: Colors.transparent,
    child: Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

Color getBookingStatusColor(String status) {
  switch (status) {
    case 'COMPLETED':
      return Colors.green;
    case 'CANCELLED':
      return Colors.red;
    case 'CONFIRMED':
      return Colors.blue;
    default:
      return Colors.orange;
  }
}

void showApiError(dynamic e) {
  String title = 'Error';
  String message = 'Something went wrong';

  if (e is Map<String, dynamic>) {
    // Main message
    title = e['message']?.toString() ?? 'Error';

    // Detailed errors (array)
    if (e['error'] is List && e['error'].isNotEmpty) {
      message = e['error'].join('\n');
    }
  } else {
    message = e.toString();
  }

  Get.snackbar(
    title,
    message,
    backgroundColor: Colors.red,
    colorText: Colors.white,
    snackPosition: SnackPosition.TOP,
    margin: const EdgeInsets.all(12),
    borderRadius: 10,
    duration: const Duration(seconds: 4),
    icon: const Icon(Icons.error, color: Colors.white),
  );
}
