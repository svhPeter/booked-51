import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment.dart';
import '../../providers/appointment_provider.dart';

class AppointmentConfirmationScreen extends ConsumerStatefulWidget {
  final AppointmentModel? appointment;
  final String appointmentId;

  const AppointmentConfirmationScreen({
    super.key,
    this.appointment,
    required this.appointmentId,
  });

  @override
  ConsumerState<AppointmentConfirmationScreen> createState() =>
      _AppointmentConfirmationScreenState();
}

class _AppointmentConfirmationScreenState
    extends ConsumerState<AppointmentConfirmationScreen> {
  AppointmentModel? _appointment;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _appointment = widget.appointment;
    if (_appointment == null) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final appt = await ref
        .read(appointmentProvider.notifier)
        .fetchAppointmentById(widget.appointmentId);
    if (mounted) {
      setState(() {
        _appointment = appt;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final appointment = _appointment;
    if (appointment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Appointment Confirmed')),
        body: const Center(child: Text('Could not load appointment details.')),
      );
    }

    final dateStr =
        '${appointment.date.day}/${appointment.date.month}/${appointment.date.year}';

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Confirmed')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.secondarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Your appointment is confirmed',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'No online payment required. Pay the doctor directly at your visit.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textHint,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _infoCard(
              context,
              children: [
                _row('Doctor', 'Dr. ${appointment.doctorName}'),
                _row('Specialty', appointment.specialty),
                _row('Date', dateStr),
                _row('Time', appointment.timeSlot),
                if (appointment.hospitalName != null)
                  _row('Location', appointment.hospitalName!),
                _row(
                  'Consultation fee (pay at clinic)',
                  'PKR ${appointment.fee.toStringAsFixed(0)}',
                  highlight: true,
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/patient/appointment/${appointment.id}'),
                child: const Text('View Appointment Details'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go('/patient/appointments'),
                child: const Text('My Appointments'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: AppShadows.sm,
      ),
      child: Column(children: children),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textHint,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                color: highlight ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
