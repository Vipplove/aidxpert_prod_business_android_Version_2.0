// ignore_for_file: constant_identifier_names
part of 'app_pages.dart';

// Authcation
class Routes {
  static const ONBOARDING = '/onboarding';
  static const AUTHENTICATION = '/authentication';
  static const LOGIN = '/authentication/login';
  static const REGISTER = '/authentication/register';
  static const OTP_AUTHENTICATION = '/authentication/otp-authentication';
  static const FORGET_PASSWORD = '/authentication/forget-password';
  static const SUCCESS_MSG = '/authentication/success-message';

  // Labs Provider
  static const LABS_PROVIDER_REGISTRATION = '/labs-provider-registration';
  static const LABS_PROVIDER_DASHBOARD = '/labs-provider-dashboard';
  static const LABS_BOOKING_HISTORY = '/labs-booking-history';
  static const LABS_BRANCH = '/labs-add-branch';
  static const LABS_TEST_DETAILS = '/labs-test-details';
  static const LABS_TEST_ENTRY = '/labs-test-entry';
  static const LABS_ACCOUNT = '/labs-account';
  static const LABS_REPORTS = '/labs-reports';
  static const LABS_INVOICES = '/labs-invoices';
  static const PATHOLOGIST_DASHBOARD = '/labs-pathologist-dashboard';

  // Diagnostic
  static const DIAGNOSTIC_PROVIDER_REGISTRATION =
      '/diagnostic-provider-registration';
  static const DIAGNOSTIC_PROVIDER_DASHBOARD = '/diagnostic-provider-dashboard';
  static const DIAGNOSTIC_BOOKING_HISTORY = '/diagnostic-booking-history';
  static const DIAGNOSTIC_BRANCH = '/diagnostic-add-branch';
  static const DIAGNOSTIC_TEST_DETAILS = '/diagnostic-test-details';
  static const DIAGNOSTIC_TEST_ENTRY = '/diagnostic-test-entry';
  static const DIAGNOSTIC_ACCOUNT = '/diagnostic-account';
  static const DIAGNOSTIC_REPORTS = '/diagnostic-reports';
  static const DIAGNOSTIC_INVOICES = '/diagnostic-invoices';
  static const RADIOLOGIST_DASHBOARD = '/diagnostic-radiologist-dashboard';

  // Ambulance Provider
  static const AMBULANCE_PROVIDER_REGISTRATION =
      '/ambulance-provider-registration';
  static const AMBULANCE_PROVIDER_DASHBOARD = '/ambulance-provider-dashboard';
  static const AMBULANCE_LIST = '/ambulance-list';
  static const AMBULANCE_ADD = '/ambulance-add';
  static const AMBULANCE_DRIVER = '/ambulance-driver';
  static const AMBULANCE_BOOKING_HISTORY = '/ambulance-booking-history';
  static const AMBULANCE_BOOKING_DETAILS = '/ambulance-booking-details';
  static const AMBULANCE_TRACK = '/ambulance-tracking-details';
  static const AMBULANCE_PROVIDER_PROFILE = '/ambulance-provider-profile';
  static const AMBULANCE_ACCOUNT = '/ambulance-account';

  // Driver
  static const DRIVER_DASHBOARD = '/driver-dashboard';
  static const DRIVER_BOOKING_HISTORY = '/driver-booking-history';
  static const DRIVER_PROFILE = '/driver-profile';
  static const DRIVER_TRACKING = '/driver-tracking';

  // Caretaker
  static const CARETAKER_PROVIDER_REGISTRATION =
      '/caretaker-provider-registration';
  static const CARETAKER_PROVIDER_DASHBOARD = '/caretaker-provider-dashboard';
  static const CARETAKER_BOOKING_HISTORY = '/caretaker-booking-history';
  static const CARETAKER_BOOKING_DETAILS = '/caretaker-booking-details';
  static const CARETAKER_STAFF = '/caretaker-staff';
  static const CARETAKER_ADD_STAFF = '/caretaker-add-staff';
  static const CARETAKER_ACCOUNT = '/caretaker-account';

  // Indivisible Caretaker
  static const INDIVISIBLE_CARETAKER_REGISTRATION =
      '/indivisible-caretaker-registration';
  static const INDIVISIBLE_CARETAKER_DASHBOARD =
      '/indivisible-caretaker-dashboard';

  //Admin
  static const ABOUT_US = '/about-us';
  static const ADMIN = '/admin';
  static const SUPPORT = '/support';
  static const CONSULT_BOOKING_ENTRY = '/consultation-booking-entry';
  static const LAB_BOOKING_ENTRY = '/lab-booking-entry';
  static const DIAGNOSTIC_BOOKING_ENTRY = '/diagnostic-booking-entry';
  static const AMBULANCE_BOOKING_ENTRY = '/ambulance-booking-entry';
  static const CARETAKER_BOOKING_ENTRY = '/caretaker-booking-entry';
  static const String ADMIN_LIST = '/admin-list';

  //Sale
  static const SALES_DASHBOARD = '/sales-dashboard';
  static const PROVIDER_LIST = '/provider-list';
  static const REGISTER_DOCTOR = '/register-doctor';

  // -----------------Terms and conditions-----------------
  static const TERMSCONDITION = '/terms-condition';
  static const PRIVACYCONDITION = '/privacy-policy';
}
