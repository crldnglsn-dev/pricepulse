import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';

/// Pending tabs — honest scaffolding shells so the bottom nav is complete.
/// Milestone 9 (Account) replaces this with the approved design from
/// design/03b §4. It reuses the EmptyState component and never pretends feature
/// work is present.

class AccountPendingScreen extends StatelessWidget {
  const AccountPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        automaticallyImplyLeading: false,
      ),
      body: const EmptyState(
        icon: Icons.person_outline_rounded,
        title: 'Account & sign-in coming later',
        body:
            'Authentication, profile, and settings arrive in a later '
            'milestone.',
      ),
    );
  }
}
