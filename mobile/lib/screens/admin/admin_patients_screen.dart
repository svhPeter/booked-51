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
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _showPatientDetail(context, ref, patient),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant, width: 0.5),
          boxShadow: context.isDarkMode ? AppShadows.darkSm : AppShadows.sm,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: context.secondarySurfaceColor,
              child: Text(
                patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                style: TextStyle(color: scheme.secondary, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: scheme.onSurface)),
                  const SizedBox(height: 2),
                  Text(patient.email, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (!patient.isActive)
              StatusBadge(label: 'Inactive', color: scheme.error, icon: Icons.block)
            else if (patient.isVerified)
              StatusBadge(label: 'Verified', color: scheme.secondary, icon: Icons.verified_user),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

void _showPatientDetail(BuildContext context, WidgetRef ref, AdminPatient patient) {
  final scheme = Theme.of(context).colorScheme;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: context.secondarySurfaceColor,
                  child: Text(
                    patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 28, color: scheme.secondary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: Text(patient.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: scheme.onSurface))),
              const SizedBox(height: 4),
              Center(child: Text(patient.email, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13))),
              Center(child: Text(patient.phone, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13))),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StatusBadge(
                      label: patient.isActive ? 'Active' : 'Inactive',
                      color: patient.isActive ? AppColors.online : scheme.error,
                      icon: patient.isActive ? Icons.check_circle : Icons.block,
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: patient.isVerified ? 'Verified' : 'Unverified',
                      color: patient.isVerified ? scheme.secondary : context.warningColor,
                      icon: patient.isVerified ? Icons.verified_user : Icons.schedule,
                    ),
                  ],
                ),
              ),
              Divider(height: 32, color: context.dividerColor),
              DetailRow(label: 'Gender', value: patient.gender.isNotEmpty ? patient.gender : 'N/A'),
              DetailRow(label: 'Blood Group', value: patient.bloodGroup.isNotEmpty ? patient.bloodGroup : 'N/A'),
              DetailRow(label: 'DOB', value: patient.dob ?? 'N/A'),
            ],
          ),
        );
      },
    ),
  );
}

