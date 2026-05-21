import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_provider.dart';
import '../../models/admin_models.dart';

class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  ConsumerState<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  String? _statusFilter;
  String? _providerFilter;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).fetchPayments());
  }

  void _applyFilters() {
    ref.read(adminProvider.notifier).fetchPayments(
      status: _statusFilter,
      provider: _providerFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All Payments')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade50,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _statusFilter == null,
                    onSelected: () => setState(() { _statusFilter = null; _applyFilters(); }),
                  ),
                  _FilterChip(
                    label: 'Pending',
                    selected: _statusFilter == 'pending',
                    onSelected: () => setState(() { _statusFilter = 'pending'; _applyFilters(); }),
                  ),
                  _FilterChip(
                    label: 'Paid',
                    selected: _statusFilter == 'paid',
                    onSelected: () => setState(() { _statusFilter = 'paid'; _applyFilters(); }),
                  ),
                  _FilterChip(
                    label: 'Failed',
                    selected: _statusFilter == 'failed',
                    onSelected: () => setState(() { _statusFilter = 'failed'; _applyFilters(); }),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 130,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Provider',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        isDense: true,
                      ),
                      value: _providerFilter,
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All')),
                        DropdownMenuItem(value: 'mock', child: Text('Mock')),
                        DropdownMenuItem(value: 'stripe', child: Text('Stripe')),
                        DropdownMenuItem(value: 'payfast', child: Text('PayFast')),
                      ],
                      onChanged: (v) => setState(() { _providerFilter = v; _applyFilters(); }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(AdminState state) {
    if (state.isLoading && state.payments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _applyFilters,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (state.payments.isEmpty) {
      return const Center(child: Text('No payments found.'));
    }
    return RefreshIndicator(
      onRefresh: () async => _applyFilters(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: state.payments.length,
        itemBuilder: (context, index) {
          final payment = state.payments[index];
          return _PaymentCard(payment: payment);
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  const _FilterChip({required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final AdminPayment payment;
  const _PaymentCard({required this.payment});

  Color _statusColor(String status) {
    switch (status) {
      case 'paid': return Colors.green;
      case 'pending': return Colors.orange;
      case 'failed': return Colors.red;
      case 'refunded': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateStr = payment.createdAt;
    try {
      final dt = DateTime.parse(payment.createdAt);
      dateStr = DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rs. ${payment.amount.toStringAsFixed(0)}  •  ${payment.provider.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(payment.userName, style: const TextStyle(fontSize: 13)),
                  Text('$dateStr${payment.appointmentTimeSlot.isNotEmpty ? " at ${payment.appointmentTimeSlot}" : ""}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (payment.providerTxnId != null)
                    Text('Txn: ${payment.providerTxnId}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(payment.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(payment.status.capitalize(),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor(payment.status))),
            ),
          ],
        ),
      ),
    );
  }
}

extension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
