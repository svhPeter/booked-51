import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/appointment_provider.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  final String doctorId;

  const BookAppointmentScreen({super.key, required this.doctorId});

  @override
  ConsumerState<BookAppointmentScreen> createState() =>
      _BookAppointmentScreenState();
}

class _BookAppointmentScreenState
    extends ConsumerState<BookAppointmentScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
    Future.microtask(() {
      ref.read(doctorProvider.notifier).fetchDoctorById(widget.doctorId);
      ref.read(appointmentProvider.notifier).fetchAvailableSlots(
            widget.doctorId,
            _selectedDate,
          );
    });
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final days = <DateTime>[];
    for (int i = 0; i < first.weekday - 1; i++) {
      days.add(DateTime(month.year, month.month, -i));
    }
    days.sort();
    for (int i = 1; i <= last.day; i++) {
      days.add(DateTime(month.year, month.month, i));
    }
    return days;
  }

  void _fetchSlotsForDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedSlot = null;
    });
    ref.read(appointmentProvider.notifier).fetchAvailableSlots(
          widget.doctorId,
          date,
        );
  }

  void _handleBooking() {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    ref.read(appointmentProvider.notifier).bookAppointment(
          doctorId: widget.doctorId,
          date: _selectedDate,
          timeSlot: _selectedSlot!,
        );
  }

  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorProvider);
    final appointmentState = ref.watch(appointmentProvider);
    final doctor = doctorState.selectedDoctor;

    ref.listen<AppointmentState>(appointmentProvider, (previous, next) {
      if (next.bookingSuccess && next.lastBookedAppointment != null) {
        final id = next.lastBookedAppointment!.id;
        ref.read(appointmentProvider.notifier).resetBookingState();
        context.go('/patient/appointment/$id/confirmed', extra: next.lastBookedAppointment);
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
      appBar: AppBar(title: const Text('Book Appointment')),
      body: doctorState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (doctor != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                            child: Text(
                              doctor.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                color: AppColors.primary,
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
                                  'Dr. ${doctor.name}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  doctor.specialty,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'PKR ${doctor.consultationFee.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 28),
                  Text('Select Preferred Date', style: Theme.of(context).textTheme.titleLarge),
                  if (doctor != null && doctor.availableDays.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Available: ${doctor.availableDays.join(', ')}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textHint),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () {
                                setState(() {
                                  _currentMonth = DateTime(
                                    _currentMonth.year,
                                    _currentMonth.month - 1,
                                  );
                                });
                              },
                            ),
                            Text(
                              '${_monthName(_currentMonth.month)} ${_currentMonth.year}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                setState(() {
                                  _currentMonth = DateTime(
                                    _currentMonth.year,
                                    _currentMonth.month + 1,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                              .map((d) => SizedBox(
                                    width: 36,
                                    child: Text(
                                      d,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textHint,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: _getDaysInMonth(_currentMonth).map((day) {
                            final isToday = _isSameDay(day, DateTime.now());
                            final isSelected = _isSameDay(day, _selectedDate);
                            final isPast = day.isBefore(
                              DateTime(DateTime.now().year, DateTime.now().month,
                                  DateTime.now().day),
                            );
                            final isCurrentMonth = day.month == _currentMonth.month;
                            final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                            final dayName = dayNames[day.weekday % 7];
                            final isUnavailable = doctor != null &&
                                doctor.availableDays.isNotEmpty &&
                                !doctor.availableDays.contains(dayName);

                            return GestureDetector(
                              onTap: isPast || !isCurrentMonth || isUnavailable
                                  ? null
                                  : () => _fetchSlotsForDate(day),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : isToday
                                          ? AppColors.primary.withValues(alpha: 0.1)
                                          : null,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.white
                                          : isPast || !isCurrentMonth || isUnavailable
                                              ? AppColors.textHint
                                              : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('Preferred Time Slot', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  appointmentState.availableSlots.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.schedule, size: 40, color: AppColors.textHint),
                              const SizedBox(height: 8),
                              Text(
                                'No slots available for this date',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                      : Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: appointmentState.availableSlots.map((slot) {
                            final isSelected = _selectedSlot == slot;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedSlot = slot),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  slot,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed:
                          appointmentState.isLoading ? null : _handleBooking,
                      icon: appointmentState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        appointmentState.isLoading
                            ? 'Sending Request...'
                            : 'Request Appointment',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
