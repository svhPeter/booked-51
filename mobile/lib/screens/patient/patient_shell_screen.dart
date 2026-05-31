import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'my_appointments_screen.dart';
import 'patient_profile_screen.dart';
import '../common/conversations_screen.dart';

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

  static const _tabs = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItem(Icons.search_rounded, Icons.search_rounded, 'Search'),
    _NavItem(Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Appointments'),
    _NavItem(Icons.chat_bubble_outline, Icons.chat_bubble_rounded, 'Inbox'),
    _NavItem(Icons.person_outline, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const PatientHomeScreen(embedded: true),
      const SearchScreen(),
      const MyAppointmentsScreen(embedded: true),
      const ConversationsScreen(),
      const PatientProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        height: 64,
        child: SafeArea(
          top: false,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final item = _tabs[i];
              final selected = i == _index;
              return Expanded(
                child: _StitchNavItem(
                  item: item,
                  selected: selected,
                  onTap: () => setState(() => _index = i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.icon, this.selectedIcon, this.label);
}

class _StitchNavItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _StitchNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: BoxDecoration(
          color: selected
              ? (isDark
                  ? const Color(0xFF064E3B)
                  : const Color(0xFF86F2E4))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? item.selectedIcon : item.icon,
              size: 22,
              color: selected
                  ? (isDark
                      ? const Color(0xFF86F2E4)
                      : const Color(0xFF006F66))
                  : const Color(0xFF434653),
              fill: selected ? 1.0 : 0.0,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? (isDark
                          ? const Color(0xFF86F2E4)
                          : const Color(0xFF006F66))
                      : const Color(0xFF434653),
                  letterSpacing: 0.02,
                ),
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
