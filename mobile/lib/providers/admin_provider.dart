import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_models.dart';
import '../core/network/api_client.dart';

String _extractError(dynamic e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) return data['error'];
  }
  return 'Something went wrong. Please try again.';
}

class AdminState {
  final AdminSummary? summary;
  final List<AdminDoctor> doctors;
  final List<AdminPatient> patients;
  final List<AdminAppointment> appointments;
  final List<AdminPayment> payments;
  final AdminDoctor? doctorDetail;
  final AdminPatient? patientDetail;
  final AdminAppointment? appointmentDetail;
  final bool isLoading;
  final String? error;

  const AdminState({
    this.summary,
    this.doctors = const [],
    this.patients = const [],
    this.appointments = const [],
    this.payments = const [],
    this.doctorDetail,
    this.patientDetail,
    this.appointmentDetail,
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    AdminSummary? summary,
    List<AdminDoctor>? doctors,
    List<AdminPatient>? patients,
    List<AdminAppointment>? appointments,
    List<AdminPayment>? payments,
    AdminDoctor? doctorDetail,
    AdminPatient? patientDetail,
    AdminAppointment? appointmentDetail,
    bool? isLoading,
    String? error,
  }) {
    return AdminState(
      summary: summary ?? this.summary,
      doctors: doctors ?? this.doctors,
      patients: patients ?? this.patients,
      appointments: appointments ?? this.appointments,
      payments: payments ?? this.payments,
      doctorDetail: doctorDetail ?? this.doctorDetail,
      patientDetail: patientDetail ?? this.patientDetail,
      appointmentDetail: appointmentDetail ?? this.appointmentDetail,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  final ApiClient _apiClient;

  AdminNotifier(this._apiClient) : super(const AdminState());

  Future<void> fetchSummary() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get('/admin/dashboard/summary');
      final summary = AdminSummary.fromJson(response.data['summary']);
      state = state.copyWith(summary: summary, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> fetchDoctors() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get('/admin/doctors');
      final List<dynamic> data = response.data['doctors'] ?? [];
      state = state.copyWith(
        doctors: data.map((e) => AdminDoctor.fromJson(e)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> fetchDoctorDetail(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get('/admin/doctors/$id');
      final doctor = AdminDoctor.fromJson(response.data['doctor']);
      state = state.copyWith(doctorDetail: doctor, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> fetchPatients() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get('/admin/patients');
      final List<dynamic> data = response.data['patients'] ?? [];
      state = state.copyWith(
        patients: data.map((e) => AdminPatient.fromJson(e)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> fetchPatientDetail(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get('/admin/patients/$id');
      final patient = AdminPatient.fromJson(response.data['patient']);
      state = state.copyWith(patientDetail: patient, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> fetchAppointments({String? status, String? doctorId, String? dateFrom, String? dateTo}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = <String, dynamic>{};
      if (status != null) params['status'] = status;
      if (doctorId != null) params['doctorId'] = doctorId;
      if (dateFrom != null) params['dateFrom'] = dateFrom;
      if (dateTo != null) params['dateTo'] = dateTo;
      final response = await _apiClient.get('/admin/appointments', query: params);
      final List<dynamic> data = response.data['appointments'] ?? [];
      state = state.copyWith(
        appointments: data.map((e) => AdminAppointment.fromJson(e)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> fetchAppointmentDetail(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get('/admin/appointments/$id');
      final appointment = AdminAppointment.fromJson(response.data['appointment']);
      state = state.copyWith(appointmentDetail: appointment, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> fetchPayments({String? status, String? provider}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = <String, dynamic>{};
      if (status != null) params['status'] = status;
      if (provider != null) params['provider'] = provider;
      final response = await _apiClient.get('/admin/payments', query: params);
      final List<dynamic> data = response.data['payments'] ?? [];
      state = state.copyWith(
        payments: data.map((e) => AdminPayment.fromJson(e)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminNotifier(apiClient);
});
