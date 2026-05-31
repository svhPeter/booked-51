import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment.dart';
import '../../providers/appointment_provider.dart';


class AppointmentDetailScreen extends ConsumerStatefulWidget {
  final String appointmentId;

  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  ConsumerState<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends ConsumerState<AppointmentDetailScreen> {
  AppointmentModel? _appointment;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final appt =
        await ref.read(appointmentProvider.notifier).fetchAppointmentById(widget.appointmentId);
    if (mounted) {
      setState(() {
        _appointment = appt;
        _loading = false;
        _error = appt == null ? 'Could not load appointment' : null;
      });
    }
  }

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, cancel')),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(appointmentProvider.notifier).cancelAppointment(widget.appointmentId);
    if (mounted) context.go('/patient/appointments');
  }

  Future<void> _joinCall() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/appointments/${widget.appointmentId}/video-session');
      final session = Map<String, dynamic>.from(
        res.data['session'] as Map? ?? res.data as Map,
      );
      if (!mounted) return;
      context.push('/call/${widget.appointmentId}', extra: session);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start video: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_appointment == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'Not found')),
      );
    }

    final a = _appointment!;
    final dateStr = '${a.date.day}/${a.date.month}/${a.date.year}';
    final canChat = a.status == AppointmentStatus.confirmed ||
        a.status == AppointmentStatus.completed;
    final isClinicVisit = a.hospitalName != null && a.hospitalName!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status pill badge (Stitch-style)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: a.status == AppointmentStatus.confirmed
                      ? scheme.secondaryContainer
                      : a.status == AppointmentStatus.pending
                          ? const Color(0xFFFEF3C7)
                          : a.status == AppointmentStatus.completed
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: a.status == AppointmentStatus.confirmed
                        ? const Color(0xFF6BD8CB)
                        : a.status == AppointmentStatus.pending
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                            : a.status == AppointmentStatus.completed
                                ? const Color(0xFF64748B).withValues(alpha: 0.3)
                                : const Color(0xFFEF4444).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      a.status == AppointmentStatus.confirmed
                          ? Icons.check_circle_rounded
                          : a.status == AppointmentStatus.pending
                              ? Icons.hourglass_top_rounded
                              : a.status == AppointmentStatus.completed
                                  ? Icons.task_alt_rounded
                                  : Icons.cancel_rounded,
                      size: 18,
                      color: a.status == AppointmentStatus.confirmed
                          ? const Color(0xFF006F66)
                          : a.status == AppointmentStatus.pending
                              ? const Color(0xFFF59E0B)
                              : a.status == AppointmentStatus.completed
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      a.status == AppointmentStatus.confirmed
                          ? 'Confirmed'
                          : a.status == AppointmentStatus.pending
                              ? 'Awaiting Confirmation'
                              : a.status == AppointmentStatus.completed
                                  ? 'Completed'
                                  : 'Cancelled',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: a.status == AppointmentStatus.confirmed
                            ? const Color(0xFF006F66)
                            : a.status == AppointmentStatus.pending
                                ? const Color(0xFFF59E0B)
                                : a.status == AppointmentStatus.completed
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Doctor card (Stitch-style)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant, width: 0.5),
                boxShadow: isDark ? AppShadows.darkSm : AppShadows.sm,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: scheme.primary.withValues(alpha: 0.2),
                    child: Text(
                      a.doctorName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        color: scheme.primary,
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
                          'Dr. ${a.doctorName}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          a.specialty,
                          style: TextStyle(color: scheme.primary, fontSize: 13),
                        ),
                        if (a.hospitalName != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 13, color: scheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  a.hospitalName!,
                                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Schedule + Fee grid (Stitch-style)
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.calendar_month_rounded,
                    label: a.status == AppointmentStatus.pending ? 'Preferred Date' : 'Date',
                    value: dateStr,
                    scheme: scheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.schedule_rounded,
                    label: a.status == AppointmentStatus.pending ? 'Preferred Time' : 'Time',
                    value: a.timeSlot,
                    scheme: scheme,
                  ),
                ),
              ],
            ),
            if (a.fee > 0) ...[
              const SizedBox(height: 12),
              _InfoTile(
                icon: Icons.payments_rounded,
                label: 'Consultation Fee',
                value: 'PKR ${a.fee.toStringAsFixed(0)}',
                scheme: scheme,
                isFee: true,
              ),
            ],
            const SizedBox(height: 20),
            // Payment info card (Stitch-style)
            if (a.status == AppointmentStatus.confirmed) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_rounded, color: scheme.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isClinicVisit
                            ? 'Payment will be collected directly at the clinic reception.'
                            : 'DocBook does not collect fees. Pay the doctor/clinic directly after confirmation.',
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Pending state info (Stitch-style)
            if (a.status == AppointmentStatus.pending) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Awaiting confirmation',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'The doctor will review and confirm your appointment. You will be notified once the time is finalised.',
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Actions (Stitch-style)
            if (a.status == AppointmentStatus.confirmed) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _joinCall,
                  icon: const Icon(Icons.videocam_rounded, size: 20),
                  label: const Text('Join Video Call'),
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (canChat)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/patient/appointment/${a.id}/chat'),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  label: const Text('Message Doctor'),
                  style: OutlinedButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            if (a.status == AppointmentStatus.confirmed || a.status == AppointmentStatus.pending) ...[
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: _cancel,
                  child: Text(
                    a.status == AppointmentStatus.pending
                        ? 'Cancel Request'
                        : 'Cancel Appointment',
                    style: TextStyle(color: scheme.error, fontSize: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme scheme;
  final bool isFee;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.scheme,
    this.isFee = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, color: scheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isFee ? scheme.secondary : scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
