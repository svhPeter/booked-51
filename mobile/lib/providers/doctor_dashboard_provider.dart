import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/doctor_appointment.dart';
import '../core/network/api_client.dart';

String _extractError(dynamic e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) return data['error'];
  }
  return 'Something went wrong. Please try again.';
}

class DoctorDashboardState {
  final DashboardSummary? summary;
  final List<DoctorAppointmentModel> appointments;
  final bool isLoading;
  final String? error;
  final bool actionSuccess;

  const DoctorDashboardState({
    this.summary,
    this.appointments = const [],
    this.isLoading = false,
    this.error,
    this.actionSuccess = false,
  });

  DoctorDashboardState copyWith({
    DashboardSummary? summary,
    List<DoctorAppointmentModel>? appointments,
    bool? isLoading,
    String? error,
    bool? actionSuccess,
  }) {
    return DoctorDashboardState(
      summary: summary ?? this.summary,
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      actionSuccess: actionSuccess ?? this.actionSuccess,
    );
  }
}

class DoctorDashboardNotifier extends StateNotifier<DoctorDashboardState> {
  final ApiClient _apiClient;

  DoctorDashboardNotifier(this._apiClient) : super(const DoctorDashboardState());

  Future<void> fetchSummary() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get('/doctor/dashboard/summary');
      final summary = DashboardSummary.fromJson(response.data['summary']);
      state = state.copyWith(summary: summary, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> fetchAppointments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get('/doctor/appointments');
      final List<dynamic> data = response.data['appointments'] ?? [];
      state = state.copyWith(
        appointments: data.map((e) => DoctorAppointmentModel.fromJson(e)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> completeAppointment(String appointmentId) async {
    state = state.copyWith(isLoading: true, error: null, actionSuccess: false);
    try {
      await _apiClient.put('/doctor/appointments/$appointmentId/complete');
      state = state.copyWith(isLoading: false, actionSuccess: true);
      await fetchAppointments();
      await fetchSummary();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    state = state.copyWith(isLoading: true, error: null, actionSuccess: false);
    try {
      await _apiClient.put('/doctor/appointments/$appointmentId/cancel');
      state = state.copyWith(isLoading: false, actionSuccess: true);
      await fetchAppointments();
      await fetchSummary();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> confirmAppointment(String appointmentId, DateTime date, String timeSlot) async {
    state = state.copyWith(isLoading: true, error: null, actionSuccess: false);
    try {
      await _apiClient.put(
        '/doctor/appointments/$appointmentId/confirm',
        data: {
          'date': date.toIso8601String(),
          'timeSlot': timeSlot,
        },
      );
      state = state.copyWith(isLoading: false, actionSuccess: true);
      await fetchAppointments();
      await fetchSummary();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  void resetActionState() {
    state = state.copyWith(actionSuccess: false, error: null);
  }
}

final doctorDashboardProvider =
    StateNotifierProvider<DoctorDashboardNotifier, DoctorDashboardState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DoctorDashboardNotifier(apiClient);
});
