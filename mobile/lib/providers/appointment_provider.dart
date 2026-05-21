import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment.dart';
import '../core/network/api_client.dart';

String _extractError(dynamic e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) return data['error'];
  }
  return 'Something went wrong. Please try again.';
}

class AppointmentState {
  final List<AppointmentModel> appointments;
  final bool isLoading;
  final String? error;
  final bool bookingSuccess;
  final List<String> availableSlots;
  final AppointmentModel? lastBookedAppointment;

  const AppointmentState({
    this.appointments = const [],
    this.isLoading = false,
    this.error,
    this.bookingSuccess = false,
    this.availableSlots = const [],
    this.lastBookedAppointment,
  });

  AppointmentState copyWith({
    List<AppointmentModel>? appointments,
    bool? isLoading,
    String? error,
    bool? bookingSuccess,
    List<String>? availableSlots,
    AppointmentModel? lastBookedAppointment,
  }) {
    return AppointmentState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      bookingSuccess: bookingSuccess ?? this.bookingSuccess,
      availableSlots: availableSlots ?? this.availableSlots,
      lastBookedAppointment: lastBookedAppointment ?? this.lastBookedAppointment,
    );
  }
}

class AppointmentNotifier extends StateNotifier<AppointmentState> {
  final ApiClient _apiClient;

  AppointmentNotifier(this._apiClient) : super(const AppointmentState());

  Future<void> fetchMyAppointments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get('/appointments/my');
      final List<dynamic> data = response.data['appointments'] ?? response.data;
      state = state.copyWith(
        appointments: data.map((e) => AppointmentModel.fromJson(e)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> fetchAvailableSlots(String doctorId, DateTime date) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await _apiClient.get(
        '/doctors/$doctorId/slots',
        query: {'date': dateStr},
      );
      final List<dynamic> data = response.data['slots'] ?? [];
      state = state.copyWith(availableSlots: data.map((e) => e.toString()).toList());
    } catch (_) {
      state = state.copyWith(error: 'Failed to load available slots');
    }
  }

  Future<void> bookAppointment({
    required String doctorId,
    required DateTime date,
    required String timeSlot,
    String? hospitalId,
  }) async {
    state = state.copyWith(isLoading: true, error: null, bookingSuccess: false);
    try {
      final response = await _apiClient.post(
        '/appointments',
        data: {
          'doctorId': doctorId,
          'date': date.toIso8601String(),
          'timeSlot': timeSlot,
          'hospitalId': hospitalId,
        },
      );
      final data = response.data;
      final appointment = AppointmentModel.fromJson(data is Map ? data['appointment'] ?? data : data);
      state = state.copyWith(
        isLoading: false,
        bookingSuccess: true,
        lastBookedAppointment: appointment,
      );
      fetchMyAppointments();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
    }
  }

  Future<AppointmentModel?> fetchAppointmentById(String appointmentId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get('/appointments/$appointmentId');
      final data = response.data['appointment'] ?? response.data;
      final appointment = AppointmentModel.fromJson(Map<String, dynamic>.from(data));
      state = state.copyWith(isLoading: false);
      return appointment;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return null;
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiClient.put('/appointments/$appointmentId/cancel');
      await fetchMyAppointments();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  void resetBookingState() {
    state = state.copyWith(bookingSuccess: false, error: null);
  }
}

final appointmentProvider =
    StateNotifierProvider<AppointmentNotifier, AppointmentState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AppointmentNotifier(apiClient);
});
