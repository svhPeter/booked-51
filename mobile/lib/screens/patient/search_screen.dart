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
    final isDark = context.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant, width: 0.5),
          boxShadow: isDark ? AppShadows.darkSm : AppShadows.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor avatar with verified badge (Stitch-style)
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
                if (doctor.pmdcRegistrationNumber != null &&
                    doctor.pmdcRegistrationNumber!.isNotEmpty)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. ${doctor.name}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
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
                  // Rating + experience row (Stitch-style)
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text(
                        doctor.averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${doctor.totalReviews})',
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('•', style: TextStyle(color: Color(0xFFC3C6D5))),
                      ),
                      Text(
                        '${doctor.yearsOfExperience}+ yrs',
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Location (Stitch-style)
                  if (doctor.hospitalName != null)
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            doctor.hospitalName!,
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  // Fee + availability row (Stitch-style)
                  Row(
                    children: [
                      // Availability badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: doctor.isAvailable
                              ? const Color(0xFF86F2E4).withValues(alpha: 0.2)
                              : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              doctor.isAvailable ? Icons.event_available_rounded : Icons.calendar_month_rounded,
                              size: 12,
                              color: doctor.isAvailable ? const Color(0xFF006A61) : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              doctor.isAvailable ? 'Available Today' : 'Next Avail: Soon',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: doctor.isAvailable ? const Color(0xFF006A61) : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        doctor.consultationFee > 0
                            ? 'PKR ${doctor.consultationFee.toStringAsFixed(0)}'
                            : 'Free',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: doctor.consultationFee > 0 ? scheme.onSurface : scheme.secondary,
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

