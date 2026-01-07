import 'package:flutter/material.dart';
import '../utils/helper.dart';

class AppConstants {
  // Environment configuration
  static const bool isProduction = false;

  // App General Constants
  static String appTitle = 'Aidxpert';
  static Color appPrimaryColor = HexColor("#43b1c6");
  static Color appSecondaryColor = HexColor("#0065a5");
  static Color appScaffoldBgColor = HexColor("#f6f7f8");
  static Color appPg1Color = HexColor("#505050");
  static Color appPg2Color = HexColor("#404040");

  // Onboarding
  static String onBoardT1 = 'Find a doctor...';
  static String onBoardS1 =
      'Find a doctor near you based on your location, specialization, ratings, and availability in the Aidxpert app.';
  static String onBoardT2 = 'Book appointments...';
  static String onBoardS2 =
      'Easily book appointments with your preferred doctor, selecting a convenient date and time, in the Aidxpert app.';
  static String onBoardT3 = 'Lab testing...';
  static String onBoardS3 =
      'Conveniently schedule and access lab testing services through the Aidxpert app for easy and efficient healthcare management.';
  static String onBoardT4 = 'Book Ambulance...';
  static String onBoardS4 =
      'Access our 24/7 ambulance booking service at any time, day or night, guaranteeing fast and reliable medical assistance whenever emergencies arise.';

  // Google Map API
  static String googleApiKey = 'AIzaSyB1BfyNffXtaDZwKruRiohhC9D_royL35U';

  // Supabase URLs and Keys
  static String get supabaseUrl => isProduction
      ? 'https://prod-supabase-project.supabase.co'
      : 'https://ncywooinpckpbkwukuum.supabase.co';
  static String get supabaseAnonKey => isProduction
      ? 'prod-anon-key'
      : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5jeXdvb2lucGNrcGJrd3VrdXVtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk0NzEyMTcsImV4cCI6MjA2NTA0NzIxN30.zHFpzjoVQd8nle0b-atek1f8KGfarJ7txm_tDgYa1os'; // Non-production key

  // API URLs
  static String get endpoint => isProduction
      ? 'https://prod.aidxpert.com/api'
      : 'https://27ba3341d35a.ngrok-free.app/api/v1';

  // Mobile Number
  static String whatsappNumber = '+918585056006';
  static String teleCall = '+918585056006';
  static String supportEmailAddress =
      'mailto:support@aidxpert.com?subject=Support%20Request:';

  // Image size
  static double imageSize = 5 * 1024 * 1024;

  // BillDesk Configuration
  // BillDesk UAT Constants
  static const String _uatMerchantId = "UFOSSGENV2";
  static const String _uatClientId = "ufossgenv2";
  static const String _uatCreateOrderAPIUrl = "https://aidxpert.in/stream";
  static const String _uatRedirectUrl = "https://aidxpert.in/response";
  static const String _uatBilldeskGatewayUrl =
      "https://uat1.billdesk.com/u2/web/v1_2/embeddedsdk";
  static const String _uatGetTransDetailsUrl =
      'https://aidxpert.in/getPaymentTransactionDetails';

  // BillDesk PROD Constants
  static const String _prodMerchantId = "PROD_UFOSSGENV2";
  static const String _prodClientId = "prod_ufossgenv2";
  static const String _prodCreateOrderAPIUrl =
      "https://prod.aidxpert.in/stream";
  static const String _prodRedirectUrl = "https://prod.aidxpert.in/response";
  static const String _prodBilldeskGatewayUrl =
      "https://pg.billdesk.com/web/v1_2/embeddedsdk";
  static const String _prodGetTransDetailsUrl =
      'https://prod.aidxpert.in/getPaymentTransactionDetails';

  // Environment-dependent BillDesk Constants
  static String get merchantId =>
      isProduction ? _prodMerchantId : _uatMerchantId;
  static String get clientId => isProduction ? _prodClientId : _uatClientId;
  static String get createOrderAPIUrl =>
      isProduction ? _prodCreateOrderAPIUrl : _uatCreateOrderAPIUrl;
  static String get redirectUrl =>
      isProduction ? _prodRedirectUrl : _uatRedirectUrl;
  static String get billdeskGatewayUrl =>
      isProduction ? _prodBilldeskGatewayUrl : _uatBilldeskGatewayUrl;
  static String get getTransDetailsUrl =>
      isProduction ? _prodGetTransDetailsUrl : _uatGetTransDetailsUrl;

  // flutter build apk --target-platform android-x64 --analyze-size
}
