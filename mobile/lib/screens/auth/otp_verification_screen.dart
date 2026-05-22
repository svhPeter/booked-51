import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/role_menu_button.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String get _email {
    final state = GoRouterState.of(context);
    return state.uri.queryParameters['email'] ?? (state.extra as String?) ?? '';
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp() {
    if (_email.isEmpty) {
      ref.read(authProvider.notifier).clearError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email is missing. Please sign up again.')),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).verifyOtp(
            email: _email,
            otp: _otpController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        context.go(homePathForRole(next.user?.role));
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/auth/register'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                const Icon(Icons.verified_user, size: 48, color: AppColors.primary),
                const SizedBox(height: 24),
                Text('Verify OTP', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 8),
                Text(
                  _email.isEmpty
                      ? 'Email is missing. Please go back and sign up again.'
                      : 'Enter the 6-digit code sent to $_email',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Verification code generated. If you do not receive email, try resend or contact support.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                ),
                const SizedBox(height: 32),
                if (authState.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, letterSpacing: 12),
                  decoration: const InputDecoration(
                    labelText: 'OTP Code',
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.length != 6) return 'Please enter the 6-digit code';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _verifyOtp,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Verify'),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Didn't receive the code?",
                        style: Theme.of(context).textTheme.bodyMedium),
                    TextButton(
                      onPressed: authState.isLoading || _email.isEmpty ? null : () async {
                        final ok = await ref.read(authProvider.notifier).resendOtp(email: _email);
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('OTP resent successfully')),
                          );
                        }
                      },
                      child: const Text('Resend'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
