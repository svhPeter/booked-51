import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';

String homePathForRole(UserRole? role) {
  switch (role) {
    case UserRole.admin:
      return '/admin/dashboard';
    case UserRole.doctor:
      return '/doctor/dashboard';
    case UserRole.patient:
    default:
      return '/patient/home';
  }
}

class RoleMenuButton extends ConsumerWidget {
  final String? profileRoute;

  const RoleMenuButton({super.key, this.profileRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            if (profileRoute != null) context.push(profileRoute!);
            break;
          case 'notifications':
            context.push('/notifications');
            break;
          case 'logout':
            try {
              await ref.read(authProvider.notifier).logout();
            } catch (_) {
              await ref.read(authProvider.notifier).logout();
            }
            if (context.mounted) context.go('/auth/login');
            break;
        }
      },
      itemBuilder: (context) => [
        if (profileRoute != null)
          const PopupMenuItem(value: 'profile', child: Text('My Profile')),
        const PopupMenuItem(value: 'notifications', child: Text('Notifications')),
        const PopupMenuItem(value: 'logout', child: Text('Sign Out')),
      ],
      icon: const Icon(Icons.more_vert),
    );
  }
}
