import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'models/appointment.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/doctor_onboarding_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/patient/patient_shell_screen.dart';
import 'screens/patient/search_screen.dart';
import 'screens/patient/doctor_profile_screen.dart';
import 'screens/patient/book_appointment_screen.dart';
import 'screens/patient/appointment_confirmation_screen.dart';
import 'screens/patient/appointment_detail_screen.dart';
import 'screens/patient/patient_profile_screen.dart';
import 'screens/doctor/doctor_dashboard_screen.dart';
import 'screens/doctor/doctor_profile_edit_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_doctors_screen.dart';
import 'screens/admin/admin_patients_screen.dart';
import 'screens/admin/admin_appointments_screen.dart';
import 'screens/admin/admin_payments_screen.dart';
import 'screens/common/splash_screen.dart';
import 'screens/common/notifications_screen.dart';
import 'screens/common/video_call_screen.dart';
import 'screens/common/chat_screen.dart';
import 'screens/common/support_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isSplash = state.matchedLocation == '/splash';

      if (isSplash) return null;
      if (!isLoggedIn && !isAuthRoute) return '/auth/login';
      if (isLoggedIn && isAuthRoute) {
        final role = authState.user?.role.name;
        if (role == 'admin') return '/admin/dashboard';
        if (role == 'doctor') return '/doctor/dashboard';
        return '/patient/home';
      }
      final role = authState.user?.role.name;
      final isOnPatientRoute = state.matchedLocation.startsWith('/patient');
      final isOnDoctorRoute = state.matchedLocation.startsWith('/doctor');
      final isOnAdminRoute = state.matchedLocation.startsWith('/admin');
      if (isLoggedIn && role == 'doctor' && isOnPatientRoute) return '/doctor/dashboard';
      if (isLoggedIn && role != 'doctor' && isOnDoctorRoute) return '/patient/home';
      if (isLoggedIn && role == 'admin' && (isOnPatientRoute || isOnDoctorRoute)) {
        return '/admin/dashboard';
      }
      if (isLoggedIn && role != 'admin' && isOnAdminRoute) return '/patient/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/doctor-onboarding',
        builder: (context, state) => const DoctorOnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/reset-password',
        builder: (context, state) => ResetPasswordScreen(
          initialEmail: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: '/auth/otp-verification',
        builder: (context, state) => const OtpVerificationScreen(),
      ),
      GoRoute(
        path: '/patient/home',
        builder: (context, state) => const PatientShellScreen(initialIndex: 0),
      ),
      GoRoute(
        path: '/patient/search',
        builder: (context, state) => SearchScreen(
          initialSpecialty: state.uri.queryParameters['specialty'],
        ),
      ),
      GoRoute(
        path: '/patient/doctor/:id',
        builder: (context, state) => DoctorProfileScreen(
          doctorId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/patient/book/:doctorId',
        builder: (context, state) => BookAppointmentScreen(
          doctorId: state.pathParameters['doctorId']!,
        ),
      ),
      GoRoute(
        path: '/patient/appointments',
        builder: (context, state) => const PatientShellScreen(initialIndex: 2),
      ),
      GoRoute(
        path: '/patient/profile',
        builder: (context, state) => const PatientProfileScreen(),
      ),
      GoRoute(
        path: '/patient/appointment/:id/confirmed',
        builder: (context, state) => AppointmentConfirmationScreen(
          appointmentId: state.pathParameters['id']!,
          appointment: state.extra is AppointmentModel ? state.extra as AppointmentModel : null,
        ),
      ),
      GoRoute(
        path: '/patient/appointment/:id',
        builder: (context, state) => AppointmentDetailScreen(
          appointmentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/patient/appointment/:id/chat',
        builder: (context, state) => ChatScreen(
          appointmentId: state.pathParameters['id']!,
          title: 'Appointment Chat',
        ),
      ),
      GoRoute(
        path: '/doctor/dashboard',
        builder: (context, state) => const DoctorDashboardScreen(),
      ),
      GoRoute(
        path: '/doctor/profile/edit',
        builder: (context, state) => const DoctorProfileEditScreen(),
      ),
      GoRoute(
        path: '/doctor/appointment/:id/chat',
        builder: (context, state) => ChatScreen(
          appointmentId: state.pathParameters['id']!,
          title: 'Patient Chat',
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/doctors',
        builder: (context, state) => const AdminDoctorsScreen(),
      ),
      GoRoute(
        path: '/admin/patients',
        builder: (context, state) => const AdminPatientsScreen(),
      ),
      GoRoute(
        path: '/admin/appointments',
        builder: (context, state) => const AdminAppointmentsScreen(),
      ),
      GoRoute(
        path: '/admin/payments',
        builder: (context, state) => const AdminPaymentsScreen(),
      ),
      GoRoute(
        path: '/call/:appointmentId',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return VideoCallScreen(
            appId: extra['appId'] as String? ?? '',
            channelName: extra['channelName'] as String? ?? '',
            token: extra['token'] as String? ?? '',
            uid: extra['uid'] as int? ?? 0,
            isMock: extra['isMock'] as bool? ?? true,
            appointmentId: state.pathParameters['appointmentId']!,
          );
        },
      ),
    ],
  );

  ref.listen(authProvider, (_, __) {
    router.refresh();
  });

  return router;
});
