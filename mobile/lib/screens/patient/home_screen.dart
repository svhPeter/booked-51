import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/notification_provider.dart';
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

  final List<Map<String, dynamic>> _specialties = [
    {'name': 'Cardiologist', 'icon': Icons.favorite_border, 'color': const Color(0xFFEF4444)},
    {'name': 'Dermatologist', 'icon': Icons.face, 'color': const Color(0xFF8B5CF6)},
    {'name': 'Pediatrician', 'icon': Icons.child_care, 'color': const Color(0xFF10B981)},
    {'name': 'Neurologist', 'icon': Icons.psychology, 'color': const Color(0xFFF59E0B)},
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'User';
    final apptState = ref.watch(appointmentProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final isLoading = apptState.isLoading;
    final now = DateTime.now();
    final upcoming = apptState.appointments
        .where((a) =>
            a.status == AppointmentStatus.confirmed &&
            a.date.isAfter(now.subtract(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final nextAppt = upcoming.isNotEmpty ? upcoming.first : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 48,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: Icon(Icons.menu_rounded, color: scheme.onSurfaceVariant),
            onPressed: () {},
          ),
        ),
        title: Text('DocBook', style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: scheme.primary,
        )),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => context.push('/patient/profile'),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(appointmentProvider.notifier).fetchMyAppointments();
            await ref.read(notificationProvider.notifier).fetchUnreadCount();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLoading && apptState.appointments.isEmpty) ...[
                  const SizedBox(height: 20),
                  const LoadingSkeleton(height: 100, borderRadius: 16),
                  const SizedBox(height: 20),
                  const LoadingSkeleton(height: 52, borderRadius: 14),
                  const SizedBox(height: 24),
                  const LoadingSkeleton(height: 20, width: 140, borderRadius: 6),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(child: LoadingSkeleton(height: 120, borderRadius: 16)),
                      SizedBox(width: 12),
                      Expanded(child: LoadingSkeleton(height: 120, borderRadius: 16)),
                    ],
                  ),
                ] else ...[
                  // Hero section (Stitch)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outlineVariant, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find your doctor & Book appointments for free.',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Connect with top healthcare professionals near you.',
                          style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant, height: 1.5),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/patient/search'),
                            icon: const Icon(Icons.search_rounded, size: 18),
                            label: const Text('Find a Doctor'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Upcoming Appointment (Stitch-style with left accent bar)
                  if (nextAppt != null) ...[
                    GestureDetector(
                      onTap: () => context.push('/patient/appointment/${nextAppt.id}'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scheme.outlineVariant, width: 0.5),
                          boxShadow: isDark ? AppShadows.darkSm : AppShadows.sm,
                        ),
                        child: Row(
                          children: [
                            // Date box (Stitch)
                            Container(
                              width: 60,
                              height: 68,
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _monthAbbr(nextAppt.date.month).toUpperCase(),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: scheme.primary),
                                  ),
                                  Text(
                                    '${nextAppt.date.day}',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: scheme.onSurface),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dr. ${nextAppt.doctorName}',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: scheme.onSurface),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    nextAppt.specialty,
                                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time_rounded, size: 14, color: scheme.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Text(
                                        nextAppt.timeSlot,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: scheme.primary, size: 24),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Search bar
                  GestureDetector(
                    onTap: () => context.push('/patient/search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: scheme.outlineVariant),
                        boxShadow: isDark ? AppShadows.darkSm : AppShadows.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: scheme.onSurfaceVariant, size: 22),
                          const SizedBox(width: 12),
                          Text(
                            'Search doctors, specialties...',
                            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Specialties grid (Stitch: 2-col grid)
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Specialties', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: scheme.onSurface)),
                      TextButton(
                        onPressed: () => context.push('/patient/search'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('See All', style: TextStyle(fontSize: 13, color: scheme.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: _specialties.length,
                    itemBuilder: (context, index) {
                      final spec = _specialties[index];
                      return GestureDetector(
                        onTap: () => context.push(
                          '/patient/search?specialty=${Uri.encodeComponent(spec['name'] as String)}',
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: scheme.outlineVariant, width: 0.5),
                            boxShadow: isDark ? AppShadows.darkSm : AppShadows.sm,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: (spec['color'] as Color).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Icon(spec['icon'] as IconData, color: spec['color'] as Color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  spec['name'] as String,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: scheme.onSurface),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Quick Action Banners (Stitch)
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickBanner(
                          title: 'How DocBook Works',
                          subtitle: 'Learn to book in 3 easy steps',
                          bgColor: scheme.secondaryContainer,
                          textColor: scheme.onSecondaryContainer,
                          iconBg: scheme.onSecondaryContainer,
                          iconColor: scheme.secondaryContainer,
                          icon: Icons.play_arrow_rounded,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickBanner(
                          title: 'My Health Records',
                          subtitle: 'Access prescriptions & lab results',
                          bgColor: scheme.surfaceContainerHighest,
                          textColor: scheme.onSurface,
                          iconBg: scheme.primary,
                          iconColor: scheme.onPrimary,
                          icon: Icons.folder_rounded,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),

                  // Trust & safety banner
                  const SizedBox(height: 24),
                  const SafetyNoticeCard(
                    message: 'DocBook does not collect any fees. Pay the doctor/clinic directly only after your appointment is confirmed. Do not send money to unverified numbers.',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _monthAbbr(int month) {
    const abbrs = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return abbrs[month - 1];
  }
}

class _QuickBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color bgColor;
  final Color textColor;
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickBanner({
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.textColor,
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.7))),
            const SizedBox(height: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
