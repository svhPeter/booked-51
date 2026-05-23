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
                if (value.length >= 2) {
                  ref.read(doctorProvider.notifier).searchDoctors(value);
                } else if (value.isEmpty) {
                  ref.read(doctorProvider.notifier).fetchDoctors();
                }
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
                    : const EmptyStateWidget(
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
              backgroundImage: doctor.avatarUrl != null
                  ? NetworkImage(doctor.avatarUrl!)
                  : null,
              child: doctor.avatarUrl == null
                  ? Text(
                      doctor.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
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
                  const SizedBox(height: 4),
                  Text(
                    doctor.specialty,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: AppColors.rating),
                      const SizedBox(width: 4),
                      Text(
                        doctor.averageRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        ' (${doctor.totalReviews})',
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.textHint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: doctor.isAvailable ? AppColors.online : AppColors.offline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        doctor.isAvailable ? 'Available' : 'Unavailable',
                        style: TextStyle(
                          fontSize: 12,
                          color: doctor.isAvailable ? AppColors.online : AppColors.offline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  'PKR ${doctor.consultationFee.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fee',
                  style: TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
