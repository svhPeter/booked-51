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
  final _txnController = TextEditingController();
  bool _submittingPayment = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _txnController.dispose();
    super.dispose();
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

  Future<void> _submitPaymentProof() async {
    final txnId = _txnController.text.trim();
    if (txnId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Transaction ID')),
      );
      return;
    }

    setState(() {
      _submittingPayment = true;
    });

    try {
      final api = ref.read(apiClientProvider);
      await api.post('/payments/create', data: {
        'appointmentId': widget.appointmentId,
        'provider': 'mock',
        'providerTxnId': txnId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment proof submitted successfully! Waiting for doctor verification.'),
          backgroundColor: AppColors.secondary,
        ),
      );

      _txnController.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not submit payment proof: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submittingPayment = false;
        });
      }
    }
  }

  Widget _buildPaymentProofCard(AppointmentModel a) {
    if (a.payment == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wallet_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'JazzCash / EasyPaisa Payment',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Please send the consultation fee to one of the clinic accounts below and submit the transaction reference ID:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            _paymentAccountLine('JazzCash Account', '0300-1234567 (DocBook Clinic)'),
            _paymentAccountLine('EasyPaisa Account', '0345-7654321 (DocBook Clinic)'),
            const Divider(height: 24),
            const Text(
              'Transaction ID (Trx ID)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _txnController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 123456789012',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _submittingPayment
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : ElevatedButton(
                        onPressed: _submitPaymentProof,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Text('Submit'),
                      ),
              ],
            ),
          ],
        ),
      );
    }

    final isPaid = a.payment!.status == 'paid';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPaid ? AppColors.secondarySurface : Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaid ? AppColors.secondary.withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPaid ? Icons.check_circle_outline : Icons.schedule_rounded,
                color: isPaid ? AppColors.secondary : Colors.amber.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isPaid ? 'Payment Verified' : 'Payment Verification Pending',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isPaid ? AppColors.secondary : Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPaid
                ? 'Thank you! Your payment of PKR ${a.payment!.amount.toStringAsFixed(0)} has been verified. The video call is unlocked.'
                : 'Your payment proof (Trx ID: ${a.payment!.providerTxnId}) has been submitted. The doctor will verify the transfer, and your video call button will unlock immediately.',
            style: TextStyle(
              fontSize: 12,
              color: isPaid ? AppColors.textSecondary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentAccountLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
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
                    const SizedBox(width: 140, child: Text('Status', style: TextStyle(color: AppColors.textTertiary))),
                    StatusBadge.fromStatus(a.status.name),
                  ],
                ),
              ),
              if (a.hospitalName != null) _line('Hospital', a.hospitalName!),
              _line(
                a.hospitalName == null ? 'Consultation Fee (JazzCash/EasyPaisa)' : 'Consultation Fee (Pay at Clinic)',
                'PKR ${a.fee.toStringAsFixed(0)}',
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              a.hospitalName == null
                  ? 'Payment is verified by the doctor via JazzCash or EasyPaisa transaction ID.'
                  : 'Payment is made directly to the doctor at your visit. DocBook does not charge you online.',
              style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
            ),
            if (a.status == AppointmentStatus.pending) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Waiting for doctor/clinic confirmation.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'You will be notified when the final time is confirmed.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (a.fee > 0 && a.hospitalName == null && (a.status == AppointmentStatus.confirmed || a.status == AppointmentStatus.pending)) ...[
              const SizedBox(height: 16),
              _buildPaymentProofCard(a),
            ],
            const SizedBox(height: 24),
            if (a.status == AppointmentStatus.confirmed) ...[
              if (a.fee > 0 && a.hospitalName == null && (a.payment == null || a.payment!.status != 'paid')) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_clock_outlined, color: Colors.amber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Video Call locked. Please submit EasyPaisa/JazzCash payment proof and wait for verification.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
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
                    style: const TextStyle(color: AppColors.error),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: AppShadows.sm,
      ),
      child: Column(children: children),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
