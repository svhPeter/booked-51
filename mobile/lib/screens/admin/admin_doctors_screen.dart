import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_provider.dart';
import '../../models/admin_models.dart';

class AdminDoctorsScreen extends ConsumerStatefulWidget {
  const AdminDoctorsScreen({super.key});

  @override
  ConsumerState<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

class _AdminDoctorsScreenState extends ConsumerState<AdminDoctorsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).fetchDoctors());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All Doctors')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminProvider.notifier).fetchDoctors(),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(AdminState state) {
    if (state.isLoading && state.doctors.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(adminProvider.notifier).fetchDoctors(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (state.doctors.isEmpty) {
      return const Center(child: Text('No doctors found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: state.doctors.length,
      itemBuilder: (context, index) {
        final doc = state.doctors[index];
        return _DoctorCard(doc: doc);
      },
    );
  }
}

class _DoctorCard extends ConsumerWidget {
  final AdminDoctor doc;
  const _DoctorCard({required this.doc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(doc.name.isNotEmpty ? doc.name[0].toUpperCase() : '?'),
        ),
        title: Text(doc.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${doc.specialty}  •  Rs. ${doc.consultationFee.toStringAsFixed(0)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!doc.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                child: const Text('Inactive', style: TextStyle(fontSize: 11, color: Colors.red)),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => _showDoctorDetail(context, ref, doc),
      ),
    );
  }
}

void _showDoctorDetail(BuildContext context, WidgetRef ref, AdminDoctor doc) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(doc.name.isNotEmpty ? doc.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: Text(doc.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
              Center(child: Text(doc.email, style: const TextStyle(color: Colors.grey))),
              Center(child: Text(doc.phone)),
              const Divider(height: 32),
              _detailRow('Specialty', doc.specialty),
              _detailRow('Qualification', doc.qualification),
              _detailRow('Experience', doc.experience),
              _detailRow('Years', '${doc.yearsOfExperience} yrs'),
              _detailRow('Fee', 'Rs. ${doc.consultationFee.toStringAsFixed(0)}'),
              _detailRow('Rating', '${doc.averageRating.toStringAsFixed(1)} / 5 (${doc.totalReviews} reviews)'),
              _detailRow('Available Days', doc.availableDays.join(', ')),
              _detailRow('Hospital', '${doc.hospitalName}${doc.hospitalCity.isNotEmpty ? ', ${doc.hospitalCity}' : ''}'),
              _detailRow('Status', doc.isActive ? 'Active' : 'Inactive'),
              _detailRow('Verified', doc.isVerified ? 'Yes' : 'No'),
            ],
          ),
        );
      },
    ),
  );
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey))),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
