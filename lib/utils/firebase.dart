// ignore_for_file: avoid_print
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'helper.dart';

class FirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Request notification permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get and save FCM token
    final fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      await saveStr('fcm_token', fcmToken);
      print('fcmToken: $fcmToken');
    }

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      await saveStr('fcm_token', newToken);
      print('FCM Token Refreshed: $newToken');
    });

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.messageId}');
      if (message.notification != null) {
        print("Foreground Notification Title: ${message.notification?.title}");
        print("Foreground Notification Body: ${message.notification?.body}");
        Get.snackbar(
          message.notification?.title ?? "Notification",
          message.notification?.body ?? "You have a new message",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: Colors.black,
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 8),
          isDismissible: true,
        );
      }
      if (message.data.isNotEmpty) {
        print("Foreground Data Payload: ${message.data}");
      }
      // Add your custom logic here
    });

    // Handle notification taps when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened app: ${message.messageId}');
      // Add navigation logic here, e.g., Get.toNamed(Routes.SOME_PAGE);
    });
  }
}
