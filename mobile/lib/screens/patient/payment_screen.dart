import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final AppointmentModel appointment;

  const PaymentScreen({super.key, required this.appointment});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: scheme.primary.withValues(alpha: 0.2),
                        child: Text(
                          widget.appointment.doctorName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 20,
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
                              'Dr. ${widget.appointment.doctorName}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.appointment.specialty,
                              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Date', style: TextStyle(color: scheme.onSurfaceVariant)),
                      Text(
                        '${widget.appointment.date.day}/${widget.appointment.date.month}/${widget.appointment.date.year}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Time', style: TextStyle(color: scheme.onSurfaceVariant)),
                      Text(
                        widget.appointment.timeSlot,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Consultation Fee', style: TextStyle(fontSize: 16)),
                      Text(
                        'PKR ${widget.appointment.fee.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.primarySurfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: scheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'How payment works',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _infoRow(
                    Icons.store_rounded,
                    'Pay the doctor/clinic directly at your visit.',
                  ),
                  const SizedBox(height: 12),
                  _infoRow(
                    Icons.money_off_rounded,
                    'DocBook does not charge any platform or online fees.',
                  ),
                  const SizedBox(height: 12),
                  _infoRow(
                    Icons.shield_rounded,
                    'Only pay verified doctor/clinic details after confirmation.',
                  ),
                  const SizedBox(height: 12),
                  _infoRow(
                    Icons.warning_amber_rounded,
                    'Never send money to unverified phone numbers or accounts.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'DocBook does not collect consultation fees. All payments are handled directly between you and the doctor/clinic.',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, height: 1.3),
          ),
        ),
      ],
    );
  }
}
