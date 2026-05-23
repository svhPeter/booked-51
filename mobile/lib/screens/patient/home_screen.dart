import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/role_menu_button.dart';
import '../../widgets/ui_components.dart';

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
    {'icon': 'calendar', 'label': 'Appointments', 'route': '/patient/appointments'},
    {'icon': 'medical', 'label': 'Specialists', 'route': '/patient/search'},
    {'icon': 'profile', 'label': 'My Profile', 'route': '/patient/profile'},
  ];

  final List<Map<String, dynamic>> _specialties = [
    {'name': 'Cardiologist', 'icon': Icons.favorite_border, 'color': const Color(0xFFEF4444)},
    {'name': 'Dermatologist', 'icon': Icons.face, 'color': const Color(0xFF8B5CF6)},
    {'name': 'Pediatrician', 'icon': Icons.child_care, 'color': const Color(0xFF10B981)},
    {'name': 'Neurologist', 'icon': Icons.psychology, 'color': const Color(0xFFF59E0B)},
    {'name': 'Orthopedic', 'icon': Icons.accessibility_new, 'color': const Color(0xFF2563EB)},
    {'name': 'Dentist', 'icon': Icons.health_and_safety, 'color': const Color(0xFF14B8A6)},
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
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(appointmentProvider.notifier).fetchMyAppointments();
            await ref.read(notificationProvider.notifier).fetchUnreadCount();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/patient/profile'),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $userName',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Book appointments for free',
                            style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
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
                    RoleMenuButton(profileRoute: '/patient/profile'),
                  ],
                ),

                // Next appointment card
                if (nextAppt != null) ...[
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => context.push('/patient/appointment/${nextAppt.id}'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'NEXT APPOINTMENT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white70),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Dr. ${nextAppt.doctorName}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 13, color: Colors.white70),
                              const SizedBox(width: 6),
                              Text(
                                '${nextAppt.date.day}/${nextAppt.date.month}/${nextAppt.date.year}',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.access_time_rounded, size: 13, color: Colors.white70),
                              const SizedBox(width: 6),
                              Text(
                                nextAppt.timeSlot,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Search bar
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => context.push('/patient/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.sm,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'Search doctors, specialties...',
                          style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

                // Quick actions
                const SizedBox(height: 28),
                const SectionHeader(title: 'Quick Actions'),
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
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border, width: 0.5),
                            boxShadow: AppShadows.sm,
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getIcon(action['icon']!),
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                action['label']!,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Trust banner
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_rounded, color: AppColors.secondary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'All doctors are verified. Pay at the clinic directly.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondary.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Top specialties
                const SizedBox(height: 28),
                const SectionHeader(title: 'Top Specialties'),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: _specialties.length,
                  itemBuilder: (context, index) {
                    final spec = _specialties[index];
                    final specName = spec['name'] as String;
                    final specColor = spec['color'] as Color;
                    return GestureDetector(
                      onTap: () => context.push(
                        '/patient/search?specialty=${Uri.encodeComponent(specName)}',
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border, width: 0.5),
                          boxShadow: AppShadows.sm,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: specColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(spec['icon'] as IconData, color: specColor, size: 22),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              specName,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
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
      ),
    );
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'search':
        return Icons.search_rounded;
      case 'calendar':
        return Icons.calendar_today_rounded;
      case 'medical':
        return Icons.medical_services_outlined;
      case 'history':
        return Icons.history_rounded;
      case 'profile':
        return Icons.person_outline_rounded;
      default:
        return Icons.circle;
    }
  }
}
