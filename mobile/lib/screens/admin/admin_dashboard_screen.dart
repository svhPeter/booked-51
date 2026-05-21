import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/admin_models.dart';

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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(adminProvider.notifier).fetchSummary(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final s = state.summary!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Platform Overview', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        _SummaryCardGrid(summary: s),
        const SizedBox(height: 24),
        Text('Management', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        _ManagementButton(
          icon: Icons.medical_services,
          label: 'Doctors (${s.totalDoctors})',
          color: Colors.blue,
          onTap: () => context.push('/admin/doctors'),
        ),
        _ManagementButton(
          icon: Icons.people,
          label: 'Patients (${s.totalPatients})',
          color: Colors.green,
          onTap: () => context.push('/admin/patients'),
        ),
        _ManagementButton(
          icon: Icons.calendar_today,
          label: 'Appointments (${s.totalAppointments})',
          color: Colors.orange,
          onTap: () => context.push('/admin/appointments'),
        ),
        _ManagementButton(
          icon: Icons.payment,
          label: 'Payments (${s.paidPaymentsCount + s.pendingPaymentsCount})',
          color: Colors.purple,
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
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _SummaryCard(title: 'Total Doctors', value: summary.totalDoctors.toString(), color: Colors.blue),
        _SummaryCard(title: 'Total Patients', value: summary.totalPatients.toString(), color: Colors.green),
        _SummaryCard(title: 'Appointments', value: summary.totalAppointments.toString(), color: Colors.orange),
        _SummaryCard(title: 'Completed', value: summary.completedAppointments.toString(), color: Colors.teal),
        _SummaryCard(title: 'Cancelled', value: summary.cancelledAppointments.toString(), color: Colors.red.shade300),
        _SummaryCard(title: 'Paid Payments', value: summary.paidPaymentsCount.toString(), color: Colors.indigo),
        _SummaryCard(title: 'Pending Paym.', value: summary.pendingPaymentsCount.toString(), color: Colors.amber.shade700),
        _SummaryCard(
          title: 'Revenue',
          value: 'Rs. ${summary.totalRevenue.toStringAsFixed(0)}',
          color: Colors.deepPurple,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _SummaryCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ManagementButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ManagementButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
