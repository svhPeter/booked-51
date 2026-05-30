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
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _showDoctorDetail(context, ref, doc),
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
              backgroundColor: context.primarySurfaceColor,
              child: Text(
                doc.name.isNotEmpty ? doc.name[0].toUpperCase() : '?',
                style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: scheme.onSurface)),
                  const SizedBox(height: 2),
                  Text(
                    '${doc.specialty}  •  Rs ${doc.consultationFee.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!doc.isApproved)
              StatusBadge(label: 'Pending', color: context.warningColor, icon: Icons.schedule)
            else if (!doc.isActive)
              StatusBadge(label: 'Inactive', color: scheme.error, icon: Icons.block)
            else
              StatusBadge(label: 'Approved', color: scheme.secondary, icon: Icons.verified),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

void _showDoctorDetail(BuildContext context, WidgetRef ref, AdminDoctor doc) {
  final scheme = Theme.of(context).colorScheme;
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
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: context.primarySurfaceColor,
                  child: Text(
                    doc.name.isNotEmpty ? doc.name[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 28, color: scheme.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: Text(doc.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: scheme.onSurface))),
              const SizedBox(height: 4),
              Center(child: Text(doc.email, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13))),
              Center(child: Text(doc.phone, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13))),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (doc.isApproved)
                      StatusBadge(label: 'Approved', color: context.successColor, icon: Icons.verified)
                    else
                      StatusBadge(label: 'Pending', color: context.warningColor, icon: Icons.schedule),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: doc.isActive ? 'Active' : 'Inactive',
                      color: doc.isActive ? AppColors.online : context.errorColor,
                      icon: doc.isActive ? Icons.check_circle : Icons.block,
                    ),
                  ],
                ),
              ),
              Divider(height: 32, color: context.dividerColor),
              _detailRow(context, 'Specialty', doc.specialty),
              _detailRow(context, 'PMDC Reg #', doc.pmdcRegistrationNumber),
              _detailRow(context, 'Qualification', doc.qualification),
              _detailRow(context, 'Experience', doc.experience),
              _detailRow(context, 'Years', '${doc.yearsOfExperience} yrs'),
              _detailRow(context, 'Fee', 'Rs ${doc.consultationFee.toStringAsFixed(0)} (pay at clinic)'),
              _detailRow(context, 'Rating', '${doc.averageRating.toStringAsFixed(1)} / 5 (${doc.totalReviews} reviews)'),
              _detailRow(context, 'Available Days', doc.availableDays.join(', ')),
              _detailRow(context, 'Hospital', '${doc.hospitalName}${doc.hospitalCity.isNotEmpty ? ', ${doc.hospitalCity}' : ''}'),
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
                    style: OutlinedButton.styleFrom(foregroundColor: scheme.error, side: BorderSide(color: scheme.error)),
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

Widget _detailRow(BuildContext context, String label, String value) {
  final scheme = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: scheme.onSurfaceVariant, fontSize: 13)),
        ),
        Expanded(child: Text(value, style: TextStyle(fontSize: 14, color: scheme.onSurface))),
      ],
    ),
  );
}
