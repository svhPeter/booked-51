import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/doctor_provider.dart';

class DoctorProfileScreen extends ConsumerStatefulWidget {
  final String doctorId;

  const DoctorProfileScreen({super.key, required this.doctorId});

  @override
  ConsumerState<DoctorProfileScreen> createState() =>
      _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(doctorProvider.notifier).fetchDoctorById(widget.doctorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorProvider);
    final doctor = doctorState.selectedDoctor;

    return Scaffold(
      body: doctorState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : doctor == null
              ? const Center(child: Text('Doctor not found'))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 280,
                      floating: false,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                            ),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 60),
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  backgroundImage: doctor.avatarUrl != null
                                      ? NetworkImage(doctor.avatarUrl!)
                                      : null,
                                  child: doctor.avatarUrl == null
                                      ? Text(
                                          doctor.name[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 40,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Dr. ${doctor.name}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doctor.specialty,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _InfoChip(
                                  icon: Icons.star,
                                  value: '${doctor.averageRating.toStringAsFixed(1)}',
                                  label: 'Rating',
                                  color: AppColors.rating,
                                ),
                                const SizedBox(width: 12),
                                _InfoChip(
                                  icon: Icons.work_outline,
                                  value: '${doctor.yearsOfExperience}+',
                                  label: 'Years Exp',
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                _InfoChip(
                                  icon: Icons.people_outline,
                                  value: '${doctor.totalReviews}',
                                  label: 'Reviews',
                                  color: AppColors.secondary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (doctor.qualification != null) ...[
                              _SectionTitle(title: 'Qualifications'),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(doctor.qualification!),
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (doctor.bio != null) ...[
                              _SectionTitle(title: 'About'),
                              const SizedBox(height: 8),
                              Text(
                                doctor.bio!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (doctor.hospitalName != null) ...[
                              _SectionTitle(title: 'Practice Location'),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.local_hospital,
                                          color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            doctor.hospitalName!,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (doctor.hospitalAddress != null)
                                            Text(
                                              doctor.hospitalAddress!,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textHint,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            _SectionTitle(title: 'Available Days'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                                  .map((day) => Chip(
                                        label: Text(day),
                                        backgroundColor: doctor.availableDays.contains(day)
                                            ? AppColors.primary.withValues(alpha: 0.1)
                                            : null,
                                        side: BorderSide(
                                          color: doctor.availableDays.contains(day)
                                              ? AppColors.primary
                                              : AppColors.border,
                                        ),
                                        labelStyle: TextStyle(
                                          color: doctor.availableDays.contains(day)
                                              ? AppColors.primary
                                              : AppColors.textHint,
                                          fontSize: 13,
                                        ),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 20),
                            if (doctor.consultationFee > 0) ...[
                              _SectionTitle(title: 'Consultation fee (pay at clinic)'),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'PKR ${doctor.consultationFee.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '/ visit',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Pay at clinic',
                                        style: TextStyle(
                                          color: AppColors.secondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 32),
                            const Text(
                              'Free to book on DocBook. No online payment — pay the doctor at your visit.',
                              style: TextStyle(fontSize: 13, color: AppColors.textHint),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  context.push('/patient/book/${doctor.id}');
                                },
                                icon: const Icon(Icons.calendar_month),
                                label: const Text('Confirm Appointment'),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}
