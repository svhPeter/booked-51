import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/ui_components.dart';

class PatientProfileScreen extends ConsumerStatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  ConsumerState<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends ConsumerState<PatientProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  String? _gender;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileProvider.notifier).fetchPatientProfile());
  }

  void _fillFromProfile(Map<String, dynamic>? p) {
    if (p == null) return;
    _nameController.text = p['name'] ?? '';
    _phoneController.text = p['phone'] ?? '';
    _cityController.text = p['city'] ?? '';
    _addressController.text = p['address'] ?? '';
    _gender = p['gender'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(profileProvider.notifier).updatePatientProfile({
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'city': _cityController.text.trim(),
      'address': _addressController.text.trim(),
      if (_gender != null) 'gender': _gender,
    });
    final authUser = ref.read(authProvider).user;
    if (authUser != null && mounted) {
      await ref.read(authProvider.notifier).checkAuth();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: context.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final authState = ref.watch(authProvider);
    final currentTheme = ref.watch(themeModeProvider);
    final email = authState.user?.email ?? '';
    final initials = (authState.user?.name ?? '?')[0].toUpperCase();

    ref.listen<ProfileState>(profileProvider, (prev, next) {
      if (prev?.profile == null && next.profile != null) {
        _fillFromProfile(next.profile);
      }
    });

    if (profileState.profile != null && _nameController.text.isEmpty) {
      _fillFromProfile(profileState.profile);
    }

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: profileState.isLoading && profileState.profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Avatar header
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: scheme.primary,
                    child: Text(
                      initials,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: scheme.onPrimary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (email.isNotEmpty)
                    Text(email, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 24),

                  // Personal information section
                  _sectionLabel('Personal Information'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      hintText: '0300-1234567',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(Icons.wc_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  ),

                  const SizedBox(height: 24),
                  _sectionLabel('Location'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cityController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      hintText: 'Karachi',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      hintText: 'Your full address',
                      prefixIcon: Icon(Icons.home_outlined),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  LoadingButton(
                    isLoading: profileState.isLoading,
                    onPressed: _save,
                    label: 'Save Profile',
                    icon: Icons.save_rounded,
                  ),
                  const SizedBox(height: 32),
                  Divider(color: context.dividerColor),
                  const SizedBox(height: 16),

                  // Appearance section
                  _sectionLabel('Appearance'),
                  const SizedBox(height: 12),
                  _ThemeOption(
                    title: 'System default',
                    subtitle: 'Follow your device theme',
                    icon: Icons.settings_suggest_outlined,
                    selected: currentTheme == ThemeMode.system,
                    onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                  ),
                  _ThemeOption(
                    title: 'Light',
                    subtitle: 'Always use light mode',
                    icon: Icons.light_mode_outlined,
                    selected: currentTheme == ThemeMode.light,
                    onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                  ),
                  _ThemeOption(
                    title: 'Dark',
                    subtitle: 'Always use dark mode',
                    icon: Icons.dark_mode_outlined,
                    selected: currentTheme == ThemeMode.dark,
                    onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: context.dividerColor),
                  const SizedBox(height: 16),

                  // Support section
                  _sectionLabel('Support & Help'),
                  const SizedBox(height: 12),
                  _SupportTile(
                    icon: Icons.email_outlined,
                    title: 'Email Support',
                    subtitle: 'support@docbook.pk',
                    onTap: () {},
                  ),
                  _SupportTile(
                    icon: Icons.chat_outlined,
                    title: 'WhatsApp Support',
                    subtitle: 'Chat with us on WhatsApp',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  Divider(color: context.dividerColor),
                  const SizedBox(height: 16),

                  // Legal section
                  _sectionLabel('Legal'),
                  const SizedBox(height: 12),
                  _SupportTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => context.push('/support'),
                  ),
                  _SupportTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () => context.push('/support'),
                  ),
                  _SupportTile(
                    icon: Icons.medical_information_outlined,
                    title: 'Medical Disclaimer',
                    onTap: () => context.push('/support'),
                  ),
                  const SizedBox(height: 16),
                  // Disclaimer banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.warningSurfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.warningColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 18, color: context.warningColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'DocBook is a booking platform, not a medical emergency service. For emergencies, contact your nearest hospital.',
                            style: TextStyle(fontSize: 11, color: context.textSecondaryColor, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: context.textTertiaryColor,
        letterSpacing: 0.5,
      )),
    );
  }
}

class _ThemeOption extends ConsumerWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: scheme.primary, size: 20)
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.outlineVariant, width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SupportTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: Icon(icon, color: scheme.primary, size: 22),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onSurface)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))
          : null,
      trailing: Icon(Icons.chevron_right, size: 20, color: scheme.onSurfaceVariant),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
