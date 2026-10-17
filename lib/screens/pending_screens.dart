import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';

/// Pending tabs — honest scaffolding shells so the bottom nav is complete.
/// Milestones 8 (Favorites) and 9 (Account) replace these with the approved
/// designs from design/03b. They reuse the EmptyState component and never
/// pretend feature work is present.

class FavoritesPendingScreen extends StatelessWidget {
  const FavoritesPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        automaticallyImplyLeading: false,
      ),
      body: const EmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'No favorites yet',
        body: 'Sign-in and cloud-synced favorites arrive in a later milestone.',
      ),
    );
  }
}

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
        body: 'Authentication, profile, and settings arrive in a later milestone.',
      ),
    );
  }
}
