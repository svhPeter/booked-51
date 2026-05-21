import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment.dart';
import '../../providers/payment_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final AppointmentModel appointment;

  const PaymentScreen({super.key, required this.appointment});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedProvider = 'mock';

  final _providers = [
    {'key': 'mock', 'label': 'Mock Payment (Dev)', 'icon': Icons.developer_mode, 'desc': 'Test payment without real charges'},
    {'key': 'stripe', 'label': 'Stripe (International)', 'icon': Icons.credit_card, 'desc': 'Visa, Mastercard, etc.'},
    {'key': 'payfast', 'label': 'PayFast (Pakistan)', 'icon': Icons.account_balance, 'desc': 'Local payment methods'},
  ];

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);

    ref.listen<PaymentState>(paymentProvider, (previous, next) {
      if (next.paymentSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: AppColors.secondary,
          ),
        );
        context.go('/patient/appointments');
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                        child: Text(
                          widget.appointment.doctorName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            color: AppColors.primary,
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
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                      const Text('Date', style: TextStyle(color: AppColors.textSecondary)),
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
                      const Text('Time', style: TextStyle(color: AppColors.textSecondary)),
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text('Select Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ..._providers.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedProvider = p['key'] as String);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedProvider == p['key'] ? AppColors.primary : AppColors.border,
                      width: _selectedProvider == p['key'] ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        p['icon'] as IconData,
                        color: _selectedProvider == p['key'] ? AppColors.primary : AppColors.textHint,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['label'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: _selectedProvider == p['key'] ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p['desc'] as String,
                              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedProvider == p['key'])
                        const Icon(Icons.check_circle, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: paymentState.isLoading ? null : _handlePayment,
                icon: paymentState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.lock_outline),
                label: Text(
                  paymentState.isLoading
                      ? 'Processing...'
                      : 'Pay PKR ${widget.appointment.fee.toStringAsFixed(0)}',
                ),
              ),
            ),
            if (_selectedProvider == 'mock')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 6),
                    const Text(
                      'Mock mode — no real charge will be made',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _handlePayment() async {
    await ref.read(paymentProvider.notifier).createPayment(
      appointmentId: widget.appointment.id,
      provider: _selectedProvider,
    );

    final state = ref.read(paymentProvider);
    if (state.payment != null && _selectedProvider == 'mock') {
      await ref.read(paymentProvider.notifier).mockPaymentSuccess(state.payment!.id);
    }
  }
}
