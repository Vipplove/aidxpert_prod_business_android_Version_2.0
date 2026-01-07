// ignore_for_file: constant_identifier_names
import 'package:get/get.dart';
import '../modules/ambulance-provider/ambulance_provider_dashboard/views/ambulance_account.dart';
import '../modules/ambulance-provider/ambulance_provider_dashboard/views/ambulance_booking_details.dart';
import '../modules/ambulance-provider/ambulance_provider_dashboard/views/ambulance_booking_history.dart';
import '../modules/ambulance-provider/ambulance_provider_dashboard/views/ambulance_dashboard.dart';
import '../modules/ambulance-provider/ambulance_provider_dashboard/views/ambulance_driver.dart';
import '../modules/ambulance-provider/ambulance_provider_dashboard/views/ambulance_list.dart';
import '../modules/ambulance-provider/ambulance_provider_dashboard/views/ambulance_tracking.dart';
import '../modules/ambulance-provider/ambulance_provider_registration/bindings/ambulance_provider_registration_binding.dart';
import '../modules/ambulance-provider/ambulance_provider_registration/views/ambulance_provider_registration.dart';
import '../modules/authentication/views/privacy_and_policy.dart';
import '../modules/authentication/views/terms_and_condition.dart';
import '../modules/caretaker-provider/caretaker_provider_dashboard/bindings/caretaker_binding.dart';
import '../modules/caretaker-provider/caretaker_provider_dashboard/views/caretaker_account.dart';
import '../modules/caretaker-provider/caretaker_provider_dashboard/views/caretaker_add_staff.dart';
import '../modules/caretaker-provider/caretaker_provider_dashboard/views/caretaker_booking_details.dart';
import '../modules/caretaker-provider/caretaker_provider_dashboard/views/caretaker_booking_history.dart';
import '../modules/caretaker-provider/caretaker_provider_dashboard/views/caretaker_dashboard.dart';
import '../modules/caretaker-provider/caretaker_provider_dashboard/views/caretaker_staff.dart';
import '../modules/caretaker-provider/caretaker_provider_registration/bindings/caretaker_provider_registration_binding.dart';
import '../modules/caretaker-provider/caretaker_provider_registration/views/caretaker_provider_registration.dart';
import '../modules/diagnostic-provider/diagnostics_provider_dashboard/bindings/diagnostics_provider_dashboard_binding.dart';
import '../modules/diagnostic-provider/diagnostics_provider_dashboard/views/diagnostics_account.dart';
import '../modules/diagnostic-provider/diagnostics_provider_dashboard/views/diagnostics_booking_history.dart';
import '../modules/diagnostic-provider/diagnostics_provider_dashboard/views/diagnostics_branch.dart';
import '../modules/diagnostic-provider/diagnostics_provider_dashboard/views/diagnostics_invoices.dart';
import '../modules/diagnostic-provider/diagnostics_provider_dashboard/views/diagnostics_provider_dashboard_view.dart';
import '../modules/diagnostic-provider/diagnostics_provider_dashboard/views/diagnostics_reports.dart';
import '../modules/diagnostic-provider/diagnostics_provider_dashboard/views/diagnostics_test_details.dart';
import '../modules/diagnostic-provider/diagnostics_provider_dashboard/views/diagnostics_test_entry.dart';
import '../modules/diagnostic-provider/diagnostics_provider_registration/bindings/diagnostics_provider_registration_binding.dart';
import '../modules/diagnostic-provider/diagnostics_provider_registration/views/diagnostics_provider_registration_view.dart';
import '../modules/driver/bindings/driver_binding.dart';
import '../modules/driver/views/driver_dashboard.dart';
import '../modules/driver/views/driver_tracking.dart';
import '../modules/labs-provider/labs_provider_dashboard/bindings/labs_provider_dashboard_binding.dart';
import '../modules/labs-provider/labs_provider_dashboard/views/labs/labs_account.dart';
import '../modules/labs-provider/labs_provider_dashboard/views/labs/labs_booking_history.dart';
import '../modules/labs-provider/labs_provider_dashboard/views/labs/labs_invoices.dart';
import '../modules/labs-provider/labs_provider_dashboard/views/labs/labs_provider_dashboard_view.dart';
import '../modules/labs-provider/labs_provider_dashboard/views/labs/labs_branch.dart';
import '../modules/labs-provider/labs_provider_dashboard/views/labs/labs_reports.dart';
import '../modules/labs-provider/labs_provider_dashboard/views/labs/labs_test_details.dart';
import '../modules/labs-provider/labs_provider_dashboard/views/labs/labs_test_entry.dart';
import '../modules/labs-provider/pathologist/pathologist_dashboard.dart';
import '../modules/diagnostic-provider/radiologist/radiologist_dashboard.dart';
import '../modules/labs-provider/labs_provider_registration/bindings/labs_provider_registration_binding.dart';
import '../modules/labs-provider/labs_provider_registration/views/labs_provider_registration_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding.dart';
import '../modules/authentication/bindings/authentication_binding.dart';
import '../modules/authentication/views/authentication.dart';
import '../modules/authentication/views/forget_password.dart';
import '../modules/authentication/views/login.dart';
import '../modules/authentication/views/otp_authentication.dart';
import '../modules/authentication/views/register.dart';
import '../modules/authentication/views/success_msg.dart';
import '../modules/sales/bindings/sales_binding.dart';
import '../modules/sales/views/provider_list.dart';
import '../modules/sales/views/register_doctor.dart';
import '../modules/sales/views/sales_dashboard.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.ONBOARDING;

  static final routes = [
    // --- Onboarding ---
    GetPage(
      name: Routes.ONBOARDING,
      page: () => const Onboarding(),
      binding: OnboardingBinding(),
      transition: Transition.native,
    ),

    // --- Terms & Privacy ---
    GetPage(
      name: Routes.TERMSCONDITION,
      page: () => const TermsAndCondition(),
      binding: AuthenticationBinding(),
      transition: Transition.native,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.PRIVACYCONDITION,
      page: () => const PrivacyAndPolicy(),
      binding: AuthenticationBinding(),
      transition: Transition.native,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // --- Authentication (Parent + Children) ---
    GetPage(
      name: Routes.AUTHENTICATION,
      page: () => const AuthenticationView(),
      binding: AuthenticationBinding(),
      transition: Transition.native,
      children: [
        GetPage(
          name: Routes.LOGIN.replaceAll('/authentication', ''),
          page: () => LoginView(),
          binding: AuthenticationBinding(),
          transition: Transition.native,
        ),
        GetPage(
          name: Routes.REGISTER.replaceAll('/authentication', ''),
          page: () => RegisterView(),
          binding: AuthenticationBinding(),
          transition: Transition.native,
        ),
        GetPage(
          name: Routes.OTP_AUTHENTICATION.replaceAll('/authentication', ''),
          page: () => const OtpAuthenticationView(),
          binding: AuthenticationBinding(),
          transition: Transition.native,
        ),
        GetPage(
          name: Routes.FORGET_PASSWORD.replaceAll('/authentication', ''),
          page: () => ForgetPasswordView(),
          binding: AuthenticationBinding(),
          transition: Transition.native,
        ),
        GetPage(
          name: Routes.SUCCESS_MSG.replaceAll('/authentication', ''),
          page: () => const SuccessMsgView(),
          binding: AuthenticationBinding(),
          transition: Transition.native,
        ),
      ],
    ),

    // --- Labs Provider Routes ---
    GetPage(
      name: Routes.LABS_PROVIDER_REGISTRATION,
      page: () => LabsRegistrationView(),
      binding: LabsRegistrationBinding(),
      transition: Transition.native,
    ),
    GetPage(
      name: Routes.LABS_PROVIDER_DASHBOARD,
      page: () => const LabsProviderDashboardView(),
      binding: LabsProviderDashboardBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.LABS_BOOKING_HISTORY,
      page: () => const LabsBookingHistoryView(),
      binding: LabsProviderDashboardBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.LABS_BRANCH,
      page: () => LabsBranchView(),
      binding: LabsProviderDashboardBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.LABS_TEST_ENTRY,
      page: () => LabsTestEntry(),
      binding: LabsProviderDashboardBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.LABS_TEST_DETAILS,
      page: () => const LabsTestDetails(),
      binding: LabsProviderDashboardBinding(),
      transition: Transition.native,
    ),
    GetPage(
      name: Routes.LABS_ACCOUNT,
      page: () => const LabAccount(),
      binding: LabsProviderDashboardBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.LABS_REPORTS,
      page: () => const LabsReports(),
      binding: LabsProviderDashboardBinding(),
      transition: Transition.native,
    ),
    GetPage(
      name: Routes.LABS_INVOICES,
      page: () => const LabsInvoices(),
      binding: LabsProviderDashboardBinding(),
      transition: Transition.native,
    ),
    GetPage(
      name: Routes.PATHOLOGIST_DASHBOARD,
      page: () => const PathologistDashboard(),
      binding: LabsProviderDashboardBinding(),
      transition: Transition.noTransition,
    ),

    // --- Diagnostic Provider Routes ---
    GetPage(
      name: Routes.DIAGNOSTIC_PROVIDER_REGISTRATION,
      page: () => DiagnosticsRegistrationView(),
      binding: DiagnosticsRegistrationBinding(),
      transition: Transition.native,
    ),
    GetPage(
      name: Routes.DIAGNOSTIC_PROVIDER_DASHBOARD,
      page: () => const DiagnosticsProviderDashboardView(),
      binding: DiagnosticsProviderDashboardBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.DIAGNOSTIC_BOOKING_HISTORY,
      page: () => const DiagnosticsBookingHistoryView(),
      binding: DiagnosticsProviderDashboardBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.DIAGNOSTIC_BRANCH,
      page: () => DiagnosticsBranchView(),
      binding: DiagnosticsProviderDashboardBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.DIAGNOSTIC_TEST_ENTRY,
      page: () => DiagnosticsTestEntry(),
      binding: DiagnosticsProviderDashboardBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.DIAGNOSTIC_TEST_DETAILS,
      page: () => const DiagnosticsTestDetails(),
      binding: DiagnosticsProviderDashboardBinding(),
      transition: Transition.native,
    ),
    GetPage(
      name: Routes.DIAGNOSTIC_ACCOUNT,
      page: () => const DiagnosticAccount(),
      binding: DiagnosticsProviderDashboardBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.DIAGNOSTIC_REPORTS,
      page: () => const DiagnosticsReports(),
      binding: DiagnosticsProviderDashboardBinding(),
      transition: Transition.native,
    ),
    GetPage(
      name: Routes.DIAGNOSTIC_INVOICES,
      page: () => const DiagnosticsInvoices(),
      binding: DiagnosticsProviderDashboardBinding(),
      transition: Transition.native,
    ),
    GetPage(
      name: Routes.RADIOLOGIST_DASHBOARD,
      page: () => const RadiologistDashboard(),
      binding: DiagnosticsProviderDashboardBinding(),
      transition: Transition.noTransition,
    ),

    // --- Sale Routes ---
    GetPage(
      name: Routes.SALES_DASHBOARD,
      page: () => SalesDashboard(),
      binding: SalesBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.PROVIDER_LIST,
      page: () => const ProviderList(),
      binding: SalesBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.REGISTER_DOCTOR,
      page: () => RegisterDoctorProfile(),
      binding: SalesBinding(),
      transition: Transition.noTransition,
    ),

    // --- Ambulance Provider Routes ---
    GetPage(
      name: Routes.AMBULANCE_PROVIDER_REGISTRATION,
      page: () => AmbulanceProviderRegistration(),
      binding: AmbulanceProviderRegistrationBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.AMBULANCE_PROVIDER_DASHBOARD,
      page: () => AmbulanceProviderDashboard(),
      binding: AmbulanceProviderRegistrationBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.AMBULANCE_BOOKING_HISTORY,
      page: () => AmbulanceBookingHistory(),
      binding: AmbulanceProviderRegistrationBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.AMBULANCE_BOOKING_DETAILS,
      page: () => AmbulanceBookingDetails(),
      binding: AmbulanceProviderRegistrationBinding(),
      transition: Transition.native,
    ),
    GetPage(
      name: Routes.AMBULANCE_LIST,
      page: () => AmbulanceList(),
      binding: AmbulanceProviderRegistrationBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.AMBULANCE_ACCOUNT,
      page: () => AmbulanceAccount(),
      binding: AmbulanceProviderRegistrationBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.AMBULANCE_TRACK,
      page: () => AmbulanceTracking(),
      binding: AmbulanceProviderRegistrationBinding(),
      transition: Transition.native,
    ),
    GetPage(
      name: Routes.AMBULANCE_DRIVER,
      page: () => AmbulanceDriver(),
      binding: AmbulanceProviderRegistrationBinding(),
      transition: Transition.noTransition,
    ),

    //--- Driver Dashboard ---
    GetPage(
      name: Routes.DRIVER_DASHBOARD,
      page: () => DriverDashboard(),
      binding: DriverBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.DRIVER_TRACKING,
      page: () => DriverTracking(),
      binding: DriverBinding(),
      transition: Transition.noTransition,
    ),

    // --- Caretaker Provider Routes ---
    GetPage(
      name: Routes.CARETAKER_PROVIDER_REGISTRATION,
      page: () => CaretakerProviderRegistration(),
      binding: CaretakerProviderRegistrationBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.CARETAKER_PROVIDER_DASHBOARD,
      page: () => CareTakerDashboard(),
      binding: CaretakerBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.CARETAKER_BOOKING_HISTORY,
      page: () => CareTakerBookingHistory(),
      binding: CaretakerBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.CARETAKER_STAFF,
      page: () => CareTakerStaff(),
      binding: CaretakerBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.CARETAKER_ADD_STAFF,
      page: () => CareTakerAddStaff(),
      binding: CaretakerBinding(),
      transition: Transition.native,
    ),
    GetPage(
      name: Routes.CARETAKER_BOOKING_DETAILS,
      page: () => CareTakerBookingDetails(),
      binding: CaretakerBinding(),
      transition: Transition.native,
    ),
    GetPage(
      name: Routes.CARETAKER_ACCOUNT,
      page: () => CaretakerAccount(),
      binding: CaretakerBinding(),
      transition: Transition.noTransition,
    ),
  ];
}
