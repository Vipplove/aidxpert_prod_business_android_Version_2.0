import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:pdf_render/pdf_render.dart'; // For PDF rendering
import 'package:image_gallery_saver/image_gallery_saver.dart'; // For saving images to gallery
import 'dart:ui' as ui;

Future<void> downloadFile(String url, String fileName) async {
  try {
    // Determine required permissions based on Android version and file type
    bool hasPermission = false;
    bool isImage = fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png');
    bool isPdf = fileName.toLowerCase().endsWith('.pdf');

    if (!isImage && !isPdf) {
      Get.snackbar(
        'Unsupported File',
        'Only images (jpg, jpeg, png) and PDFs are supported.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        // Android 13+: Request photos permission for gallery access
        print('Requesting Permission.photos for Android 13+');
        hasPermission = await Permission.photos.request().isGranted;
      } else {
        // Android 12 and below: Request storage permission
        print('Requesting Permission.storage for Android 12 or below');
        hasPermission = await Permission.storage.request().isGranted;
      }
    } else {
      // For iOS, assume permission is granted or handled by ImageGallerySaver
      print('Assuming permission granted for iOS');
      hasPermission = true;
    }

    // Handle permission denial
    if (!hasPermission) {
      if (await Permission.photos.isPermanentlyDenied ||
          await Permission.storage.isPermanentlyDenied) {
        Get.snackbar(
          'Permission Required',
          'Please enable storage or media permissions in app settings.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          mainButton: const TextButton(
            onPressed: openAppSettings,
            child: Text('Open Settings', style: TextStyle(color: Colors.white)),
          ),
        );
        return;
      }

      Get.snackbar(
        'Permission Denied',
        'Storage or media permission is required to download files.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Download the file
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      Get.snackbar(
        'Error',
        'Failed to download file: ${response.statusCode}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (isImage) {
      // Save image directly to gallery using image_gallery_saver
      final result = await ImageGallerySaver.saveImage(
        response.bodyBytes,
        quality: 100,
        name: fileName,
      );
      if (result['isSuccess'] == true) {
        Get.snackbar(
          'Success',
          'Image saved to gallery',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to save image to gallery: ${result['errorMessage']}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
      print('Image save result: $result');
    } else {
      // Handle PDF: Save to temp directory, convert to images, and save to gallery
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';
      final pdfFile = File(tempPath);
      await pdfFile.writeAsBytes(response.bodyBytes);

      // Load PDF document
      final pdfDocument = await PdfDocument.openFile(tempPath);
      if (pdfDocument == null) {
        Get.snackbar(
          'Error',
          'Unable to open PDF',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Convert each PDF page to an image and save to gallery
      for (int i = 1; i <= pdfDocument.pageCount; i++) {
        final page = await pdfDocument.getPage(i);
        print('Page $i size: ${page.width} x ${page.height}');

        // Convert PDF points to pixels (300 DPI)
        final width = (page.width * 300 / 72).ceil();
        final height = (page.height * 300 / 72).ceil();
        final pageImage = await page.render(
          width: width,
          height: height,
          allowAntialiasingIOS: true,
        );

        final uiImage = await pageImage.createImageDetached();
        final imageBytes =
            await uiImage.toByteData(format: ui.ImageByteFormat.png);

        if (imageBytes != null) {
          final result = await ImageGallerySaver.saveImage(
            imageBytes.buffer.asUint8List(),
            quality: 100,
            name: 'pdf_page_${i}_${DateTime.now().millisecondsSinceEpoch}',
          );
          if (result['isSuccess'] == true) {
            Get.snackbar(
              'Success',
              'PDF page $i saved to gallery',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          } else {
            Get.snackbar(
              'Error',
              'Failed to save PDF page $i to gallery: ${result['errorMessage']}',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
          print('PDF page $i save result: $result');
        }

        // Clean up
        pageImage.dispose();
      }

      // Clean up PDF document and temp file
      await pdfDocument.dispose();
      if (await pdfFile.exists()) {
        await pdfFile.delete();
      }
    }
  } catch (e) {
    Get.snackbar(
      'Error',
      'Download failed: $e',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    print('Error: $e');
  }
}
