import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/doctor.dart';
import '../../providers/doctor_provider.dart';
import '../../widgets/ui_components.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialSpecialty;

  const SearchScreen({super.key, this.initialSpecialty});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final spec = widget.initialSpecialty;
      if (spec != null && spec.isNotEmpty) {
        ref.read(doctorProvider.notifier).setSpecialty(spec);
      } else {
        ref.read(doctorProvider.notifier).fetchDoctors();
      }
      ref.read(doctorProvider.notifier).fetchSpecialties();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Doctor'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, specialty...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          ref.read(doctorProvider.notifier).fetchDoctors();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  if (value.length >= 2) {
                    ref.read(doctorProvider.notifier).searchDoctors(value);
                  } else if (value.isEmpty) {
                    ref.read(doctorProvider.notifier).fetchDoctors();
                  }
                });
              },
            ),
          ),
          if (doctorState.specialties.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _SpecialtyChip(
                    label: 'All',
                    isSelected: doctorState.selectedSpecialty.isEmpty,
                    onTap: () {
                      ref.read(doctorProvider.notifier).setSpecialty('');
                      ref.read(doctorProvider.notifier).fetchDoctors();
                    },
                  ),
                  ...doctorState.specialties.map((spec) => _SpecialtyChip(
                        label: spec,
                        isSelected: doctorState.selectedSpecialty == spec,
                        onTap: () {
                          ref.read(doctorProvider.notifier).setSpecialty(spec);
                          ref.read(doctorProvider.notifier).searchDoctors(spec);
                        },
                      )),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: doctorState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : doctorState.doctors.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.search_off_rounded,
                        title: 'No doctors found',
                        subtitle: 'Try a different name or specialty',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: doctorState.doctors.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _DoctorCard(
                            doctor: doctorState.doctors[index],
                            onTap: () => context.push(
                              '/patient/doctor/${doctorState.doctors[index].id}',
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpecialtyChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onTap;

  const _DoctorCard({required this.doctor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant, width: 0.5),
          boxShadow: context.isDarkMode ? AppShadows.darkSm : AppShadows.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: scheme.primary.withValues(alpha: 0.2),
                  backgroundImage: doctor.avatarUrl != null
                      ? NetworkImage(doctor.avatarUrl!)
                      : null,
                  child: doctor.avatarUrl == null
                      ? Text(
                          doctor.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: doctor.isAvailable ? AppColors.online : AppColors.offline,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Dr. ${doctor.name}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (doctor.pmdcRegistrationNumber != null &&
                          doctor.pmdcRegistrationNumber!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: scheme.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(Icons.verified_rounded,
                              color: scheme.secondary, size: 14),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.specialty,
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: AppColors.rating),
                      const SizedBox(width: 4),
                      Text(
                        doctor.averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        ' (${doctor.totalReviews})',
                        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: doctor.isAvailable ? AppColors.online : AppColors.offline,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        doctor.isAvailable ? 'Available' : 'Unavailable',
                        style: TextStyle(
                          fontSize: 11,
                          color: doctor.isAvailable ? AppColors.online : AppColors.offline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ModeLabel(
                        icon: Icons.videocam_rounded,
                        label: 'Video',
                        color: const Color(0xFF0D9488),
                      ),
                      const SizedBox(width: 8),
                      _ModeLabel(
                        icon: Icons.business_rounded,
                        label: 'Clinic',
                        color: scheme.primary,
                      ),
                      const Spacer(),
                      if (doctor.consultationFee > 0)
                        Text(
                          'PKR ${doctor.consultationFee.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                        )
                      else
                        Text(
                          'Free',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: scheme.secondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ModeLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
