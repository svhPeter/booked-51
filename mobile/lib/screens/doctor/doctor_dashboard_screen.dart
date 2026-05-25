import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../models/doctor_appointment.dart';
import '../../providers/doctor_dashboard_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/role_menu_button.dart';
import '../../widgets/ui_components.dart';

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    Future.microtask(() {
      ref.read(doctorDashboardProvider.notifier).fetchSummary();
      ref.read(doctorDashboardProvider.notifier).fetchAppointments();
      ref.read(notificationProvider.notifier).fetchUnreadCount();
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
    final state = ref.watch(doctorDashboardProvider);

    ref.listen<DoctorDashboardState>(doctorDashboardProvider, (previous, next) {
      if (next.actionSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Appointment updated successfully'),
            backgroundColor: scheme.secondary,
          ),
        );
      }
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: scheme.error,
          ),
        );
      }
    });

    final summary = state.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push('/inbox'),
          ),
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
                        decoration: BoxDecoration(
                          color: scheme.error,
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
          const RoleMenuButton(profileRoute: '/doctor/profile/edit'),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: scheme.primary,
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurfaceVariant,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Requests'),
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: state.isLoading && state.appointments.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.appointments.isEmpty
              ? _buildError(state)
              : Column(
                  children: [
                    _buildSummaryCards(summary),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAppointmentList(state, 'pending'),
                          _buildAppointmentList(state, 'today'),
                          _buildAppointmentList(state, 'upcoming'),
                          _buildAppointmentList(state, 'completed'),
                          _buildAppointmentList(state, 'cancelled'),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildError(DoctorDashboardState state) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error),
            const SizedBox(height: 16),
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(doctorDashboardProvider.notifier).fetchSummary();
                ref.read(doctorDashboardProvider.notifier).fetchAppointments();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(DashboardSummary? summary) {
    final scheme = Theme.of(context).colorScheme;
    if (summary == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.schedule_rounded,
            value: '${summary.todayCount}',
            label: 'Today',
            color: scheme.primary,
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.check_circle_outline_rounded,
            value: '${summary.completedCount}',
            label: 'Completed',
            color: scheme.secondary,
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.people_outline_rounded,
            value: '${summary.totalPatients}',
            label: 'Patients',
            color: scheme.tertiary,
          ),
        ],
      ),
    );
  }

  List<DoctorAppointmentModel> _filtered(DoctorDashboardState state, String tab) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    switch (tab) {
      case 'pending':
        return state.appointments.where((a) => a.status == 'pending').toList();
      case 'today':
        return state.appointments.where((a) {
          return a.status == 'confirmed' &&
              !a.date.isBefore(todayStart) &&
              a.date.isBefore(todayEnd);
        }).toList();
      case 'upcoming':
        return state.appointments.where((a) {
          return a.status == 'confirmed' &&
              !a.date.isBefore(todayEnd);
        }).toList();
      case 'completed':
        return state.appointments.where((a) => a.status == 'completed').toList();
      case 'cancelled':
        return state.appointments.where((a) => a.status == 'cancelled').toList();
      default:
        return [];
    }
  }

  Widget _buildAppointmentList(DoctorDashboardState state, String tab) {
    final items = _filtered(state, tab);

    if (items.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.event_busy_rounded,
        title: tab == 'pending'
            ? 'No pending requests'
            : tab == 'today'
                ? 'No appointments today'
                : tab == 'upcoming'
                    ? 'No upcoming appointments'
                    : tab == 'completed'
                        ? 'No completed appointments'
                        : 'No cancelled appointments',
        subtitle: tab == 'pending'
            ? 'New patient appointment requests will show here. You control the final confirmed date and time.'
            : tab == 'today'
                ? 'Your scheduled patients will appear here'
                : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(doctorDashboardProvider.notifier).fetchAppointments();
        await ref.read(doctorDashboardProvider.notifier).fetchSummary();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final appt = items[index];
          return _AppointmentCard(
            appointment: appt,
            onConfirm: appt.status == 'pending'
                ? () => _showConfirmAppointmentDialog(context, appt)
                : null,
            onMessage: appt.status == 'confirmed' || appt.status == 'completed'
                ? () => context.push('/doctor/appointment/${appt.id}/chat')
                : null,
            onJoinCall: appt.status == 'confirmed'
                ? () => _joinVideoCall(context, ref, appt.id)
                : null,
            onComplete: appt.status == 'confirmed'
                ? () => ref.read(doctorDashboardProvider.notifier).completeAppointment(appt.id)
                : null,
            onCancel: appt.status != 'cancelled' && appt.status != 'completed'
                ? () => ref.read(doctorDashboardProvider.notifier).cancelAppointment(appt.id)
                : null,

          );
        },
      ),
    );
  }

  Future<void> _showConfirmAppointmentDialog(BuildContext context, DoctorAppointmentModel appointment) async {
    DateTime selectedDate = appointment.preferredDate ?? appointment.date;
    String selectedSlot = appointment.preferredTimeSlot ?? appointment.timeSlot;

    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(selectedDate),
    );

    final dialogScheme = Theme.of(context).colorScheme;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Confirm Appointment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patient: ${appointment.patientName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (appointment.preferredDate != null && appointment.preferredTimeSlot != null) ...[
                    Text(
                      'Preferred: ${DateFormat('MMM dd, yyyy').format(appointment.preferredDate!)} at ${appointment.preferredTimeSlot}',
                      style: TextStyle(fontSize: 13, color: dialogScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text('Set Confirmed Date:', style: TextStyle(fontSize: 12, color: dialogScheme.onSurfaceVariant)),
                  TextField(
                    controller: dateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      hintText: 'Select Date',
                      suffixIcon: Icon(Icons.calendar_today, size: 20),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                          dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Set Confirmed Time Slot:', style: TextStyle(fontSize: 12, color: dialogScheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedSlot,
                    items: const [
                      DropdownMenuItem(value: '09:00', child: Text('09:00 AM')),
                      DropdownMenuItem(value: '09:30', child: Text('09:30 AM')),
                      DropdownMenuItem(value: '10:00', child: Text('10:00 AM')),
                      DropdownMenuItem(value: '10:30', child: Text('10:30 AM')),
                      DropdownMenuItem(value: '11:00', child: Text('11:00 AM')),
                      DropdownMenuItem(value: '11:30', child: Text('11:30 AM')),
                      DropdownMenuItem(value: '12:00', child: Text('12:00 PM')),
                      DropdownMenuItem(value: '12:30', child: Text('12:30 PM')),
                      DropdownMenuItem(value: '13:00', child: Text('01:00 PM')),
                      DropdownMenuItem(value: '13:30', child: Text('01:30 PM')),
                      DropdownMenuItem(value: '14:00', child: Text('02:00 PM')),
                      DropdownMenuItem(value: '14:30', child: Text('02:30 PM')),
                      DropdownMenuItem(value: '15:00', child: Text('03:00 PM')),
                      DropdownMenuItem(value: '15:30', child: Text('03:30 PM')),
                      DropdownMenuItem(value: '16:00', child: Text('04:00 PM')),
                      DropdownMenuItem(value: '16:30', child: Text('04:30 PM')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedSlot = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ref.read(doctorDashboardProvider.notifier).confirmAppointment(
                          appointment.id,
                          selectedDate,
                          selectedSlot,
                        );
                    Navigator.pop(context);
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _joinVideoCall(BuildContext context, WidgetRef ref, String appointmentId) async {
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
        final errScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: errScheme.error,
          ),
        );
      }
    }
  }
}

class _AppointmentCard extends StatelessWidget {
  final DoctorAppointmentModel appointment;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final VoidCallback? onJoinCall;
  final VoidCallback? onMessage;

  const _AppointmentCard({
    required this.appointment,
    this.onComplete,
    this.onCancel,
    this.onConfirm,
    this.onJoinCall,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timeStr = appointment.timeSlot;
    final dateStr = DateFormat('MMM dd, yyyy').format(appointment.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
        boxShadow: context.isDarkMode ? AppShadows.darkSm : AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: scheme.primary.withValues(alpha: 0.2),
                child: Text(
                  appointment.patientName.isNotEmpty
                      ? appointment.patientName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 18,
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    if (appointment.patientPhone.isNotEmpty)
                      Text(
                        appointment.patientPhone,
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              _buildStatusBadge(appointment.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                appointment.status == 'pending' ? 'Preferred: $dateStr' : dateStr,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                appointment.status == 'pending' ? 'Preferred: $timeStr' : timeStr,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          if (onMessage != null || onJoinCall != null || onComplete != null || onCancel != null || onConfirm != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onConfirm != null) ...[
                  _ActionButton(
                    label: 'Confirm',
                    icon: Icons.check_circle_outline,
                    color: scheme.secondary,
                    onTap: onConfirm!,
                  ),
                  const SizedBox(width: 8),
                ],
                if (onMessage != null) ...[
                  _ActionButton(
                    label: 'Message',
                    icon: Icons.chat_bubble_outline,
                    color: scheme.primary,
                    onTap: onMessage!,
                  ),
                  const SizedBox(width: 8),
                ],
                if (onJoinCall != null) ...[
                  _ActionButton(
                    label: 'Join Call',
                    icon: Icons.videocam,
                    color: Colors.teal,
                    onTap: onJoinCall!,
                  ),
                  const SizedBox(width: 8),
                ],
                if (onComplete != null)
                  _ActionButton(
                    label: 'Complete',
                    icon: Icons.check_circle_outline,
                    color: scheme.secondary,
                    onTap: onComplete!,
                  ),
                if (onCancel != null) ...[
                  const SizedBox(width: 8),
                  _ActionButton(
                    label: appointment.status == 'pending' ? 'Reject' : 'Cancel',
                    icon: Icons.cancel_outlined,
                    color: scheme.error,
                    onTap: onCancel!,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return StatusBadge.fromStatus(status);
  }

}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color.withValues(alpha: 0.4)),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
