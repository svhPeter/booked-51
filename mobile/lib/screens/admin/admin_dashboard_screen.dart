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
        _ManagementCard(
          icon: Icons.medical_services_rounded,
          label: 'Doctors',
          count: s.totalDoctors,
          color: AppColors.primary,
          onTap: () => context.push('/admin/doctors'),
        ),
        const SizedBox(height: 10),
        _ManagementCard(
          icon: Icons.people_rounded,
          label: 'Patients',
          count: s.totalPatients,
          color: AppColors.secondary,
          onTap: () => context.push('/admin/patients'),
        ),
        const SizedBox(height: 10),
        _ManagementCard(
          icon: Icons.calendar_month_rounded,
          label: 'Appointments',
          count: s.totalAppointments,
          color: AppColors.warning,
          onTap: () => context.push('/admin/appointments'),
        ),
        const SizedBox(height: 10),
        _ManagementCard(
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
        _SummaryCard(title: 'Doctors', value: summary.totalDoctors.toString(), icon: Icons.medical_services_outlined, color: AppColors.primary),
        _SummaryCard(title: 'Patients', value: summary.totalPatients.toString(), icon: Icons.people_outline, color: AppColors.secondary),
        _SummaryCard(title: 'Appointments', value: summary.totalAppointments.toString(), icon: Icons.calendar_today_rounded, color: AppColors.warning),
        _SummaryCard(title: 'Completed', value: summary.completedAppointments.toString(), icon: Icons.task_alt_rounded, color: const Color(0xFF14B8A6)),
        _SummaryCard(title: 'Cancelled', value: summary.cancelledAppointments.toString(), icon: Icons.cancel_outlined, color: AppColors.error),
        _SummaryCard(title: 'Paid', value: summary.paidPaymentsCount.toString(), icon: Icons.check_circle_outline, color: const Color(0xFF6366F1)),
        _SummaryCard(title: 'Pending', value: summary.pendingPaymentsCount.toString(), icon: Icons.schedule_rounded, color: const Color(0xFFD97706)),
        _SummaryCard(
          title: 'Revenue',
          value: 'Rs ${summary.totalRevenue.toStringAsFixed(0)}',
          icon: Icons.trending_up_rounded,
          color: AppColors.accent,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bgAlpha = isDark ? 0.12 : 0.06;
    final borderAlpha = isDark ? 0.2 : 0.12;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: borderAlpha)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color),
            ),
          ),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;
  const _ManagementCard({required this.icon, required this.label, required this.count, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant, width: 0.5),
          boxShadow: context.isDarkMode ? AppShadows.darkSm : AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: scheme.onSurface)),
                  const SizedBox(height: 2),
                  Text('$count total', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
