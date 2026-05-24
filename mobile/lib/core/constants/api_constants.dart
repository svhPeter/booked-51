class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );
  static const bool enableVoiceNotes = false;
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String doctors = '/doctors';
  static const String doctorById = '/doctors/';
  static const String searchDoctors = '/doctors/search';
  static const String specialties = '/doctors/specialties';
  static const String appointments = '/appointments';
  static const String bookAppointment = '/appointments';
  static const String cancelAppointment = '/appointments/';
  static const String myAppointments = '/appointments/my';
  static const String patientProfile = '/patients/profile';
  static const String doctorProfile = '/doctors/profile';
  static const String reviews = '/reviews';
  static const String prescriptions = '/prescriptions';
  static const String notifications = '/notifications';
  static const String payments = '/payments';
  static const String createPayment = '/payments/create';
  static const String mockPaymentSuccess = '/payments/mock-success';
  static const String paymentStatus = '/payments/status';
  static const String uploadFile = '/upload';
  static const String users = '/users';
  static const String availableSlots = '/doctors/';
}
