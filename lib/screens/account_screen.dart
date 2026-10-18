import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/account_header.dart';
import '../widgets/feedback.dart';
import '../widgets/settings_row.dart';

/// Account.
///
/// Spec: design/03b §4, with the deviations the prototype requires:
/// - The privacy dialog states what this build stores. The spec's §4.3 text
///   mentions Cloud Firestore, which is not in this build, and design QA §3.5
///   requires the privacy dialog to match stored data exactly.
/// - The spec's §4.4 caption "Saving favorites requires an account" is
///   corrected. Favorites work *without* an account here, so the opposite is
///   true and the original wording would be a lie.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, this.onFavoritesTap});

  /// Takes the user to the Favorites tab.
  final VoidCallback? onFavoritesTap;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        automaticallyImplyLeading: false,
      ),
      body: AppLayout.centerContent(
        ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          children: [
            if (user == null)
              SignedOutAccountHeader(
                canAuthenticate: auth.canAuthenticate,
                onAccountAction: (title) => _showAccountNotice(context, title),
              )
            else
              SignedInProfileHeader(user: user),
            const SizedBox(height: AppSpacing.xl),
            SettingsCard(
              children: [
                SettingsRow(
                  icon: Icons.favorite_border_rounded,
                  title: 'My favorites',
                  trailing: Text(
                    _countLabel(favorites),
                    style: AppTypography.caption,
                  ),
                  onTap: onFavoritesTap,
                ),
                SettingsRow(
                  icon: Icons.smartphone_rounded,
                  title: 'Where favorites live',
                  // The Favorites tab carries this as a status chip. Here the
                  // chip would squeeze the title into an awkward wrap, so the
                  // same fact is stated in words — and uses the chip's exact
                  // wording, so the two screens cannot disagree.
                  subtitle: 'On this device. Not synced to an account.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsCard(
              children: [
                SettingsRow(
                  icon: Icons.info_outline_rounded,
                  title: 'App info',
                  subtitle: 'Version 1.0.0 (build 1)',
                  onTap: () => _showAppInfo(context),
                ),
                SettingsRow(
                  icon: Icons.lock_outline_rounded,
                  title: 'Privacy & data',
                  onTap: () => _showPrivacy(context),
                ),
              ],
            ),
            if (user != null) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => _confirmSignOut(context),
                  child: Text(
                    'Log out',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The favorites count, or a dash while the store is still loading.
  ///
  /// A dash rather than a zero: showing "0" would claim the user has no
  /// favorites when the answer is not known yet.
  static String _countLabel(FavoritesProvider favorites) =>
      favorites.status == FavoritesStatus.loading
      ? '—'
      : '${favorites.favorites.length} saved';
}

/// Explains that this build has no accounts, instead of pretending otherwise.
Future<void> _showAccountNotice(BuildContext context, String title) =>
    showInfoDialog(
      context,
      title: title,
      points: const [
        'Accounts are not part of this prototype build.',
        'Your favorites are saved on this device and work without signing in.',
        'The data layer is already built to swap in a cloud account later.',
      ],
    );

Future<void> _showAppInfo(BuildContext context) => showInfoDialog(
  context,
  title: 'App info',
  points: const [
    'PricePulse 1.0.0 (build 1).',
    'Built with Flutter. Favorites are kept in this device\'s local app '
        'storage — nothing is uploaded.',
    'Product prices are recorded by hand from each store\'s listing, together '
        'with the date they were read.',
    'Built as an academic prototype.',
  ],
);

Future<void> _showPrivacy(BuildContext context) => showInfoDialog(
  context,
  title: 'Privacy & data',
  points: const [
    'Your favorites are stored on this device only. Nothing is uploaded, and '
        'this build has no account to attach to.',
    'Product prices are recorded records — they are not fetched live from '
        'store APIs.',
    'Opening a listing hands off to the store\'s app or website. PricePulse '
        'does not collect store-side data.',
    'Removing the app removes your favorites with it.',
  ],
);

/// Signs the user out after they confirm. Spec: design/03b §4.2.
Future<void> _confirmSignOut(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  final confirmed = await showAppDialog(
    context,
    title: 'Log out of PricePulse?',
    message: 'Your favorites stay on this device.',
    confirmLabel: 'Log out',
    destructive: true,
  );
  if (confirmed != true || !context.mounted) return;

  final ok = await auth.signOut();
  if (!context.mounted) return;
  showAppSnackbar(
    context,
    ok
        ? 'You\'ve been logged out.'
        : auth.lastFailure?.message ?? 'Could not log out. Try again.',
    kind: ok ? SnackbarKind.success : SnackbarKind.error,
  );
}
