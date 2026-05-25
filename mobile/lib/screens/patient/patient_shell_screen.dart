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
    final colorScheme = Theme.of(context).colorScheme;

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
        animationDuration: const Duration(milliseconds: 300),
        destinations: [
          NavigationDestination(
            icon: Icon(_index == 0 ? Icons.home : Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(_index == 1 ? Icons.search : Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(_index == 2 ? Icons.calendar_month : Icons.calendar_month_outlined),
            label: 'Appointments',
          ),
          NavigationDestination(
            icon: Icon(_index == 3 ? Icons.person : Icons.person_outline),
            label: 'Profile',
          ),
        ],
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            );
          }
          return TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),
    );
  }
}
