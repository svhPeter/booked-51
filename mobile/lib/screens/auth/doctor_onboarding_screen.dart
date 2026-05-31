import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ui_components.dart';

class DoctorOnboardingScreen extends ConsumerStatefulWidget {
  const DoctorOnboardingScreen({super.key});

  @override
  ConsumerState<DoctorOnboardingScreen> createState() => _DoctorOnboardingScreenState();
}

class _DoctorOnboardingScreenState extends ConsumerState<DoctorOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _cityController = TextEditingController();
  final _clinicController = TextEditingController();
  final _feeController = TextEditingController();
  final _pmdcController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _password = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).clearMessages());
    _passwordController.addListener(() {
      setState(() => _password = _passwordController.text);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _cityController.dispose();
    _clinicController.dispose();
    _feeController.dispose();
    _pmdcController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int get _passwordStrength {
    int score = 0;
    if (_password.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(_password)) score++;
    if (RegExp(r'[a-z]').hasMatch(_password)) score++;
    if (RegExp(r'[0-9]').hasMatch(_password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(_password)) score++;
    return score;
  }

  String get _strengthLabel {
    final s = _passwordStrength;
    if (_password.isEmpty) return '';
    if (s < 3) return 'Weak';
    if (s < 5) return 'Medium';
    return 'Strong';
  }

  Color _strengthColor(BuildContext context) {
    final s = _passwordStrength;
    if (_password.isEmpty) return Colors.transparent;
    if (s < 3) return Theme.of(context).colorScheme.error;
    if (s < 5) return context.warningColor;
    return context.successColor;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).registerDoctor(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          specialty: _specialtyController.text.trim(),
          city: _cityController.text.trim(),
          clinicName: _clinicController.text.trim(),
          consultationFee: _feeController.text.trim(),
          pmdcRegistrationNumber: _pmdcController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isOtpSent) {
        final email = _emailController.text.trim();
        context.go('/auth/otp-verification?email=${Uri.encodeComponent(email)}', extra: email);
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.medical_information_rounded, size: 24, color: AppColors.accent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Doctor Onboarding', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 2),
                          Text(
                            'Join the DocBook network',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const MessageBanner(
                  message: 'Your profile will be reviewed by our admin team before patients can see you. This usually takes 1–2 business days.',
                  type: MessageType.info,
                ),
                if (authState.error != null)
                  MessageBanner(message: authState.error!, type: MessageType.error),

                // Professional info
                const StitchFormSection(label: 'Professional Information'),
                const SizedBox(height: 10),
                _field(_nameController, 'Full name', Icons.person_outlined, hint: 'Dr. Ahmed Khan'),
                _field(_emailController, 'Email address', Icons.email_outlined,
                    hint: 'doctor@example.com', keyboardType: TextInputType.emailAddress,
                    helper: 'We will send a verification code to this email'),
                _field(_phoneController, 'Phone number', Icons.phone_outlined,
                    hint: '0300-1234567', keyboardType: TextInputType.phone),
                _field(_specialtyController, 'Specialty', Icons.medical_services_outlined,
                    hint: 'e.g. Cardiologist, Dermatologist'),

                // Practice info
                const StitchFormSection(label: 'Practice Details'),
                const SizedBox(height: 10),
                _field(_cityController, 'City', Icons.location_on_outlined, hint: 'Karachi'),
                _field(_clinicController, 'Clinic / Hospital name', Icons.local_hospital_outlined,
                    hint: 'City Hospital'),
                _field(_feeController, 'Consultation fee (PKR)', Icons.payments_outlined,
                    hint: '1500', keyboardType: TextInputType.number,
                    helper: 'Informational only — patients pay you directly'),
                _field(_pmdcController, 'PMDC registration number', Icons.badge_outlined,
                    hint: 'e.g. 12345-P'),

                // Security
                const StitchFormSection(label: 'Account Security'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText: 'Min 10 chars with upper, lower, number & symbol',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter a password';
                    if (v.length < 10) return 'Password must be at least 10 characters';
                    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Must include an uppercase letter';
                    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Must include a lowercase letter';
                    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Must include a number';
                    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(v)) return 'Must include a symbol';
                    return null;
                  },
                ),
                if (_password.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _passwordStrength / 5,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      color: _strengthColor(context),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _strengthLabel,
                      style: TextStyle(fontSize: 11, color: _strengthColor(context), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 28),
                LoadingButton(
                  isLoading: authState.isLoading,
                  onPressed: _submit,
                  label: 'Submit for Approval',
                  icon: Icons.send_rounded,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Not a doctor?', style: Theme.of(context).textTheme.bodyMedium),
                      TextButton(
                        onPressed: () => context.go('/auth/register'),
                        child: const Text('Sign up as patient'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    String? helper,
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        textCapitalization: keyboardType == TextInputType.text ? TextCapitalization.words : TextCapitalization.none,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
          prefixIcon: Icon(icon),
        ),
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) return 'Please enter ${label.toLowerCase()}';
          if (label.contains('Email') && v != null && v.isNotEmpty && !v.contains('@')) return 'Please enter a valid email';
          return null;
        },
      ),
    );
  }
}
