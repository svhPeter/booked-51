import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../models/appointment.dart';
import '../../providers/appointment_provider.dart';
import '../../widgets/ui_components.dart';

class MyAppointmentsScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const MyAppointmentsScreen({super.key, this.embedded = false});

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
    final scheme = Theme.of(context).colorScheme;
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
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurfaceVariant,
          indicatorColor: scheme.primary,
          tabs: [
            Tab(text: 'Confirmed (${upcoming.length})'),
            Tab(text: 'Requests (${pending.length})'),
            Tab(text: 'Completed (${past.length})'),
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
              color: scheme.error.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: scheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointmentState.error!,
                      style: TextStyle(color: scheme.error, fontSize: 13),
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
                        isEmpty: 'No confirmed appointments',
                        emptySubtitle: 'Appointments confirmed by your doctor will appear here',
                        allowCancel: true,
                      ),
                      _AppointmentList(
                        appointments: pending,
                        isEmpty: 'No pending requests',
                        emptySubtitle: 'Appointment requests awaiting doctor confirmation',
                        allowCancel: true,
                      ),
                      _AppointmentList(
                        appointments: past,
                        isEmpty: 'No completed appointments',
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
  final String? emptySubtitle;
  final bool allowCancel;

  const _AppointmentList({
    required this.appointments,
    required this.isEmpty,
    this.emptySubtitle,
    this.allowCancel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    if (appointments.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.event_busy_rounded,
        title: isEmpty,
        subtitle: emptySubtitle ?? 'Your appointments will appear here',
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
        final statusColor = appt.status == AppointmentStatus.confirmed
            ? const Color(0xFF10B981)
            : appt.status == AppointmentStatus.pending
                ? const Color(0xFFF59E0B)
                : appt.status == AppointmentStatus.completed
                    ? const Color(0xFF64748B)
                    : const Color(0xFFEF4444);
        final statusBg = appt.status == AppointmentStatus.confirmed
            ? const Color(0xFFD1FAE5)
            : appt.status == AppointmentStatus.pending
                ? const Color(0xFFFEF3C7)
                : appt.status == AppointmentStatus.completed
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFFFEE2E2);
        return InkWell(
          onTap: () => context.push('/patient/appointment/${appt.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPastOrCancelled
                  ? scheme.surface.withValues(alpha: 0.75)
                  : scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: avatar + name/specialty + status badge
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: scheme.primary.withValues(alpha: 0.2),
                      child: Text(
                        appt.doctorName[0].toUpperCase(),
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. ${appt.doctorName}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isPastOrCancelled
                                  ? scheme.onSurfaceVariant
                                  : scheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            appt.specialty,
                            style: TextStyle(fontSize: 12, color: scheme.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Stitch-style status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        appt.status == AppointmentStatus.confirmed
                            ? 'Confirmed'
                            : appt.status == AppointmentStatus.pending
                                ? 'Pending'
                                : appt.status == AppointmentStatus.completed
                                    ? 'Completed'
                                    : 'Cancelled',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Date/time row (Stitch-style)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        '${appt.date.day}/${appt.date.month}/${appt.date.year}',
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time_rounded, size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        appt.timeSlot,
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                // Action buttons
                if (!isPastOrCancelled) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (appt.status == AppointmentStatus.confirmed) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _joinVideoCall(context, ref, appt.id),
                            icon: const Icon(Icons.videocam_rounded, size: 16),
                            label: const Text('Join Call', style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: scheme.secondaryContainer,
                              foregroundColor: scheme.onSecondaryContainer,
                              minimumSize: const Size(0, 38),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (allowCancel)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmCancel(context, ref, appt),
                            icon: const Icon(Icons.cancel_outlined, size: 16),
                            label: const Text('Cancel', style: TextStyle(fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: scheme.error,
                              side: BorderSide(color: scheme.error.withValues(alpha: 0.4)),
                              minimumSize: const Size(0, 38),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _joinVideoCall(BuildContext context, WidgetRef ref, String appointmentId) async {
    final scheme = Theme.of(context).colorScheme;
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/appointments/$appointmentId/video-session');
      final session = Map<String, dynamic>.from(
        response.data['session'] as Map? ?? response.data as Map,
      );
      if (!context.mounted) return;
      context.push('/call/$appointmentId', extra: session);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: scheme.error,
          ),
        );
      }
    }
  }

  void _confirmCancel(BuildContext context, WidgetRef ref, AppointmentModel appt) {
    final scheme = Theme.of(context).colorScheme;
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
            child: Text('Yes, Cancel',
                style: TextStyle(color: scheme.error)),
          ),
        ],
      ),
    );
  }
}
