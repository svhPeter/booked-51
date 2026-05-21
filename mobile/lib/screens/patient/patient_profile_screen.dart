import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

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
      // refresh display name on home
      await ref.read(authProvider.notifier).checkAuth();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), backgroundColor: AppColors.secondary),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    ref.listen<ProfileState>(profileProvider, (prev, next) {
      if (prev?.profile == null && next.profile != null) {
        _fillFromProfile(next.profile);
      }
    });

    if (profileState.profile != null && _nameController.text.isEmpty) {
      _fillFromProfile(profileState.profile);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: profileState.isLoading && profileState.profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: profileState.isLoading ? null : _save,
                      child: profileState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Profile'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
