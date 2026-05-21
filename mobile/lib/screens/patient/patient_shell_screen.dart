import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'my_appointments_screen.dart';
import 'patient_profile_screen.dart';

class PatientShellScreen extends StatefulWidget {
  final int initialIndex;

  const PatientShellScreen({super.key, this.initialIndex = 0});

  @override
  State<PatientShellScreen> createState() => _PatientShellScreenState();
}

class _PatientShellScreenState extends State<PatientShellScreen> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const PatientHomeScreen(embedded: true),
      const SearchScreen(),
      const MyAppointmentsScreen(embedded: true),
      const PatientProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Appointments'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
