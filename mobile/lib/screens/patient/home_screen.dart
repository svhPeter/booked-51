import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/role_menu_button.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const PatientHomeScreen({super.key, this.embedded = false});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).fetchUnreadCount();
      ref.read(appointmentProvider.notifier).fetchMyAppointments();
    });
  }

  final List<Map<String, String>> _quickActions = [
    {'icon': 'search', 'label': 'Find Doctor', 'route': '/patient/search'},
    {'icon': 'calendar', 'label': 'My Appointments', 'route': '/patient/appointments'},
    {'icon': 'medical', 'label': 'Specialists', 'route': '/patient/search'},
    {'icon': 'profile', 'label': 'My Profile', 'route': '/patient/profile'},
  ];

  final List<Map<String, dynamic>> _specialties = [
    {'name': 'Cardiologist', 'icon': Icons.favorite_border, 'color': AppColors.error},
    {'name': 'Dermatologist', 'icon': Icons.face, 'color': AppColors.accent},
    {'name': 'Pediatrician', 'icon': Icons.child_care, 'color': AppColors.secondary},
    {'name': 'Neurologist', 'icon': Icons.psychology, 'color': AppColors.warning},
    {'name': 'Orthopedic', 'icon': Icons.accessibility_new, 'color': AppColors.primary},
    {'name': 'Dentist', 'icon': Icons.health_and_safety, 'color': Colors.teal},
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'User';
    final notifState = ref.watch(notificationProvider);
    final apptState = ref.watch(appointmentProvider);
    final now = DateTime.now();
    final upcoming = apptState.appointments
        .where((a) =>
            a.status == AppointmentStatus.confirmed &&
            a.date.isAfter(now.subtract(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final nextAppt = upcoming.isNotEmpty ? upcoming.first : null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello,', style: Theme.of(context).textTheme.bodyMedium),
                      Text(userName, style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                  Row(
                    children: [
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () => context.push('/notifications'),
                          ),
                          if (notifState.unreadCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                child: Text(
                                  notifState.unreadCount > 99
                                      ? '99+'
                                      : '${notifState.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.push('/patient/profile'),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      RoleMenuButton(profileRoute: '/patient/profile'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Book appointments for free. Pay your doctor at the clinic.',
                style: TextStyle(fontSize: 13, color: AppColors.textHint),
              ),
              if (nextAppt != null) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => context.push('/patient/appointment/${nextAppt.id}'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Next appointment',
                            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                        const SizedBox(height: 8),
                        Text('Dr. ${nextAppt.doctorName} • ${nextAppt.timeSlot}',
                            style: Theme.of(context).textTheme.titleSmall),
                        Text(
                          '${nextAppt.date.day}/${nextAppt.date.month}/${nextAppt.date.year}',
                          style: const TextStyle(color: AppColors.textHint, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => context.push('/patient/search'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.textHint),
                      const SizedBox(width: 12),
                      Text(
                        'Search doctors, specialties...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.tune, color: AppColors.primary, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () => context.push('/patient/search'),
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: _quickActions.map((action) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => context.push(action['route']!),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _getIcon(action['icon']!),
                              color: AppColors.primary,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              action['label']!,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              Text('Top Specialties', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: _specialties.length,
                itemBuilder: (context, index) {
                  final spec = _specialties[index];
                  final specName = spec['name'] as String;
                  return GestureDetector(
                    onTap: () => context.push(
                      '/patient/search?specialty=${Uri.encodeComponent(specName)}',
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: spec['color'] as Color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(spec['icon'] as IconData, color: Colors.white, size: 24),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            spec['name'] as String,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'search':
        return Icons.search;
      case 'calendar':
        return Icons.calendar_today;
      case 'medical':
        return Icons.medical_services_outlined;
      case 'history':
        return Icons.history;
      case 'profile':
        return Icons.person_outline;
      default:
        return Icons.circle;
    }
  }
}
