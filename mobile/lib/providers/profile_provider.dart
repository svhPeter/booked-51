import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';

String _extractError(dynamic e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) return data['error'];
  }
  return 'Something went wrong. Please try again.';
}

class ProfileState {
  final Map<String, dynamic>? profile;
  final bool isLoading;
  final String? error;
  final bool saveSuccess;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
    this.saveSuccess = false,
  });

  ProfileState copyWith({
    Map<String, dynamic>? profile,
    bool? isLoading,
    String? error,
    bool? saveSuccess,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      saveSuccess: saveSuccess ?? this.saveSuccess,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ApiClient _apiClient;

  ProfileNotifier(this._apiClient) : super(const ProfileState());

  Future<void> fetchPatientProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiClient.get('/patients/me');
      state = state.copyWith(
        isLoading: false,
        profile: Map<String, dynamic>.from(res.data['profile'] ?? res.data),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> updatePatientProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null, saveSuccess: false);
    try {
      final res = await _apiClient.put('/patients/me', data: data);
      state = state.copyWith(
        isLoading: false,
        saveSuccess: true,
        profile: Map<String, dynamic>.from(res.data['profile'] ?? res.data),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> fetchDoctorProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiClient.get('/doctor/profile');
      state = state.copyWith(
        isLoading: false,
        profile: Map<String, dynamic>.from(res.data['profile'] ?? res.data),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> updateDoctorProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null, saveSuccess: false);
    try {
      final res = await _apiClient.put('/doctor/profile', data: data);
      state = state.copyWith(
        isLoading: false,
        saveSuccess: true,
        profile: Map<String, dynamic>.from(res.data['profile'] ?? res.data),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref.watch(apiClientProvider));
});
