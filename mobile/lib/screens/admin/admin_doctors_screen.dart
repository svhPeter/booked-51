import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../models/admin_models.dart';
import '../../widgets/ui_components.dart';

class AdminDoctorsScreen extends ConsumerStatefulWidget {
  const AdminDoctorsScreen({super.key});

  @override
  ConsumerState<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

class _AdminDoctorsScreenState extends ConsumerState<AdminDoctorsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).fetchDoctors());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All Doctors')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminProvider.notifier).fetchDoctors(),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(AdminState state) {
    if (state.isLoading && state.doctors.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.doctors.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.error_outline_rounded,
        title: 'Failed to load doctors',
        subtitle: state.error,
        actionLabel: 'Retry',
        onAction: () => ref.read(adminProvider.notifier).fetchDoctors(),
      );
    }
    if (state.doctors.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.medical_services_outlined,
        title: 'No doctors found',
        subtitle: 'Doctors who sign up will appear here',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.doctors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final doc = state.doctors[index];
        return _DoctorCard(doc: doc);
      },
    );
  }
}

class _DoctorCard extends ConsumerWidget {
  final AdminDoctor doc;
  const _DoctorCard({required this.doc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showDoctorDetail(context, ref, doc),
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
              backgroundColor: AppColors.primarySurface,
              child: Text(
                doc.name.isNotEmpty ? doc.name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    '${doc.specialty}  •  Rs ${doc.consultationFee.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!doc.isApproved)
              const StatusBadge(label: 'Pending', color: AppColors.warning, icon: Icons.schedule)
            else if (!doc.isActive)
              const StatusBadge(label: 'Inactive', color: AppColors.error, icon: Icons.block)
            else
              const StatusBadge(label: 'Approved', color: AppColors.secondary, icon: Icons.verified),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

void _showDoctorDetail(BuildContext context, WidgetRef ref, AdminDoctor doc) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
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
                  backgroundColor: AppColors.primarySurface,
                  child: Text(
                    doc.name.isNotEmpty ? doc.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 28, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: Text(doc.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
              const SizedBox(height: 4),
              Center(child: Text(doc.email, style: const TextStyle(color: AppColors.textTertiary, fontSize: 13))),
              Center(child: Text(doc.phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (doc.isApproved)
                      const StatusBadge(label: 'Approved', color: AppColors.secondary, icon: Icons.verified)
                    else
                      const StatusBadge(label: 'Pending', color: AppColors.warning, icon: Icons.schedule),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: doc.isActive ? 'Active' : 'Inactive',
                      color: doc.isActive ? AppColors.online : AppColors.error,
                      icon: doc.isActive ? Icons.check_circle : Icons.block,
                    ),
                  ],
                ),
              ),
              const Divider(height: 32),
              _detailRow('Specialty', doc.specialty),
              _detailRow('Qualification', doc.qualification),
              _detailRow('Experience', doc.experience),
              _detailRow('Years', '${doc.yearsOfExperience} yrs'),
              _detailRow('Fee', 'Rs ${doc.consultationFee.toStringAsFixed(0)} (pay at clinic)'),
              _detailRow('Rating', '${doc.averageRating.toStringAsFixed(1)} / 5 (${doc.totalReviews} reviews)'),
              _detailRow('Available Days', doc.availableDays.join(', ')),
              _detailRow('Hospital', '${doc.hospitalName}${doc.hospitalCity.isNotEmpty ? ', ${doc.hospitalCity}' : ''}'),
              const SizedBox(height: 20),
              if (!doc.isApproved)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ref.read(adminProvider.notifier).approveDoctor(doc.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.verified_rounded, size: 18),
                    label: const Text('Approve for Public Listing'),
                  ),
                ),
              if (doc.isApproved) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(adminProvider.notifier).rejectDoctor(doc.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.block_rounded, size: 18),
                    label: const Text('Revoke Approval'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    await ref.read(adminProvider.notifier).setDoctorActive(doc.id, !doc.isActive);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(doc.isActive ? 'Deactivate Account' : 'Activate Account'),
                ),
              ),
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
