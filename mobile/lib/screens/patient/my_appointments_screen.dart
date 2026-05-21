import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../models/appointment.dart';
import '../../providers/appointment_provider.dart';

class MyAppointmentsScreen extends ConsumerStatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  ConsumerState<MyAppointmentsScreen> createState() =>
      _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends ConsumerState<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(() {
      ref.read(appointmentProvider.notifier).fetchMyAppointments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointmentState = ref.watch(appointmentProvider);

    final upcoming = appointmentState.appointments
        .where((a) => a.status == AppointmentStatus.confirmed)
        .toList();
    final pending = appointmentState.appointments
        .where((a) => a.status == AppointmentStatus.pending)
        .toList();
    final past = appointmentState.appointments
        .where((a) => a.status == AppointmentStatus.completed)
        .toList();
    final cancelled = appointmentState.appointments
        .where((a) => a.status == AppointmentStatus.cancelled)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Upcoming (${upcoming.length})'),
            Tab(text: 'Pending (${pending.length})'),
            Tab(text: 'Past (${past.length})'),
            Tab(text: 'Cancelled (${cancelled.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (appointmentState.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppColors.error.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointmentState.error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: appointmentState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _AppointmentList(
                        appointments: upcoming,
                        isEmpty: 'No upcoming appointments',
                        allowCancel: true,
                      ),
                      _AppointmentList(
                        appointments: pending,
                        isEmpty: 'No pending appointments',
                        allowCancel: true,
                      ),
                      _AppointmentList(
                        appointments: past,
                        isEmpty: 'No past appointments',
                      ),
                      _AppointmentList(
                        appointments: cancelled,
                        isEmpty: 'No cancelled appointments',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentList extends ConsumerWidget {
  final List<AppointmentModel> appointments;
  final String isEmpty;
  final bool allowCancel;

  const _AppointmentList({
    required this.appointments,
    required this.isEmpty,
    this.allowCancel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 48, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(isEmpty, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final appt = appointments[index];
        final isPastOrCancelled = appt.status == AppointmentStatus.completed ||
            appt.status == AppointmentStatus.cancelled;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                    child: Text(
                      appt.doctorName[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${appt.doctorName}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(appt.specialty,
                            style:
                                const TextStyle(fontSize: 12, color: AppColors.primary)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(appt.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      appt.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(appt.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    '${appt.date.day}/${appt.date.month}/${appt.date.year}',
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    appt.timeSlot,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ),
              if (!isPastOrCancelled) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (appt.status == AppointmentStatus.confirmed) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _joinVideoCall(context, ref, appt.id),
                          icon: const Icon(Icons.videocam, size: 18),
                          label: const Text('Join Call'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (allowCancel)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmCancel(context, ref, appt),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _joinVideoCall(BuildContext context, WidgetRef ref, String appointmentId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/appointments/$appointmentId/video-session');
      final session = response.data['session'] as Map<String, dynamic>;
      if (!context.mounted) return;
      context.push('/call/$appointmentId', extra: session);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _confirmCancel(BuildContext context, WidgetRef ref, AppointmentModel appt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text(
            'Cancel your appointment with Dr. ${appt.doctorName} on ${appt.date.day}/${appt.date.month}/${appt.date.year} at ${appt.timeSlot}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(appointmentProvider.notifier).cancelAppointment(appt.id);
            },
            child: const Text('Yes, Cancel',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return AppColors.secondary;
      case AppointmentStatus.pending:
        return AppColors.warning;
      case AppointmentStatus.completed:
        return AppColors.primary;
      case AppointmentStatus.cancelled:
        return AppColors.error;
    }
  }
}
