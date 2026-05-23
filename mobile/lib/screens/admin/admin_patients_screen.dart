import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../models/admin_models.dart';
import '../../widgets/ui_components.dart';

class AdminPatientsScreen extends ConsumerStatefulWidget {
  const AdminPatientsScreen({super.key});

  @override
  ConsumerState<AdminPatientsScreen> createState() => _AdminPatientsScreenState();
}

class _AdminPatientsScreenState extends ConsumerState<AdminPatientsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).fetchPatients());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All Patients')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminProvider.notifier).fetchPatients(),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(AdminState state) {
    if (state.isLoading && state.patients.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.patients.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.error_outline_rounded,
        title: 'Failed to load patients',
        subtitle: state.error,
        actionLabel: 'Retry',
        onAction: () => ref.read(adminProvider.notifier).fetchPatients(),
      );
    }
    if (state.patients.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.people_outline,
        title: 'No patients found',
        subtitle: 'Patients who sign up will appear here',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.patients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final pat = state.patients[index];
        return _PatientCard(patient: pat);
      },
    );
  }
}

class _PatientCard extends ConsumerWidget {
  final AdminPatient patient;
  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showPatientDetail(context, ref, patient),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.secondarySurface,
              child: Text(
                patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(patient.email, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ],
              ),
            ),
            if (!patient.isActive)
              const StatusBadge(label: 'Inactive', color: AppColors.error, icon: Icons.block)
            else if (patient.isVerified)
              const StatusBadge(label: 'Verified', color: AppColors.secondary, icon: Icons.verified_user),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

void _showPatientDetail(BuildContext context, WidgetRef ref, AdminPatient patient) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.secondarySurface,
                  child: Text(
                    patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 28, color: AppColors.secondary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: Text(patient.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
              const SizedBox(height: 4),
              Center(child: Text(patient.email, style: const TextStyle(color: AppColors.textTertiary, fontSize: 13))),
              Center(child: Text(patient.phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StatusBadge(
                      label: patient.isActive ? 'Active' : 'Inactive',
                      color: patient.isActive ? AppColors.online : AppColors.error,
                      icon: patient.isActive ? Icons.check_circle : Icons.block,
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: patient.isVerified ? 'Verified' : 'Unverified',
                      color: patient.isVerified ? AppColors.secondary : AppColors.warning,
                      icon: patient.isVerified ? Icons.verified_user : Icons.schedule,
                    ),
                  ],
                ),
              ),
              const Divider(height: 32),
              _detailRow('Gender', patient.gender.isNotEmpty ? patient.gender : 'N/A'),
              _detailRow('Blood Group', patient.bloodGroup.isNotEmpty ? patient.bloodGroup : 'N/A'),
              _detailRow('DOB', patient.dob ?? 'N/A'),
            ],
          ),
        );
      },
    ),
  );
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textTertiary, fontSize: 13)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    ),
  );
}
