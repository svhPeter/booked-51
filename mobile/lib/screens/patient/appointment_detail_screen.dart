import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment.dart';
import '../../providers/appointment_provider.dart';
import '../../widgets/ui_components.dart';

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

  Widget _buildPaymentInfoCard(AppointmentModel a) {
    final scheme = Theme.of(context).colorScheme;
    final isClinicVisit = a.hospitalName != null && a.hospitalName!.isNotEmpty;
    return Container(
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
              Icon(isClinicVisit ? Icons.store_rounded : Icons.info_outline,
                  color: scheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                isClinicVisit ? 'Pay at Clinic' : 'Consultation Fee',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isClinicVisit) ...[
            Text(
              'Pay the consultation fee directly at the clinic during your visit.',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, height: 1.4),
            ),
          ] else ...[
            Text(
              'The doctor may request payment via their official account. DocBook does not collect any fees. Do not send money to unverified numbers or accounts.',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, height: 1.4),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.warningColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.warningColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: context.warningColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Only pay the verified doctor/clinic directly. DocBook will never ask you to pay online.',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.warningColor.withValues(alpha: 0.9),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dr. ${a.doctorName}', style: Theme.of(context).textTheme.headlineSmall),
            Text(a.specialty, style: TextStyle(color: scheme.primary)),
            const SizedBox(height: 16),
            _card([
              _line(
                a.status == AppointmentStatus.pending ? 'Preferred Date' : 'Date',
                dateStr,
              ),
              _line(
                a.status == AppointmentStatus.pending ? 'Preferred Time' : 'Time',
                a.timeSlot,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(width: 140, child: Text('Status', style: TextStyle(color: scheme.onSurfaceVariant))),
                    StatusBadge.fromStatus(a.status.name),
                  ],
                ),
              ),
              if (a.hospitalName != null) _line('Hospital', a.hospitalName!),
              if (a.fee > 0)
                _line('Consultation Fee', 'PKR ${a.fee.toStringAsFixed(0)}'),
            ]),
            const SizedBox(height: 8),
            Text(
              isClinicVisit
                  ? 'Payment is made directly to the doctor at your visit. DocBook does not charge you online.'
                  : 'DocBook does not collect any fees. Pay the doctor/clinic directly after confirmation.',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, height: 1.4),
            ),
            if (a.status == AppointmentStatus.pending) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: scheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Awaiting doctor confirmation',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: scheme.primary,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                      Text(
                        'The doctor will review and confirm your appointment. You will be notified once the time is finalised.',
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.videocam, size: 18),
                        label: const Text('Video call available after confirmation'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (a.fee > 0 && (a.status == AppointmentStatus.confirmed)) ...[
              const SizedBox(height: 16),
              _buildPaymentInfoCard(a),
            ],
            const SizedBox(height: 24),
            if (a.status == AppointmentStatus.confirmed) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _joinCall,
                  icon: const Icon(Icons.videocam),
                  label: const Text('Join Video Call'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Secure Agora-powered video consultation. Only join if the doctor has confirmed your appointment.',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant, height: 1.3),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
            if (canChat)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/patient/appointment/${a.id}/chat'),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Message Doctor'),
                ),
              ),
            if (a.status == AppointmentStatus.confirmed || a.status == AppointmentStatus.pending) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _cancel,
                  child: Text(
                    a.status == AppointmentStatus.pending
                        ? 'Cancel Request'
                        : 'Cancel Appointment',
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
        boxShadow: context.isDarkMode ? AppShadows.darkSm : AppShadows.sm,
      ),
      child: Column(children: children),
    );
  }

  Widget _line(String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
