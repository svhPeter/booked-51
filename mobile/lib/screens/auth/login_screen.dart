import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ui_components.dart';
import '../../widgets/docbook_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final scheme = Theme.of(context).colorScheme;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        final role = next.user?.role.name;
        if (role == 'admin') {
          context.go('/admin/dashboard');
        } else if (role == 'doctor') {
          context.go('/doctor/dashboard');
        } else {
          context.go('/patient/home');
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                // Brand header
                Center(
                  child: Column(
                    children: [
                      const DocBookLogo(size: 64, showText: false),
                      const SizedBox(height: 16),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                          children: [
                            TextSpan(text: 'Doc', style: TextStyle(color: scheme.onSurface)),
                            TextSpan(text: 'Book', style: TextStyle(color: scheme.primary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pakistan\'s free doctor appointment platform',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                if (authState.error != null)
                  MessageBanner(
                    message: authState.error!,
                    type: MessageType.error,
                  ),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter your email';
                    if (!v.contains('@')) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter your password';
                    if (v.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go('/auth/forgot-password'),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
                    child: const Text('Forgot password?', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 20),
                LoadingButton(
                  isLoading: authState.isLoading,
                  onPressed: _handleLogin,
                  label: 'Sign In',
                  icon: Icons.login_rounded,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?",
                        style: Theme.of(context).textTheme.bodyMedium),
                    TextButton(
                      onPressed: () => context.go('/auth/register'),
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Trust indicators
                const Center(
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      TrustBanner(icon: Icons.verified_user_outlined, text: 'Verified doctors'),
                      TrustBanner(icon: Icons.event_available_outlined, text: 'Free booking'),
                      TrustBanner(icon: Icons.shield_outlined, text: 'Secure & private'),
                    ],
                  ),
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
