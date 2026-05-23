import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/role_menu_button.dart';
import '../../widgets/ui_components.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _resendCooldown = 0;
  Timer? _timer;
  bool _resendSuccess = false;

  String get _email {
    final state = GoRouterState.of(context);
    return state.uri.queryParameters['email'] ?? (state.extra as String?) ?? '';
  }

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    setState(() {
      _resendCooldown = 60;
      _resendSuccess = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _resendCooldown--);
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
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

  Future<void> _handleResend() async {
    if (_email.isEmpty || _resendCooldown > 0) return;
    final ok = await ref.read(authProvider.notifier).resendOtp(email: _email);
    if (ok && mounted) {
      _startCooldown();
      setState(() => _resendSuccess = true);
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
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/auth/register'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.mark_email_read_rounded, size: 36, color: AppColors.primary),
                ),
                const SizedBox(height: 24),
                Text('Verify your email', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 8),
                if (_email.isNotEmpty) ...[
                  Text(
                    'Enter the 6-digit code sent to',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _email,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ] else
                  const Text(
                    'Email is missing. Please go back and sign up again.',
                    style: TextStyle(color: AppColors.error, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 8),
                Text(
                  'Check your inbox and spam folder',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                if (_resendSuccess)
                  const MessageBanner(
                    message: 'A new verification code has been sent to your email.',
                    type: MessageType.success,
                  ),
                if (authState.error != null)
                  MessageBanner(message: authState.error!, type: MessageType.error),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _verifyOtp(),
                  style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: '••••••',
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(vertical: 18),
                  ),
                  validator: (v) {
                    if (v == null || v.length != 6) return 'Please enter the 6-digit code';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                LoadingButton(
                  isLoading: authState.isLoading,
                  onPressed: _verifyOtp,
                  label: 'Verify & Continue',
                  icon: Icons.verified_rounded,
                ),
                const SizedBox(height: 24),
                // Resend section
                Column(
                  children: [
                    Text(
                      "Didn't receive the code?",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    if (_resendCooldown > 0)
                      Text(
                        'Resend available in ${_resendCooldown}s',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: authState.isLoading || _email.isEmpty ? null : _handleResend,
                        child: const Text('Resend Code'),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
