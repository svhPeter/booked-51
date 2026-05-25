import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../models/admin_models.dart';
import '../../widgets/ui_components.dart';

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
            padding: const EdgeInsets.all(12),
            color: context.surfaceVariantColor,
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
      return EmptyStateWidget(
        icon: Icons.error_outline_rounded,
        title: 'Failed to load payments',
        subtitle: state.error,
        actionLabel: 'Retry',
        onAction: _applyFilters,
      );
    }
    if (state.payments.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.receipt_long_rounded,
        title: 'No payments found',
        subtitle: 'Try adjusting your filters',
      );
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    String dateStr = payment.createdAt;
    try {
      final dt = DateTime.parse(payment.createdAt);
      dateStr = DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
        boxShadow: context.isDarkMode ? AppShadows.darkSm : AppShadows.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rs ${payment.amount.toStringAsFixed(0)}  •  ${payment.provider.toUpperCase()}',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: scheme.onSurface)),
                const SizedBox(height: 4),
                Text(payment.userName, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                Text('$dateStr${payment.appointmentTimeSlot.isNotEmpty ? " at ${payment.appointmentTimeSlot}" : ""}',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                if (payment.providerTxnId != null)
                  Text('Txn: ${payment.providerTxnId}', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          StatusBadge.fromStatus(payment.status),
        ],
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
