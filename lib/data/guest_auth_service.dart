import 'dart:async';

import 'auth_service.dart';
import 'data_failure.dart';

/// The prototype's [AuthService]: there is no backend, so there is no user.
///
/// This is a real implementation of the contract rather than a stub. The one
/// thing that matters is [canAuthenticate], which is false — the UI reads it to
/// decide between a sign-in form and an honest notice. When Firebase Auth
/// arrives this class is replaced by one that talks to it; the interface, the
/// provider and the screen do not change.
class GuestAuthService implements AuthService {
  @override
  AuthUser? get currentUser => null;

  @override
  bool get canAuthenticate => false;

  @override
  Stream<AuthUser?> authStateChanges() => Stream<AuthUser?>.value(null);

  @override
  Future<AuthUser> signIn({required String email, required String password}) =>
      _unsupported();

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
    String? displayName,
  }) => _unsupported();

  @override
  Future<void> signOut() async {
    // Idempotent. There is no session to clear, so signing out is a no-op
    // rather than an error, and a double tap cannot throw.
  }

  @override
  Future<void> sendPasswordReset(String email) => _unsupported();

  /// The honest reason this build cannot sign anyone in.
  ///
  /// Phrased as something the reader can act on — they are told where their
  /// favorites actually are, rather than being handed a bare error.
  Never _unsupported() => throw const UnsupportedOperationFailure(
    'Accounts are not part of this build yet. Your favorites are saved on '
    'this device and work without signing in.',
  );
}
