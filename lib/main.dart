// ignore_for_file: use_build_context_synchronously, avoid_print, unrelated_type_equality_checks
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';
import 'package:http/http.dart' as http;
import 'app/routes/app_pages.dart';
import 'constants/app_constants.dart';
import 'utils/firebase.dart';
import 'utils/helper.dart';
import 'dart:async';
import 'dart:convert';

// Background message handler (must be top-level or static)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
  if (message.notification != null) {
    print("Background Notification Title: ${message.notification?.title}");
    print("Background Notification Body: ${message.notification?.body}");
  }
  if (message.data.isNotEmpty) {
    print("Background Data Payload: ${message.data}");
  }
  // Add your custom logic here
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  // Check internet connectivity before proceeding
  bool hasInternet = await checkInternetConnectivity();
  if (!hasInternet) {
    // Show dialog and exit if no internet
    runApp(const NoInternetApp());
    return;
  }

  if (Platform.isIOS) {
    await saveStr('fcm_token', 'test');
  } else {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseApi().initNotifications();
  }

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: AppConstants.appPrimaryColor,
    ),
  );

  // Request only location permission at startup
  await requestPermissions();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Determine initial route asynchronously
  String initialRoute = await determineInitialRoute();

  runApp(
    MyApp(initialRoute: initialRoute),
  );
}

// Function to check internet connectivity
Future<bool> checkInternetConnectivity() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    return false;
  }
  // Verify actual internet access by attempting a DNS lookup
  try {
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException catch (_) {
    return false;
  }
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    // Initialize connectivity listener
    final Connectivity connectivity = Connectivity();
    StreamSubscription<List<ConnectivityResult>>? subscription;

    void checkConnectivity(List<ConnectivityResult> results) async {
      bool hasInternet = await checkInternetConnectivity();
      if (!hasInternet) {
        Get.dialog(
          AlertDialog(
            title: const Text('No Internet Connection'),
            content: const Text(
                'Please check your internet connection and try again.'),
            actions: [
              TextButton(
                child: const Text('Retry'),
                onPressed: () async {
                  bool hasInternet = await checkInternetConnectivity();
                  if (hasInternet) {
                    Get.back();
                    // Trigger version check
                    // await checkAppVersion(context);
                  }
                },
              ),
              TextButton(
                child: const Text('Exit'),
                onPressed: () => SystemNavigator.pop(),
              ),
            ],
          ),
          barrierDismissible: false,
        );
      }
    }

    // Listen for connectivity changes
    subscription = connectivity.onConnectivityChanged.listen(checkConnectivity);

    return GetMaterialApp(
      color: AppConstants.appSecondaryColor,
      locale: const Locale('en', 'US'),
      debugShowCheckedModeBanner: false,
      title: AppConstants.appTitle,
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      theme: ThemeData(
        fontFamily: 'Roboto',
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18.0,
          ),
        ),
      ),
      builder: EasyLoading.init(
        builder: (context, child) {
          // Get the shortest side of the screen to classify device size
          final double shortestSide = MediaQuery.of(context).size.shortestSide;
          final bool isTablet = shortestSide >= 600;

          // Get device dimensions
          final Size screenSize = MediaQuery.of(context).size;
          final double width = screenSize.width;
          final double height = screenSize.height;

          // Define textScaleFactor based on platform and device characteristics
          double textScaleFactor;
          if (Platform.isIOS) {
            textScaleFactor = isTablet ? 1.2 : 0.9;
          } else {
            if (width <= 360.0 && height <= 790.0) {
              textScaleFactor = 0.9;
            } else {
              textScaleFactor = 1.0;
            }
          }

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final box = GetStorage();
            bool hasFetchedLocation = box.read('hasStoredLocation') ?? false;
            bool hasDismissedLocationDialog =
                box.read('hasDismissedLocationDialog') ?? false;

            if (!hasFetchedLocation && !hasDismissedLocationDialog) {
              await fetchAndStoreLocation(context);
            }
          });

          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScaleFactor)),
            child: child!,
          );
        },
      ),

      // Dispose of the subscription when the widget is disposed
      onDispose: () {
        subscription?.cancel();
      },
    );
  }
}

// App to show when no internet is available
class NoInternetApp extends StatelessWidget {
  const NoInternetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'No Internet Connection',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  bool hasInternet = await checkInternetConnectivity();
                  if (hasInternet) {
                    // Restart the app
                    String initialRoute = await determineInitialRoute();
                    runApp(MyApp(initialRoute: initialRoute));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Still no internet connection.'),
                      ),
                    );
                  }
                },
                child: const Text('Retry'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Exit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> requestPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.location,
  ].request();

  if (statuses[Permission.location]!.isDenied) {
    print('Location permission denied');
  }
}

Future<void> fetchAndStoreLocation(BuildContext context) async {
  final box = GetStorage();
  bool serviceEnabled;
  LocationPermission permission;

  // Check if the user has previously dismissed the dialog
  bool hasDismissedLocationDialog =
      box.read('hasDismissedLocationDialog') ?? false;
  if (hasDismissedLocationDialog) {
    print('Location dialog previously dismissed, skipping dialog.');
    return;
  }

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print('Location services disabled');
    Get.dialog(
      AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
            'Please enable location services to proceed. Would you like to open settings?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () async {
              // Store the dismissal state
              await box.write('hasDismissedLocationDialog', true);
              Get.back();
            },
          ),
          TextButton(
            child: const Text('Open Settings'),
            onPressed: () async {
              await Geolocator.openLocationSettings();
              Get.back();
              await Future.delayed(const Duration(milliseconds: 500));
              bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
              if (serviceEnabled) {
                await fetchAndStoreLocation(context);
              } else {
                // Store the dismissal state if the user returns without enabling
                await box.write('hasDismissedLocationDialog', true);
              }
            },
          ),
        ],
      ),
    );
    return;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      print('Location permission denied forever');
      return;
    }
  }

  try {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print('Latitude: ${position.latitude}, Longitude: ${position.longitude}');

    await box.write('latitude', position.latitude.toString());
    await box.write('longitude', position.longitude.toString());
    await box.write('hasStoredLocation', true);
  } catch (e) {
    print('Error fetching location: $e');
  }
}

Future<void> checkAppVersion(BuildContext context) async {
  final box = GetStorage();
  final now = DateTime.now().millisecondsSinceEpoch;

  try {
    // Check internet connectivity before making API call
    bool hasInternet = await checkInternetConnectivity();
    if (!hasInternet) {
      print('No internet connection for version check');
      if (context.mounted) {
        Get.snackbar(
          'No Internet',
          'Please check your internet connection to perform version check.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
      return;
    }

    // Get local app version
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String localVersion = packageInfo.version;

    // Fetch backend version
    final response =
        await http.get(Uri.parse('${AppConstants.endpoint}/settings'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      if (jsonData.isNotEmpty) {
        var type = await readStr('type');
        if (jsonData[0]['b_maintenance'] == 1 && type != 'Admin') {
          if (context.mounted) {
            Get.defaultDialog(
              title: '🚧 Maintenance Mode',
              titleStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orangeAccent,
              ),
              content: const Text(
                'The app is currently under maintenance.\nPlease try again later.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              backgroundColor: Colors.white,
              radius: 15,
              barrierDismissible: false,
              confirm: TextButton(
                onPressed: () {
                  if (Platform.isAndroid || Platform.isIOS) {
                    exit(0);
                  } else {
                    Get.back();
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }
          return;
        }

        // Select the appropriate version field based on platform
        final String backendVersion = Platform.isAndroid
            ? jsonData[0]['b_android_version']
            : jsonData[0]['b_ios_version'];

        // Compare versions
        final Version local = Version.parse(localVersion);
        final Version backend = Version.parse(backendVersion);

        if (backend > local) {
          if (context.mounted) {
            Timer(
              const Duration(seconds: 1),
              () {
                showUpdateDialog(context);
              },
            );
          }
        }
      } else {
        print('Empty response from backend');
      }
    } else if (response.statusCode == 429) {
      print('Rate limit exceeded for version check');
      if (context.mounted) {
        Get.snackbar(
          'Rate Limit Exceeded',
          'Too many version check requests. Please try again later.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } else {
      print('Failed to fetch backend version: ${response.statusCode}');
    }

    // Update last checked timestamp
    await box.write('lastVersionCheck', now);
  } catch (e) {
    print('Error checking app version: $e');
    if (context.mounted) {
      Get.snackbar(
        'Error',
        'Failed to check for updates. Please try again later.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }
}

void showUpdateDialog(BuildContext context) {
  Get.defaultDialog(
    title: '',
    titlePadding: EdgeInsets.zero,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    barrierDismissible: false,
    radius: 10,
    backgroundColor: Colors.white,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.network(
          'https://example.com/update_icon.png',
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.system_update,
            size: 60,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'New Version Available!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'A new version of the app is available. Update now to enjoy the latest features and improvements!',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => SystemNavigator.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Open Play Store or App Store
                final String appId = Platform.isAndroid
                    ? 'com.fossgentechnologies.aidxpert_business'
                    : '6642680568';
                final String url = Platform.isAndroid
                    ? 'market://details?id=$appId'
                    : 'https://apps.apple.com/app/id$appId';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                } else {
                  Get.snackbar(
                    'Error',
                    'Could not open the app store.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Future<String> determineInitialRoute() async {
  final type = await readStr('userType');
  final isFirstTime = await readStr('isFirstTime') == 'true';
  final token = await readStr('token') ?? '';

  print(type);
  print(isFirstTime);
  print(token);

  // Map user types to their dashboards
  const dashboardRoutes = {
    'Labs': Routes.LABS_PROVIDER_DASHBOARD,
    'Pathologist': Routes.PATHOLOGIST_DASHBOARD,
    'Diagnostic': Routes.DIAGNOSTIC_PROVIDER_DASHBOARD,
    'Radiologist': Routes.RADIOLOGIST_DASHBOARD,
    'Ambulance': Routes.AMBULANCE_PROVIDER_DASHBOARD,
    'Driver': Routes.DRIVER_DASHBOARD,
    'Caretaker': Routes.CARETAKER_PROVIDER_DASHBOARD,
    'Indivisible-Caretaker': Routes.INDIVISIBLE_CARETAKER_DASHBOARD,
    'Admin': Routes.ADMIN,
    'Support': Routes.SUPPORT,
    'Sales': Routes.SALES_DASHBOARD,
  };

  // Default route if type not found
  final dashboardRoute = dashboardRoutes[type];

  if (dashboardRoute == null) {
    // Unknown or missing type
    return Routes.ONBOARDING;
  }

  // Everyone else goes to ONBOARDING if not first time
  return isFirstTime ? Routes.ONBOARDING : dashboardRoute;
}
