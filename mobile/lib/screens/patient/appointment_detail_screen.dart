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

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dr. ${a.doctorName}', style: Theme.of(context).textTheme.headlineSmall),
            Text(a.specialty, style: const TextStyle(color: AppColors.primary)),
            const SizedBox(height: 16),
            _card([
              _line('Date', dateStr),
              _line('Time', a.timeSlot),
              _line('Status', a.status.name),
              if (a.hospitalName != null) _line('Hospital', a.hospitalName!),
              _line('Consultation fee (pay at clinic)', 'PKR ${a.fee.toStringAsFixed(0)}'),
            ]),
            const SizedBox(height: 8),
            const Text(
              'Payment is made directly to the doctor at your visit. DocBook does not charge you online.',
              style: TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
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
            if (a.status == AppointmentStatus.confirmed) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _cancel,
                  child: const Text('Cancel Appointment', style: TextStyle(color: AppColors.error)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: AppColors.textHint))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
