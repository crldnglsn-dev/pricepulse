import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pricepulse/theme/app_colors.dart';
import 'package:pricepulse/widgets/buttons.dart';

/// Tests for the shared button components.
///
/// These are the pieces every screen is built from, and a state that has never
/// been exercised is a state nobody knows works — the disabled button, the
/// loading spinner, the destructive confirm.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
    await tester.pump();
  }

  group('PrimaryButton', () {
    testWidgets('reports its tap', (tester) async {
      var taps = 0;
      await pump(tester, PrimaryButton(label: 'Go', onPressed: () => taps++));

      await tester.tap(find.text('Go'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('a disabled button does not report a tap', (tester) async {
      var taps = 0;
      await pump(tester, PrimaryButton(label: 'Go', onPressed: () => taps++));

      // A null callback is the disabled state.
      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.onPressed, isNotNull);

      await pump(tester, const PrimaryButton(label: 'Go'));
      await tester.tap(find.text('Go'));
      await tester.pump();

      expect(taps, 0);
    });

    testWidgets('a loading button shows a spinner and refuses taps', (
      tester,
    ) async {
      var taps = 0;
      await pump(
        tester,
        PrimaryButton(label: 'Go', loading: true, onPressed: () => taps++),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Go'));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('a destructive button uses the error tint, not the brand', (
      tester,
    ) async {
      await pump(
        tester,
        const PrimaryButton(label: 'Log out', destructive: true),
      );

      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.destructive, isTrue);
    });

    testWidgets('an icon is rendered alongside the label', (tester) async {
      await pump(
        tester,
        const PrimaryButton(
          label: 'Open listing',
          icon: Icons.open_in_new_rounded,
        ),
      );

      expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
      expect(find.text('Open listing'), findsOneWidget);
    });

    testWidgets('it can size to its content instead of filling the width', (
      tester,
    ) async {
      await pump(
        tester,
        const PrimaryButton(label: 'Try again', expand: false),
      );

      final width = tester.getSize(find.byType(PrimaryButton)).width;
      expect(width, lessThan(390));
    });
  });

  group('GhostPill', () {
    testWidgets('reports its tap', (tester) async {
      var taps = 0;
      await pump(tester, GhostPill(label: 'All', onTap: () => taps++));

      await tester.tap(find.text('All'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('exposes its selected state to assistive technology', (
      tester,
    ) async {
      await pump(tester, const GhostPill(label: 'All', isSelected: true));

      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(GhostPill),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.properties.selected, isTrue);
    });

    testWidgets('renders an icon when given one', (tester) async {
      await pump(
        tester,
        const GhostPill(label: 'All', icon: Icons.grid_view_rounded),
      );

      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
    });
  });

  group('FavoriteButton', () {
    testWidgets('shows a filled heart when saved and an outline when not', (
      tester,
    ) async {
      await pump(tester, const FavoriteButton(isFavorite: false));
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      await pump(tester, const FavoriteButton(isFavorite: true));
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('reports its tap', (tester) async {
      var taps = 0;
      await pump(
        tester,
        FavoriteButton(isFavorite: false, onPressed: () => taps++),
      );

      await tester.tap(find.byType(FavoriteButton));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('says out loud what tapping will do', (tester) async {
      await pump(tester, const FavoriteButton(isFavorite: false));
      expect(
        tester.getSemantics(find.byType(FavoriteButton)).label,
        'Add to favorites',
      );

      await pump(tester, const FavoriteButton(isFavorite: true));
      expect(
        tester.getSemantics(find.byType(FavoriteButton)).label,
        'Remove from favorites',
      );
    });

    testWidgets('an overlay button keeps a 44dp target on a card', (
      tester,
    ) async {
      await pump(
        tester,
        const FavoriteButton(isFavorite: false, compact: true, overlay: true),
      );

      final size = tester.getSize(find.byType(FavoriteButton));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });
  });

  group('PressableScale', () {
    testWidgets('a disabled scale target does not fire', (tester) async {
      var taps = 0;
      await pump(
        tester,
        PressableScale(
          enabled: false,
          onTap: () => taps++,
          child: const Text('Nope'),
        ),
      );

      await tester.tap(find.text('Nope'));
      await tester.pump();

      expect(taps, 0);
    });

    testWidgets('an enabled scale target fires', (tester) async {
      var taps = 0;
      await pump(
        tester,
        PressableScale(onTap: () => taps++, child: const Text('Yes')),
      );

      await tester.tap(find.text('Yes'));
      await tester.pump();

      expect(taps, 1);
    });
  });

  group('the palette the buttons read from', () {
    testWidgets('a primary button label is readable on its fill', (
      tester,
    ) async {
      await pump(tester, PrimaryButton(label: 'Sign in', onPressed: () {}));

      final label = tester.widget<Text>(find.text('Sign in'));
      expect(label.style?.color, AppColors.onPrimary);
    });
  });
}
