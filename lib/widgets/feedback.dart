import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../data/data_failure.dart';
import '../data/favorites_repository.dart';
import 'buttons.dart';

enum SnackbarKind { success, error, info }

/// App snackbar with a colored left rail. Spec: design/02 §2.8 `AppSnackbar`.
void showAppSnackbar(
  BuildContext context,
  String message, {
  SnackbarKind kind = SnackbarKind.info,
}) => _showAppSnackbar(ScaffoldMessenger.of(context), message, kind: kind);

/// Messenger-first variant, for callers that must fire a snackbar *after*
/// tearing down the widget they were invoked from (e.g. a dialog that pops).
void _showAppSnackbar(
  ScaffoldMessengerState messenger,
  String message, {
  required SnackbarKind kind,
}) {
  final (Color rail, IconData icon) = switch (kind) {
    SnackbarKind.success => (AppColors.success, Icons.check_rounded),
    SnackbarKind.error => (AppColors.error, Icons.error_outline_rounded),
    SnackbarKind.info => (AppColors.textMuted, Icons.info_outline_rounded),
  };

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: kind == SnackbarKind.error
            ? const Duration(seconds: 6)
            : const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(icon, size: 18, color: rail),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

/// Reports the outcome of a favorite write.
///
/// The copy is chosen by [scope], never hard-coded at the call site, because the
/// one thing this app must not do is tell the user their favorite is synced
/// when it is only on this device.
void showFavoriteResult(
  BuildContext context, {
  required bool succeeded,
  required bool saved,
  required FavoriteScope scope,
  DataFailure? failure,
}) {
  if (!succeeded) {
    showAppSnackbar(
      context,
      failure?.message ?? 'Could not save that favorite. Try again.',
      kind: SnackbarKind.error,
    );
    return;
  }
  final onDevice = scope == FavoriteScope.local ? ' on this device' : '';
  showAppSnackbar(
    context,
    saved
        ? 'Saved$onDevice. Sync to an account comes later.'
        : 'Removed from favorites$onDevice.',
    kind: SnackbarKind.info,
  );
}

/// Confirmation-style dialog. Spec: design/02 §2.8 `AppDialog`.
Future<bool?> showAppDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'OK',
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        PrimaryButton(
          label: confirmLabel,
          onPressed: () => Navigator.of(context).pop(true),
          expand: false,
          destructive: destructive,
        ),
      ],
    ),
  );
}

/// Link-unavailable dialog. Spec: design/03b §5.
///
/// `url` is non-null only when a URL exists but failed to launch — in that
/// case a "Copy link" action is offered; placeholder/missing links have
/// nothing to copy.
Future<void> showLinkUnavailableDialog(BuildContext context, {String? url}) {
  final messenger = ScaffoldMessenger.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Listing link unavailable'),
      content: const Text(
        'This marketplace link hasn’t been added yet. Try another store or '
        'check back later.',
      ),
      actions: [
        if (url != null && url.isNotEmpty)
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              _showAppSnackbar(
                messenger,
                'Link copied to clipboard',
                kind: SnackbarKind.success,
              );
            },
            child: const Text('Copy link'),
          ),
        PrimaryButton(
          label: 'OK',
          onPressed: () => Navigator.of(dialogContext).pop(),
          expand: false,
        ),
      ],
    ),
  );
}
