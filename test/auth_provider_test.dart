import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:pricepulse/data/auth_service.dart';
import 'package:pricepulse/data/data_failure.dart';
import 'package:pricepulse/providers/auth_provider.dart';

/// Tests for [AuthProvider].
///
/// The provider is the seam where a Firebase swap will happen, so its contract
/// matters more than its size: a failed attempt must leave the user signed
/// out, and a failure must always be explainable.
void main() {
  group('AuthProvider', () {
    test('starts signed out', () async {
      final provider = AuthProvider(_FakeAuthService());
      await provider.load();

      expect(provider.isSignedIn, isFalse);
      expect(provider.user, isNull);
      provider.dispose();
    });

    test('reports whether the build can authenticate at all', () async {
      final provider = AuthProvider(_FakeAuthService(canAuthenticate: false));
      await provider.load();

      expect(provider.canAuthenticate, isFalse);
      provider.dispose();
    });

    test('a successful sign in exposes the user', () async {
      final provider = AuthProvider(_FakeAuthService());
      await provider.load();

      final ok = await provider.signIn(email: 'a@b.co', password: 'password');

      expect(ok, isTrue);
      expect(provider.isSignedIn, isTrue);
      expect(provider.user?.email, 'angela.santos@gmail.com');
      expect(provider.lastFailure, isNull);
      provider.dispose();
    });

    test('a failed sign in leaves the user signed out', () async {
      final provider = AuthProvider(_FakeAuthService(failWith: true));
      await provider.load();

      final ok = await provider.signIn(email: 'a@b.co', password: 'wrong');

      expect(ok, isFalse);
      expect(provider.isSignedIn, isFalse);
      expect(provider.user, isNull);
      expect(provider.lastFailure, isNotNull);
      provider.dispose();
    });

    test(
      'a failed sign in does not leave the previous failure in place',
      () async {
        final service = _FakeAuthService(failWith: true);
        final provider = AuthProvider(service);
        await provider.load();

        await provider.signIn(email: 'a@b.co', password: 'wrong');
        expect(provider.lastFailure, isNotNull);

        service.failWith = false;
        await provider.signIn(email: 'a@b.co', password: 'password');

        expect(provider.lastFailure, isNull);
        provider.dispose();
      },
    );

    test('register signs the user in', () async {
      final provider = AuthProvider(_FakeAuthService());
      await provider.load();

      final ok = await provider.register(
        email: 'a@b.co',
        password: 'password',
        displayName: 'Angela Santos',
      );

      expect(ok, isTrue);
      expect(provider.isSignedIn, isTrue);
      provider.dispose();
    });

    test('signing out clears the user', () async {
      final provider = AuthProvider(_FakeAuthService());
      await provider.load();
      await provider.signIn(email: 'a@b.co', password: 'password');

      final ok = await provider.signOut();

      expect(ok, isTrue);
      expect(provider.isSignedIn, isFalse);
      expect(provider.user, isNull);
      provider.dispose();
    });

    test('a failed sign out keeps the session and records why', () async {
      final service = _FakeAuthService();
      final provider = AuthProvider(service);
      await provider.load();
      await provider.signIn(email: 'a@b.co', password: 'password');

      service.failSignOut = true;
      final ok = await provider.signOut();

      expect(ok, isFalse);
      expect(provider.isSignedIn, isTrue);
      expect(provider.lastFailure, isNotNull);
      provider.dispose();
    });

    test('a stream error is recorded as a failure, not swallowed', () async {
      final service = _FakeAuthService();
      final provider = AuthProvider(service);
      await provider.load();

      service.emitError();
      await Future<void>.delayed(Duration.zero);

      expect(provider.lastFailure, isNotNull);
      provider.dispose();
    });
  });
}

/// An auth service with a session, so the provider can be driven in tests.
class _FakeAuthService implements AuthService {
  _FakeAuthService({this.canAuthenticate = true, this.failWith = false})
    : _controller = StreamController<AuthUser?>() {
    // The contract: the stream emits the current state immediately, even to a
    // caller that subscribes late. A single-subscription controller buffers it
    // until the provider listens.
    _controller.add(null);
  }

  @override
  bool canAuthenticate;

  bool failWith;
  bool failSignOut = false;

  AuthUser? _user;

  final StreamController<AuthUser?> _controller;

  static const _account = AuthUser(
    uid: 'u1',
    email: 'angela.santos@gmail.com',
    displayName: 'Angela Santos',
  );

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  void emitError() => _controller.addError(const UnexpectedFailure());

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    if (failWith) {
      throw const NotAuthenticatedFailure('Incorrect email or password.');
    }
    _user = _account;
    return _account;
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (failWith) {
      throw const NotAuthenticatedFailure('This email is already in use.');
    }
    _user = _account;
    return _account;
  }

  @override
  Future<void> signOut() async {
    if (failSignOut) {
      throw const UnreachableFailure('Could not reach the sign-out service.');
    }
    _user = null;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}
}
