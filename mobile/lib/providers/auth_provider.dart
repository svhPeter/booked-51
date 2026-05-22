import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../core/network/api_client.dart';

final secureStorage = const FlutterSecureStorage();

String _extractError(dynamic e) {
  if (e is DioException) {
    if (kDebugMode) {
      debugPrint(
        'Auth request failed: type=${e.type.name}, status=${e.response?.statusCode}, path=${e.requestOptions.path}',
      );
    }
    final data = e.response?.data;
    if (data is Map) {
      final message = data['error'] ?? data['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    if (data is String && data.trim().isNotEmpty) return data;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Network error. Please check your connection and try again.';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        return status == null ? 'Request failed. Please try again.' : 'Request failed with status $status. Please try again.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed. Please try again later.';
      case DioExceptionType.cancel:
        return 'Request was cancelled. Please try again.';
      case DioExceptionType.unknown:
        return 'Network request failed. Please try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final UserModel? user;
  final String? error;
  final String? successMessage;
  final bool isOtpSent;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.error,
    this.successMessage,
    this.isOtpSent = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserModel? user,
    String? error,
    String? successMessage,
    bool? isOtpSent,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      successMessage: successMessage,
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
    required String city,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null, isOtpSent: false);
    try {
      await _apiClient.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'city': city,
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

  Future<void> registerDoctor({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String specialty,
    required String city,
    required String clinicName,
    required String consultationFee,
    String? pmdcRegistrationNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null, isOtpSent: false);
    try {
      await _apiClient.post(
        '/auth/register-doctor',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'specialty': specialty,
          'city': city,
          'clinicName': clinicName,
          'consultationFee': consultationFee,
          'pmdcRegistrationNumber': pmdcRegistrationNumber,
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

  Future<bool> resendOtp({required String email}) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      final response = await _apiClient.post('/auth/resend-otp', data: {'email': email});
      state = state.copyWith(
        isLoading: false,
        successMessage: response.data['message'] ?? 'OTP resent successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  Future<bool> forgotPassword({required String email}) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      final response = await _apiClient.post('/auth/forgot-password', data: {'email': email});
      state = state.copyWith(
        isLoading: false,
        successMessage: response.data['message'] ?? 'If an account exists, a reset code has been sent.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      final response = await _apiClient.post(
        '/auth/reset-password',
        data: {
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        },
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: response.data['message'] ?? 'Password reset successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
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

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final notifier = AuthNotifier(apiClient);
  apiClient.onUnauthenticated = () => notifier.logout();
  return notifier;
});
