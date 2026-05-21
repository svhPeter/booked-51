import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_provider.dart';
import '../../models/admin_models.dart';

class AdminPatientsScreen extends ConsumerStatefulWidget {
  const AdminPatientsScreen({super.key});

  @override
  ConsumerState<AdminPatientsScreen> createState() => _AdminPatientsScreenState();
}

class _AdminPatientsScreenState extends ConsumerState<AdminPatientsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).fetchPatients());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All Patients')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminProvider.notifier).fetchPatients(),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(AdminState state) {
    if (state.isLoading && state.patients.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(adminProvider.notifier).fetchPatients(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (state.patients.isEmpty) {
      return const Center(child: Text('No patients found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: state.patients.length,
      itemBuilder: (context, index) {
        final pat = state.patients[index];
        return _PatientCard(patient: pat);
      },
    );
  }
}

class _PatientCard extends ConsumerWidget {
  final AdminPatient patient;
  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Text(patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?'),
        ),
        title: Text(patient.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(patient.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!patient.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                child: const Text('Inactive', style: TextStyle(fontSize: 11, color: Colors.red)),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => _showPatientDetail(context, ref, patient),
      ),
    );
  }
}

void _showPatientDetail(BuildContext context, WidgetRef ref, AdminPatient patient) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
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
                  backgroundColor: Colors.green.shade100,
                  child: Text(patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: Text(patient.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
              Center(child: Text(patient.email, style: const TextStyle(color: Colors.grey))),
              Center(child: Text(patient.phone)),
              const Divider(height: 32),
              _detailRow('Gender', patient.gender.isNotEmpty ? patient.gender : 'N/A'),
              _detailRow('Blood Group', patient.bloodGroup.isNotEmpty ? patient.bloodGroup : 'N/A'),
              _detailRow('DOB', patient.dob ?? 'N/A'),
              _detailRow('Status', patient.isActive ? 'Active' : 'Inactive'),
              _detailRow('Verified', patient.isVerified ? 'Yes' : 'No'),
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
