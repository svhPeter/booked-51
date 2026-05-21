import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment.dart';
import '../core/network/api_client.dart';

String _extractError(dynamic e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) return data['error'];
  }
  return 'Something went wrong. Please try again.';
}

class PaymentState {
  final PaymentModel? payment;
  final bool isLoading;
  final String? error;
  final bool paymentSuccess;
  final String selectedProvider;

  const PaymentState({
    this.payment,
    this.isLoading = false,
    this.error,
    this.paymentSuccess = false,
    this.selectedProvider = 'mock',
  });

  PaymentState copyWith({
    PaymentModel? payment,
    bool? isLoading,
    String? error,
    bool? paymentSuccess,
    String? selectedProvider,
  }) {
    return PaymentState(
      payment: payment ?? this.payment,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      paymentSuccess: paymentSuccess ?? this.paymentSuccess,
      selectedProvider: selectedProvider ?? this.selectedProvider,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final ApiClient _apiClient;

  PaymentNotifier(this._apiClient) : super(const PaymentState());

  void setProvider(String provider) {
    state = state.copyWith(selectedProvider: provider);
  }

  Future<void> createPayment({
    required String appointmentId,
    required String provider,
  }) async {
    state = state.copyWith(isLoading: true, error: null, paymentSuccess: false);
    try {
      final response = await _apiClient.post('/payments/create', data: {
        'appointmentId': appointmentId,
        'provider': provider,
      });
      final payment = PaymentModel.fromJson(response.data['payment']);
      state = state.copyWith(
        payment: payment,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
    }
  }

  Future<void> mockPaymentSuccess(String paymentId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiClient.post('/payments/mock-success', data: {
        'paymentId': paymentId,
      });
      state = state.copyWith(
        isLoading: false,
        paymentSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
    }
  }

  Future<void> fetchPaymentStatus(String appointmentId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get('/payments/status/$appointmentId');
      if (response.data['payment'] != null) {
        final payment = PaymentModel.fromJson(response.data['payment']);
        state = state.copyWith(payment: payment, isLoading: false);
      } else {
        state = state.copyWith(payment: null, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  void reset() {
    state = const PaymentState();
  }
}

final paymentProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PaymentNotifier(apiClient);
});
