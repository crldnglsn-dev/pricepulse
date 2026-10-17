import 'dart:async';

import 'package:flutter/foundation.dart';

import 'data_failure.dart';

/// The signed-in user, or a guest.
///
/// A guest is a real state, not an error: browsing and comparing work with no
/// account, and `design/03b` §3.1 says so explicitly ("Explore as guest"). The
/// type makes it impossible to write `currentUser!` by accident.
@immutable
class AuthUser {
  const AuthUser({required this.uid, required this.email, this.displayName});

  final String uid;
  final String email;
  final String? displayName;
}

/// Authentication boundary. No backend today; Firebase Auth later.
///
/// ## Contract for implementers
///
/// - [authStateChanges] emits at least once, immediately, with the current
///   state — `null` for a guest. A caller that subscribes late must not wait.
/// - [signIn] and [register] throw [NotAuthenticatedFailure] on a rejected
///  credential, **never** a failure that reveals whether an account exists.
///  `design/03b` §3.4 requires the "if an account exists" phrasing so the form
///  cannot be used to enumerate accounts.
/// - Every method returns a [DataFailure]-throwing future. No bare exceptions.
abstract interface class AuthService {
  /// Current state, or `null` for a guest. Cheap and synchronous — the UI reads
  /// it during build.
  AuthUser? get currentUser;

  /// Whether this build can sign in at all. False in the prototype; the UI
  /// uses it to decide between a real form and an honest notice.
  bool get canAuthenticate;

  /// Emits on every sign-in, sign-out and token change, starting with the
  /// current value.
  Stream<AuthUser?> authStateChanges();

  /// Signs in. Throws [NotAuthenticatedFailure] on rejection.
  Future<AuthUser> signIn({required String email, required String password});

  /// Creates an account and signs in. Throws on rejection.
  Future<AuthUser> register({
    required String email,
    required String password,
    String? displayName,
  });

  /// Signs out. Idempotent: signing out when already signed out is a no-op,
  /// not an error, so a double-tap on a logout button cannot throw.
  Future<void> signOut();

  /// Sends a password reset.
  ///
  /// Returns normally whether or not an account exists — the result is
  /// identical on purpose, so this cannot be used to discover accounts.
  Future<void> sendPasswordReset(String email);
}
