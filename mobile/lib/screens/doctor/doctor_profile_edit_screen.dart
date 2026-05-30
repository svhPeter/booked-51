import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/ui_components.dart';

class DoctorProfileEditScreen extends ConsumerStatefulWidget {
  const DoctorProfileEditScreen({super.key});

  @override
  ConsumerState<DoctorProfileEditScreen> createState() =>
      _DoctorProfileEditScreenState();
}

class _DoctorProfileEditScreenState extends ConsumerState<DoctorProfileEditScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _bioController = TextEditingController();
  final _feeController = TextEditingController();
  final _daysController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileProvider.notifier).fetchDoctorProfile());
  }

  void _fill(Map<String, dynamic>? p) {
    if (p == null) return;
    _nameController.text = p['name'] ?? '';
    _phoneController.text = p['phone'] ?? '';
    _specialtyController.text = p['specialty'] ?? '';
    _qualificationController.text = p['qualification'] ?? '';
    _bioController.text = p['bio'] ?? '';
    _feeController.text = '${p['consultationFee'] ?? 0}';
    final days = p['availableDays'] as List?;
    _daysController.text = days?.join(', ') ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _qualificationController.dispose();
    _bioController.dispose();
    _feeController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final days = _daysController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    await ref.read(profileProvider.notifier).updateDoctorProfile({
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'specialty': _specialtyController.text.trim(),
      'qualification': _qualificationController.text.trim(),
      'bio': _bioController.text.trim(),
      'consultationFee': double.tryParse(_feeController.text) ?? 0,
      'availableDays': days,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated. Fee is shown to patients as pay-at-clinic.'),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);

    ref.listen<ProfileState>(profileProvider, (prev, next) {
      if (prev?.profile == null && next.profile != null) _fill(next.profile);
    });

    if (state.profile != null && _nameController.text.isEmpty) {
      _fill(state.profile);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: state.isLoading && state.profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Professional info
                  _sectionLabel('Professional Information'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      hintText: '0300-1234567',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _specialtyController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Specialty',
                      hintText: 'e.g. Cardiologist',
                      prefixIcon: Icon(Icons.medical_services_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _qualificationController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Qualification',
                      hintText: 'e.g. MBBS, FCPS',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _sectionLabel('Practice Details'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _feeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Consultation fee (PKR)',
                      helperText: 'Patients pay you directly at the clinic',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _daysController,
                    decoration: const InputDecoration(
                      labelText: 'Available days',
                      hintText: 'Mon, Tue, Wed, Thu, Fri',
                      helperText: 'Comma-separated day abbreviations',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _sectionLabel('About You'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      hintText: 'Tell patients about yourself...',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.description_outlined),
                      ),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 28),
                  LoadingButton(
                    isLoading: state.isLoading,
                    onPressed: _save,
                    label: 'Save Profile',
                    icon: Icons.save_rounded,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textTertiary,
      letterSpacing: 0.5,
    ));
  }
}
