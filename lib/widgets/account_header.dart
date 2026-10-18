import 'package:flutter/material.dart';

import '../data/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/buttons.dart';

/// Headers for the Account screen.
///
/// Spec: design/03b §4.1 (signed-in) and §4.4 (signed-out).
///
/// Both are real. The prototype has no backend, so only the signed-out header
/// is reachable today — but the signed-in one is written against the
/// [AuthUser] contract rather than against Firebase, so swapping the service
/// in `app.dart` is the only change a signed-in build needs.

/// Signed-out header: brand lockup, tagline, and the account entry.
class SignedOutAccountHeader extends StatelessWidget {
  const SignedOutAccountHeader({
    super.key,
    required this.onAccountAction,
    required this.canAuthenticate,
  });

  /// Called with the title of the action the user chose.
  final void Function(String title) onAccountAction;

  /// Whether this build can sign anyone in at all.
  final bool canAuthenticate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.trending_down_rounded,
            size: 30,
            color: AppColors.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('PricePulse', style: AppTypography.display),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Compare recorded prices across Shopee, Lazada & TikTok Shop.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySecondary,
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Sign in',
          onPressed: () => onAccountAction('Sign in'),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextButton(
          onPressed: () => onAccountAction('Create account'),
          child: Text(
            'Create account',
            style: AppTypography.labelLarge.copyWith(color: AppColors.link),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          canAuthenticate
              ? 'Sign in to keep your favorites on your account.'
              : 'Accounts are not part of this prototype build. Favorites are '
                    'saved on this device and work without signing in.',
          textAlign: TextAlign.center,
          style: AppTypography.captionMuted,
        ),
      ],
    );
  }
}

/// Signed-in header: avatar, display name, email.
///
/// Spec: design/03b §4.1. There is no edit-profile control — the spec rules it
/// out of the prototype, and a control that does nothing is worse than none.
class SignedInProfileHeader extends StatelessWidget {
  const SignedInProfileHeader({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final name = user.displayName?.trim();
    final hasName = name != null && name.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              _initial(name, user.email),
              style: AppTypography.avatarInitial,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasName ? name : user.email,
                  style: AppTypography.headline2,
                ),
                // Without a display name the email is already the heading, so
                // it is not repeated underneath.
                if (hasName) ...[
                  const SizedBox(height: 2),
                  Text(user.email, style: AppTypography.captionMuted),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The first letter of the display name, else of the email, else a mark.
  static String _initial(String? name, String email) {
    final source = (name != null && name.isNotEmpty) ? name : email;
    if (source.isEmpty) return '?';
    return source.characters.first.toUpperCase();
  }
}
