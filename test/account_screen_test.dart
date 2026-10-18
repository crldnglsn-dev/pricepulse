import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pricepulse/data/auth_service.dart';
import 'package:pricepulse/data/favorites_repository.dart';
import 'package:pricepulse/data/in_memory_favorites_repository.dart';
import 'package:pricepulse/screens/account_screen.dart';
import 'package:pricepulse/theme/app_theme.dart';
import 'package:pricepulse/widgets/status_chip.dart';

import 'fixtures.dart';

/// Tests for the Account tab.
///
/// The Account tab is the screen most able to lie: it is where a prototype
/// would be tempted to show a profile, a sync status and a log-out button it
/// does not have. These tests pin the honest behaviour.
void main() {
  Future<void> pumpAccount(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1.0,
    AuthService? auth,
    FavoritesRepository? favorites,
    VoidCallback? onFavoritesTap,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: harnessProviders(
            AccountScreen(onFavoritesTap: onFavoritesTap),
            favorites: favorites,
            auth: auth,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Scrolls [target] into view inside the Account screen's list.
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find
          .descendant(
            of: find.byType(AccountScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  group('signed-out Account', () {
    testWidgets('shows the brand and the account entry', (tester) async {
      await pumpAccount(tester);

      expect(find.text('PricePulse'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
    });

    testWidgets('never offers a log out when there is no session', (
      tester,
    ) async {
      await pumpAccount(tester);

      expect(find.text('Log out'), findsNothing);
    });

    testWidgets('never claims favorites are synced', (tester) async {
      await pumpAccount(tester);

      expect(find.text('Synced'), findsNothing);
      expect(find.textContaining('On this device'), findsOneWidget);
      expect(find.textContaining('Not synced to an account'), findsOneWidget);
    });

    testWidgets('says plainly that accounts are not part of this build', (
      tester,
    ) async {
      await pumpAccount(tester);

      expect(
        find.textContaining('Accounts are not part of this prototype build'),
        findsWidgets,
      );
    });

    testWidgets('does not claim favorites need an account', (tester) async {
      // The spec's §4.4 caption says "Saving favorites requires an account".
      // That is backwards here: favorites work without one.
      await pumpAccount(tester);

      expect(find.textContaining('requires an account'), findsNothing);
    });
  });

  group('the privacy notice', () {
    testWidgets('matches what this build actually stores', (tester) async {
      await pumpAccount(tester);

      await scrollTo(tester, find.text('Privacy & data'));
      await tester.tap(find.text('Privacy & data'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(AlertDialog, 'Privacy & data'),
        findsOneWidget,
      );
      expect(find.textContaining('stored on this device only'), findsOneWidget);
      expect(find.textContaining('not fetched live'), findsOneWidget);
    });

    testWidgets('does not mention a cloud backend this build does not have', (
      tester,
    ) async {
      await pumpAccount(tester);

      await scrollTo(tester, find.text('Privacy & data'));
      await tester.tap(find.text('Privacy & data'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Firestore'), findsNothing);
      expect(find.textContaining('Cloud Firestore'), findsNothing);
    });
  });

  group('the sign-in entry', () {
    testWidgets('explains where favorites actually are', (tester) async {
      await pumpAccount(tester);

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Accounts are not part of this prototype build'),
        findsWidgets,
      );
      expect(find.textContaining('this device'), findsWidgets);
    });
  });

  group('favorites', () {
    testWidgets('shows the live count', (tester) async {
      final repo = InMemoryFavoritesRepository();
      await repo.toggle(productId: 'a', save: true);
      await repo.toggle(productId: 'b', save: true);

      await pumpAccount(tester, favorites: repo);

      expect(find.text('2 saved'), findsOneWidget);
    });

    testWidgets('tapping My favorites opens the Favorites tab', (tester) async {
      var tapped = false;
      await pumpAccount(tester, onFavoritesTap: () => tapped = true);

      await tester.tap(find.text('My favorites'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('signed-in Account', () {
    testWidgets('shows the name and the email', (tester) async {
      await pumpAccount(
        tester,
        auth: _FakeAuthService(
          const AuthUser(
            uid: 'u1',
            email: 'angela.santos@gmail.com',
            displayName: 'Angela Santos',
          ),
        ),
      );

      expect(find.text('Angela Santos'), findsOneWidget);
      expect(find.text('angela.santos@gmail.com'), findsOneWidget);
    });

    testWidgets('log out asks for confirmation first', (tester) async {
      await pumpAccount(
        tester,
        auth: _FakeAuthService(
          const AuthUser(uid: 'u1', email: 'angela.santos@gmail.com'),
        ),
      );

      await scrollTo(tester, find.text('Log out'));
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      expect(find.text('Log out of PricePulse?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Cancelling must leave the session alone.
      expect(find.text('Angela Santos'), findsNothing);
      expect(find.text('angela.santos@gmail.com'), findsOneWidget);
    });

    testWidgets('confirming log out clears the session', (tester) async {
      await pumpAccount(
        tester,
        auth: _FakeAuthService(
          const AuthUser(
            uid: 'u1',
            email: 'angela.santos@gmail.com',
            displayName: 'Angela Santos',
          ),
        ),
      );

      await scrollTo(tester, find.text('Log out'));
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log out').last);
      await tester.pumpAndSettle();

      expect(find.text('angela.santos@gmail.com'), findsNothing);
      expect(find.text('Sign in'), findsOneWidget);
    });
  });

  group('the favorites scope chip', () {
    test('never calls a local favorite synced', () {
      // The single worst lie this app could tell. Both screens render the
      // chip, so the wording is single-sourced and pinned here.
      expect(favoriteScopeChip(FavoriteScope.local).label, 'On this device');
      expect(favoriteScopeChip(FavoriteScope.cloud).label, 'Synced');
    });
  });

  group('resilience', () {
    for (final (label, size) in [
      ('320dp', Size(320, 640)),
      ('768dp', Size(768, 1024)),
      ('1440dp', Size(1440, 900)),
    ]) {
      testWidgets('lays out without overflow at $label', (tester) async {
        await pumpAccount(tester, size: size);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('survives a 200% text scale without overflow', (tester) async {
      await pumpAccount(tester, size: const Size(320, 640), textScale: 2.0);

      // Scroll to the bottom as well, so the rows that start off-screen are
      // laid out under the large text too.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

/// An auth service with a session, so the signed-in layout can be tested.
class _FakeAuthService implements AuthService {
  _FakeAuthService(this.user);

  AuthUser? user;

  @override
  AuthUser? get currentUser => user;

  @override
  bool get canAuthenticate => true;

  @override
  Stream<AuthUser?> authStateChanges() => Stream<AuthUser?>.value(user);

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async => user!;

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
    String? displayName,
  }) async => user!;

  @override
  Future<void> signOut() async {
    user = null;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}
}
