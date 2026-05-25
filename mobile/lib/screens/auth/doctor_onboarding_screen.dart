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

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).clearMessages());
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
          pmdcRegistrationNumber: _pmdcController.text.trim().isEmpty ? null : _pmdcController.text.trim(),
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
                _sectionLabel('Professional Information'),
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
                _sectionLabel('Practice Details'),
                const SizedBox(height: 10),
                _field(_cityController, 'City', Icons.location_on_outlined, hint: 'Karachi'),
                _field(_clinicController, 'Clinic / Hospital name', Icons.local_hospital_outlined,
                    hint: 'City Hospital'),
                _field(_feeController, 'Consultation fee (PKR)', Icons.payments_outlined,
                    hint: '1500', keyboardType: TextInputType.number,
                    helper: 'Informational only — patients pay you directly'),
                _field(_pmdcController, 'PMDC registration number', Icons.badge_outlined,
                    hint: 'Optional', required: false),

                // Security
                _sectionLabel('Account Security'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText: 'At least 8 characters',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter a password';
                    if (v.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),
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
                  backgroundColor: AppColors.accent,
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

  Widget _sectionLabel(String text) {
    final t = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Text(text, style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: t.onSurfaceVariant,
        letterSpacing: 0.5,
      )),
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
