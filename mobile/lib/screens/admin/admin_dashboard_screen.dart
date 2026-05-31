import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/admin_models.dart';
import '../../widgets/role_menu_button.dart';
import '../../widgets/ui_components.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminProvider.notifier).fetchSummary();
      ref.read(notificationProvider.notifier).fetchUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          const RoleMenuButton(),
          Consumer(
            builder: (context, ref, _) {
              final notifState = ref.watch(notificationProvider);
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.push('/notifications'),
                  ),
                  if (notifState.unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          notifState.unreadCount > 99 ? '99+' : '${notifState.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminProvider.notifier).fetchSummary(),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(AdminState state) {
    if (state.isLoading && state.summary == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.summary == null) {
      final scheme = Theme.of(context).colorScheme;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.errorSurfaceColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.error_outline_rounded, color: scheme.error, size: 32),
            ),
            const SizedBox(height: 16),
            Text(state.error!, style: TextStyle(color: scheme.error), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => ref.read(adminProvider.notifier).fetchSummary(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final s = state.summary!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const SectionHeader(title: 'Platform Overview'),
        const SizedBox(height: 14),
        _SummaryCardGrid(summary: s),
        const SizedBox(height: 28),
        const SectionHeader(title: 'Management'),
        const SizedBox(height: 14),
        StitchManagementCard(
          icon: Icons.medical_services_rounded,
          label: 'Doctors',
          count: s.totalDoctors,
          color: AppColors.primary,
          onTap: () => context.push('/admin/doctors'),
        ),
        const SizedBox(height: 10),
        StitchManagementCard(
          icon: Icons.people_rounded,
          label: 'Patients',
          count: s.totalPatients,
          color: AppColors.secondary,
          onTap: () => context.push('/admin/patients'),
        ),
        const SizedBox(height: 10),
        StitchManagementCard(
          icon: Icons.calendar_month_rounded,
          label: 'Appointments',
          count: s.totalAppointments,
          color: AppColors.warning,
          onTap: () => context.push('/admin/appointments'),
        ),
        const SizedBox(height: 10),
        StitchManagementCard(
          icon: Icons.receipt_long_rounded,
          label: 'Payments',
          count: s.paidPaymentsCount + s.pendingPaymentsCount,
          color: AppColors.accent,
          onTap: () => context.push('/admin/payments'),
        ),
      ],
    );
  }
}

class _SummaryCardGrid extends StatelessWidget {
  final AdminSummary summary;
  const _SummaryCardGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.65,
      children: [
        StitchStatCard(icon: Icons.medical_services_outlined, value: summary.totalDoctors.toString(), label: 'Doctors', color: AppColors.primary),
        StitchStatCard(icon: Icons.people_outline, value: summary.totalPatients.toString(), label: 'Patients', color: AppColors.secondary),
        StitchStatCard(icon: Icons.calendar_today_rounded, value: summary.totalAppointments.toString(), label: 'Appointments', color: AppColors.warning),
        StitchStatCard(icon: Icons.task_alt_rounded, value: summary.completedAppointments.toString(), label: 'Completed', color: const Color(0xFF14B8A6)),
        StitchStatCard(icon: Icons.cancel_outlined, value: summary.cancelledAppointments.toString(), label: 'Cancelled', color: AppColors.error),
        StitchStatCard(icon: Icons.check_circle_outline, value: summary.paidPaymentsCount.toString(), label: 'Paid', color: const Color(0xFF6366F1)),
        StitchStatCard(icon: Icons.schedule_rounded, value: summary.pendingPaymentsCount.toString(), label: 'Pending', color: const Color(0xFFD97706)),
        StitchStatCard(
          icon: Icons.trending_up_rounded,
          value: 'Rs ${summary.totalRevenue.toStringAsFixed(0)}',
          label: 'Revenue',
          color: AppColors.accent,
        ),
      ],
    );
  }
}
