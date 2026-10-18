import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/auth_service.dart';
import '../data/data_failure.dart';

/// Holds the signed-in user, or the fact that there is none.
///
/// Sits between the UI and [AuthService], the same way [FavoritesProvider]
/// sits between the UI and [FavoritesRepository]. Its job is to make sure the
/// Account screen can never imply a session that does not exist: [canAuthenticate]
/// comes straight from the service, and a sign-in that fails leaves the user
/// signed out with [lastFailure] explaining why.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service);

  final AuthService _service;
  StreamSubscription<AuthUser?>? _subscription;

  AuthUser? _user;
  DataFailure? _lastFailure;

  /// The signed-in user, or null when browsing as a guest.
  AuthUser? get user => _user;

  bool get isSignedIn => _user != null;

  /// Whether this build can sign anyone in at all. False in the prototype.
  bool get canAuthenticate => _service.canAuthenticate;

  /// The most recent failure, or null.
  DataFailure? get lastFailure => _lastFailure;

  /// Starts listening for session changes.
  Future<void> load() async {
    await _subscription?.cancel();
    _subscription = _service.authStateChanges().listen(
      _onUser,
      onError: _onError,
    );
  }

  /// Signs in. Returns true on success.
  ///
  /// On failure nothing is cached, [lastFailure] is set, and the user stays
  /// signed out — a failed attempt must never look like a partial success.
  Future<bool> signIn({required String email, required String password}) =>
      _run(() => _service.signIn(email: email, password: password));

  /// Creates an account and signs in. Returns true on success.
  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
  }) => _run(
    () => _service.register(
      email: email,
      password: password,
      displayName: displayName,
    ),
  );

  /// Signs out. Returns true if the session is gone afterwards.
  Future<bool> signOut() async {
    try {
      await _service.signOut();
      _user = null;
      _lastFailure = null;
      notifyListeners();
      return true;
    } on Object catch (error) {
      _lastFailure = asDataFailure(error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> _run(Future<AuthUser> Function() action) async {
    _lastFailure = null;
    try {
      _user = await action();
      notifyListeners();
      return true;
    } on Object catch (error) {
      _lastFailure = asDataFailure(error);
      notifyListeners();
      return false;
    }
  }

  void _onUser(AuthUser? user) {
    _user = user;
    notifyListeners();
  }

  void _onError(Object error, StackTrace stackTrace) {
    _lastFailure = asDataFailure(error);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
