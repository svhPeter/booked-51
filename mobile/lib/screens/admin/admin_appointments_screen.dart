import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../models/admin_models.dart';
import '../../providers/doctor_provider.dart';
import '../../widgets/ui_components.dart';

class AdminAppointmentsScreen extends ConsumerStatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  ConsumerState<AdminAppointmentsScreen> createState() => _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends ConsumerState<AdminAppointmentsScreen> {
  String? _statusFilter;
  String? _doctorFilter;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminProvider.notifier).fetchAppointments();
      ref.read(doctorProvider.notifier).fetchDoctors();
    });
  }

  void _applyFilters() {
    ref.read(adminProvider.notifier).fetchAppointments(
      status: _statusFilter,
      doctorId: _doctorFilter,
      dateFrom: _dateFrom?.toIso8601String().split('T')[0],
      dateTo: _dateTo?.toIso8601String().split('T')[0],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final doctors = ref.watch(doctorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All Appointments')),
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
                    label: 'Confirmed',
                    selected: _statusFilter == 'confirmed',
                    onSelected: () => setState(() { _statusFilter = 'confirmed'; _applyFilters(); }),
                  ),
                  _FilterChip(
                    label: 'Completed',
                    selected: _statusFilter == 'completed',
                    onSelected: () => setState(() { _statusFilter = 'completed'; _applyFilters(); }),
                  ),
                  _FilterChip(
                    label: 'Cancelled',
                    selected: _statusFilter == 'cancelled',
                    onSelected: () => setState(() { _statusFilter = 'cancelled'; _applyFilters(); }),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 140,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Doctor',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        isDense: true,
                      ),
                      value: _doctorFilter,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        ...doctors.doctors.map((d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(d.name, overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (v) => setState(() { _doctorFilter = v; _applyFilters(); }),
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
    if (state.isLoading && state.appointments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.appointments.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.error_outline_rounded,
        title: 'Failed to load appointments',
        subtitle: state.error,
        actionLabel: 'Retry',
        onAction: _applyFilters,
      );
    }
    if (state.appointments.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.calendar_month_rounded,
        title: 'No appointments found',
        subtitle: 'Try adjusting your filters',
      );
    }
    return RefreshIndicator(
      onRefresh: () async => _applyFilters(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: state.appointments.length,
        itemBuilder: (context, index) {
          final appt = state.appointments[index];
          return _AppointmentCard(appointment: appt);
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

class _AppointmentCard extends ConsumerWidget {
  final AdminAppointment appointment;
  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    String dateStr = appointment.date;
    try {
      final dt = DateTime.parse(appointment.date);
      dateStr = DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
        boxShadow: context.isDarkMode ? AppShadows.darkSm : AppShadows.sm,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text('${appointment.patientName} → Dr. ${appointment.doctorName}',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: scheme.onSurface)),
        subtitle: Text('$dateStr at ${appointment.timeSlot}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusBadge.fromStatus(appointment.status),
            if (appointment.payment != null) ...[
              const SizedBox(height: 4),
              Text('${appointment.payment!.provider} / ${appointment.payment!.status}',
                  style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
            ],
          ],
        ),
        onTap: () => _showAppointmentDetail(context, ref, appointment),
      ),
    );
  }
}

void _showAppointmentDetail(BuildContext context, WidgetRef ref, AdminAppointment appt) {
  final scheme = Theme.of(context).colorScheme;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        String dateStr = appt.date;
        try {
          final dt = DateTime.parse(appt.date);
          dateStr = DateFormat('MMM dd, yyyy').format(dt);
        } catch (_) {}

        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Text('Appointment Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: scheme.onSurface))),
              Divider(height: 32, color: context.dividerColor),
              _detailRow(context, 'Patient', appt.patientName),
              _detailRow(context, 'Patient Email', appt.patientEmail),
              _detailRow(context, 'Patient Phone', appt.patientPhone),
              _detailRow(context, 'Doctor', appt.doctorName),
              _detailRow(context, 'Doctor Email', appt.doctorEmail),
              _detailRow(context, 'Date', dateStr),
              _detailRow(context, 'Time', appt.timeSlot),
              _detailRow(context, 'Status', appt.status),
              _detailRow(context, 'Hospital', appt.hospitalName),
              if (appt.notes != null) _detailRow(context, 'Notes', appt.notes!),
              if (appt.payment != null) ...[
                Divider(color: context.dividerColor),
                Text('Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: scheme.onSurface)),
                const SizedBox(height: 8),
                _detailRow(context, 'Amount', 'Rs. ${appt.payment!.amount.toStringAsFixed(0)}'),
                _detailRow(context, 'Provider', appt.payment!.provider),
                _detailRow(context, 'Status', appt.payment!.status),
              ],
            ],
          ),
        );
      },
    ),
  );
}

Widget _detailRow(BuildContext context, String label, String value) {
  final scheme = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: scheme.onSurfaceVariant, fontSize: 13))),
        Expanded(child: Text(value, style: TextStyle(color: scheme.onSurface))),
      ],
    ),
  );
}

extension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
