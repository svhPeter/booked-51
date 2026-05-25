import 'package:flutter/cupertino.dart';
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
import 'screens/common/conversations_screen.dart';

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
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/auth/register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/auth/doctor-onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DoctorOnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/auth/reset-password',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: ResetPasswordScreen(
            initialEmail: state.uri.queryParameters['email'] ?? '',
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/auth/otp-verification',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OtpVerificationScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/patient/home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PatientShellScreen(initialIndex: 0),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/patient/search',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: SearchScreen(
            initialSpecialty: state.uri.queryParameters['specialty'],
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/patient/doctor/:id',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DoctorProfileScreen(
            doctorId: state.pathParameters['id']!,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/patient/book/:doctorId',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BookAppointmentScreen(
            doctorId: state.pathParameters['doctorId']!,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/patient/appointments',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PatientShellScreen(initialIndex: 2),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/patient/profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PatientProfileScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/patient/appointment/:id/confirmed',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: AppointmentConfirmationScreen(
            appointmentId: state.pathParameters['id']!,
            appointment: state.extra is AppointmentModel ? state.extra as AppointmentModel : null,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/patient/appointment/:id',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: AppointmentDetailScreen(
            appointmentId: state.pathParameters['id']!,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/patient/appointment/:id/chat',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: ChatScreen(
            appointmentId: state.pathParameters['id']!,
            title: 'Appointment Chat',
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/doctor/dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DoctorDashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/doctor/profile/edit',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DoctorProfileEditScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/doctor/appointment/:id/chat',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: ChatScreen(
            appointmentId: state.pathParameters['id']!,
            title: 'Patient Chat',
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NotificationsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/support',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SupportScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/inbox',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ConversationsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/admin/dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminDashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/admin/doctors',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminDoctorsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/admin/patients',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminPatientsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/admin/appointments',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminAppointmentsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/admin/payments',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminPaymentsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
        ),
      ),
      GoRoute(
        path: '/call/:appointmentId',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CustomTransitionPage(
            key: state.pageKey,
            child: VideoCallScreen(
              appId: extra['appId'] as String? ?? '',
              channelName: extra['channelName'] as String? ?? '',
              token: extra['token'] as String? ?? '',
              uid: extra['uid'] as int? ?? 0,
              isMock: extra['isMock'] as bool? ?? true,
              appointmentId: state.pathParameters['appointmentId']!,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              CupertinoPageTransition(
                primaryRouteAnimation: animation,
                secondaryRouteAnimation: secondaryAnimation,
                linearTransition: false,
                child: child,
              ),
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
