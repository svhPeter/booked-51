import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../providers/doctor_provider.dart';
import '../../widgets/ui_components.dart';

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

  void _shareProfile() {
    final url = 'https://docbook.pk/doctor/${widget.doctorId}';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Doctor profile link copied to clipboard!'),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showReportDialog() {
    String? selectedReason;
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Report an Issue'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('What would you like to report?',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                ...['wrong_doctor_info', 'wrong_clinic_address', 'doctor_unavailable', 'other'].map((reason) {
                  final label = {
                    'wrong_doctor_info': 'Wrong doctor information',
                    'wrong_clinic_address': 'Wrong clinic address',
                    'doctor_unavailable': 'Doctor unavailable',
                    'other': 'Other',
                  }[reason]!;
                  return RadioListTile<String>(
                    title: Text(label, style: const TextStyle(fontSize: 14)),
                    value: reason,
                    groupValue: selectedReason,
                    dense: true,
                    onChanged: (v) => setDialogState(() => selectedReason = v),
                  );
                }),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Describe the issue...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedReason == null || descController.text.trim().length < 5
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      try {
                        final apiClient = ref.read(apiClientProvider);
                        await apiClient.post('/reports', data: {
                          'reason': selectedReason,
                          'description': descController.text.trim(),
                          'doctorId': widget.doctorId,
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Report submitted. Thank you!'),
                              backgroundColor: AppColors.secondary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to submit report: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
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
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.share_rounded, color: Colors.white),
                          tooltip: 'Share profile',
                          onPressed: _shareProfile,
                        ),
                        IconButton(
                          icon: const Icon(Icons.flag_outlined, color: Colors.white70),
                          tooltip: 'Report issue',
                          onPressed: _showReportDialog,
                        ),
                      ],
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
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        doctor.specialty,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white.withValues(alpha: 0.95),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
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
                            // Trust badges row
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _TrustChip(
                                  icon: Icons.verified_user_rounded,
                                  label: 'Verified & Approved',
                                  color: AppColors.verified,
                                ),
                                if (doctor.pmdcRegistrationNumber != null &&
                                    doctor.pmdcRegistrationNumber!.isNotEmpty)
                                  _TrustChip(
                                    icon: Icons.badge_rounded,
                                    label: 'PMDC: ${doctor.pmdcRegistrationNumber}',
                                    color: AppColors.primary,
                                  ),
                                _TrustChip(
                                  icon: Icons.schedule_rounded,
                                  label: 'Doctor confirms timing',
                                  color: AppColors.info,
                                ),
                                _TrustChip(
                                  icon: Icons.money_off_rounded,
                                  label: 'No platform fee',
                                  color: AppColors.secondary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
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
                              _SectionTitle(title: 'Consultation Fee'),
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
                            const SizedBox(height: 24),
                            // Share booking link
                            OutlinedButton.icon(
                              onPressed: () {
                                final url = 'https://docbook.pk/book/${doctor.id}';
                                Clipboard.setData(ClipboardData(text: url));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Booking link copied!'),
                                    backgroundColor: AppColors.secondary,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.link_rounded, size: 18),
                              label: const Text('Copy Booking Link'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 44),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Free to request on DocBook. No platform fee\u2009—\u2009pay the doctor/clinic directly at your visit.',
                              style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
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
                                label: const Text('Request Appointment'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Center(
                              child: Text(
                                'Doctor/clinic will confirm your final appointment time.',
                                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
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

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TrustChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
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
