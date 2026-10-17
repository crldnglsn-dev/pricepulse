import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:pricepulse/models/offer.dart';
import 'package:pricepulse/models/product.dart';
import 'package:pricepulse/screens/product_details_screen.dart';
import 'package:pricepulse/theme/app_theme.dart';
import 'package:pricepulse/widgets/offer_row.dart';

/// The hand-off to a store leaves the app, so it must be confirmed first. These
/// tests fail if a launch ever happens without the user agreeing to it.
void main() {
  late List<Uri> launched;

  setUp(() {
    launched = <Uri>[];
    // Intercept launchUrl so no real browser/store app is opened in tests.
    UrlLauncherPlatform.instance = _RecordingLauncher(
      onLaunch: (uri) => launched.add(uri),
    );
  });

  tearDown(() => UrlLauncherPlatform.instance = _NoopLauncher());

  Product buildProduct() => Product(
    id: 'p1',
    name: 'Logitech G102 LIGHTSYNC Gaming Mouse',
    category: 'PC Parts',
    imageUrl: 'assets/products/logitech_g102.png',
    offers: [
      Offer(
        store: Store.shopee,
        price: 1076,
        productUrl: 'https://shopee.ph/product/124930893/9544986414',
        lastCheckedAt: DateTime(2026, 10, 17),
      ),
      Offer(
        store: Store.lazada,
        price: 1049,
        productUrl:
            'https://www.lazada.com.ph/products/i1059718604-s3599640767.html',
        lastCheckedAt: DateTime(2026, 10, 17),
      ),
    ],
  );

  Future<void> openDetails(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ProductDetailsScreen(product: buildProduct()),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find
        .descendant(
          of: find.byType(ProductDetailsScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Available offers'),
      300,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping an offer row asks for confirmation first', (
    tester,
  ) async {
    await openDetails(tester);

    // Offers are listed cheapest-first, so row 0 is Lazada (₱1,049).
    await tester.tap(find.byType(OfferRow).first);
    await tester.pumpAndSettle();

    // The dialog is up, and nothing has been launched yet.
    expect(find.text('Open Lazada?'), findsOneWidget);
    expect(launched, isEmpty);
  });

  testWidgets('the confirmation restates the recorded price and its date', (
    tester,
  ) async {
    await openDetails(tester);

    await tester.tap(find.byType(OfferRow).first);
    await tester.pumpAndSettle();

    // Scope to the dialog — the same figures also appear on the page behind it.
    final dialog = find.byType(AlertDialog);
    // The honesty contract: the user is told this is a *recorded* price and
    // that it may no longer be the live one.
    expect(
      find.descendant(of: dialog, matching: find.textContaining('₱1,049')),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: dialog,
        matching: find.textContaining('Oct 17, 2026'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: dialog,
        matching: find.textContaining('live price may differ'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('confirming launches the store URL', (tester) async {
    await openDetails(tester);

    await tester.tap(find.byType(OfferRow).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open listing'));
    await tester.pumpAndSettle();

    expect(launched, hasLength(1));
    expect(launched.single.host, 'www.lazada.com.ph');
  });

  testWidgets('cancelling launches nothing', (tester) async {
    await openDetails(tester);

    await tester.tap(find.byType(OfferRow).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(launched, isEmpty);
    expect(find.text('Open Shopee?'), findsNothing);
    // The user is still on the details screen.
    expect(find.byType(ProductDetailsScreen), findsOneWidget);
  });

  testWidgets('dismissing the dialog by tapping outside launches nothing', (
    tester,
  ) async {
    await openDetails(tester);

    await tester.tap(find.byType(OfferRow).first);
    await tester.pumpAndSettle();

    // Tap the barrier above the dialog.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(launched, isEmpty);
  });

  testWidgets('the sticky CTA is confirmed too', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ProductDetailsScreen(product: buildProduct()),
      ),
    );
    await tester.pumpAndSettle();

    // "Open lowest · Lazada · ₱1,049"
    await tester.tap(find.textContaining('Open lowest'));
    await tester.pumpAndSettle();

    expect(find.text('Open Lazada?'), findsOneWidget);
    expect(launched, isEmpty);
  });

  testWidgets('an unavailable link still shows the unavailable dialog, not a '
      'confirmation', (tester) async {
    final product = Product(
      id: 'p2',
      name: 'Placeholder Product',
      category: 'PC Parts',
      imageUrl: 'assets/products/orashare_hs05.jpg',
      offers: [
        Offer(
          store: Store.shopee,
          price: 100,
          productUrl: 'https://example.invalid/shopee/p2',
          lastCheckedAt: DateTime(2026, 10, 17),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ProductDetailsScreen(product: product),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Available offers'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ProductDetailsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(OfferRow).first);
    await tester.pumpAndSettle();

    expect(find.text('Listing link unavailable'), findsOneWidget);
    expect(find.textContaining('Open Shopee?'), findsNothing);
    expect(launched, isEmpty);
  });
}

/// Records every URL the app tries to open, so a test can assert that nothing
/// is launched without an explicit confirmation.
class _RecordingLauncher extends UrlLauncherPlatform {
  _RecordingLauncher({required this.onLaunch});

  final void Function(Uri uri) onLaunch;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    onLaunch(Uri.parse(url));
    return true;
  }
}

/// Default-safe launcher for other test files.
class _NoopLauncher extends UrlLauncherPlatform {
  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async => false;
}
