import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../core/network/api_client.dart';

final secureStorage = const FlutterSecureStorage();

String _extractError(dynamic e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) return data['error'];
    if (e.response?.statusCode == 0) return 'Network error. Is the backend running?';
  }
  return 'Something went wrong. Please try again.';
}

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final UserModel? user;
  final String? error;
  final bool isOtpSent;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.error,
    this.isOtpSent = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserModel? user,
    String? error,
    bool? isOtpSent,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      isOtpSent: isOtpSent ?? this.isOtpSent,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(const AuthState());

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data;
      await secureStorage.write(key: 'access_token', value: data['accessToken']);
      await secureStorage.write(key: 'refresh_token', value: data['refreshToken']);
      final user = UserModel.fromJson(data['user']);
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'patient',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiClient.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'role': role,
        },
      );
      state = state.copyWith(isLoading: false, isOtpSent: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
    }
  }

  Future<void> verifyOtp({required String email, required String otp}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.post(
        '/auth/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      final data = response.data;
      await secureStorage.write(key: 'access_token', value: data['accessToken']);
      await secureStorage.write(key: 'refresh_token', value: data['refreshToken']);
      final user = UserModel.fromJson(data['user']);
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: user,
        isOtpSent: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
    }
  }

  Future<void> resendOtp({required String email}) async {
    try {
      await _apiClient.post('/auth/resend-otp', data: {'email': email});
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (_) {}
    await secureStorage.deleteAll();
    state = const AuthState();
  }

  Future<void> checkAuth() async {
    final token = await secureStorage.read(key: 'access_token');
    if (token != null) {
      try {
        final response = await _apiClient.get('/auth/me');
        final user = UserModel.fromJson(response.data['user']);
        state = state.copyWith(isAuthenticated: true, user: user);
      } catch (_) {
        await secureStorage.deleteAll();
        state = const AuthState();
      }
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final notifier = AuthNotifier(apiClient);
  apiClient.onUnauthenticated = () => notifier.logout();
  return notifier;
});
