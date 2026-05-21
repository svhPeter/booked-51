import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/profile_provider.dart';

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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Display name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _specialtyController,
                    decoration: const InputDecoration(labelText: 'Specialty'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _qualificationController,
                    decoration: const InputDecoration(labelText: 'Qualification'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _feeController,
                    decoration: const InputDecoration(
                      labelText: 'Consultation fee (PKR, pay at clinic)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _daysController,
                    decoration: const InputDecoration(
                      labelText: 'Available days (Mon, Tue, ...)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(labelText: 'Bio'),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : _save,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
