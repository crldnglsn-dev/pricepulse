// Verifies that every marketplace URL in the seed dataset actually resolves.
//
//   dart run tool/verify_links.dart
//
// Reads lib/data/seed_products.dart, extracts each `productUrl`, and issues a
// real HTTP GET with a mobile user agent (marketplaces 403 the default Dart
// agent). Prints one line per offer and exits non-zero if any link that the app
// would treat as "available" is dead — so a broken listing can never reach a
// demo unnoticed.
//
// This is a dev tool. It is not shipped in the app.
import 'dart:io';

const _seedPath = 'lib/data/seed_products.dart';

/// Placeholders the app deliberately treats as unavailable (see
/// `lib/utils/link_utils.dart`); they are expected to fail and are not errors.
const _expectedDead = ['example.invalid', 'placeholder'];

final _mobileAgent =
    'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36';

/// Whether a store actually returns 404 for a missing listing, measured by
/// probing deliberately-fake URLs.
///
/// Only Lazada does. Shopee and TikTok Shop answer HTTP 200 for pages that do
/// not exist, so a "200" from them proves nothing — those links can only be
/// confirmed by opening them on a device.
const _storesThatDetectMissing = ['lazada.com.ph'];

bool _canTrustStatus(String url) =>
    _storesThatDetectMissing.any(url.toLowerCase().contains);

Future<void> main(List<String> args) async {
  final file = File(_seedPath);
  if (!file.existsSync()) {
    stderr.writeln('Could not find $_seedPath — run from the project root.');
    exit(2);
  }

  final source = await file.readAsString();
  final urls = RegExp(r"""productUrl:\s*'([^']+)'""")
      .allMatches(source)
      .map((m) => m.group(1)!)
      .toList();

  if (urls.isEmpty) {
    stdout.writeln('No productUrl entries found in $_seedPath.');
    exit(0);
  }

  stdout.writeln('Checking ${urls.length} seed URL(s)…\n');

  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..userAgent = _mobileAgent;

  var live = 0;
  var placeholder = 0;
  var dead = 0;
  var unverified = 0;

  for (final url in urls) {
    if (_expectedDead.any(url.toLowerCase().contains)) {
      placeholder++;
      stdout.writeln('  PLACEHOLDER  $url');
      continue;
    }

    final result = await _probe(client, url);
    final trustworthy = _canTrustStatus(url);
    final String label;
    if (!result.ok) {
      label = 'DEAD';
    } else if (trustworthy) {
      label = 'LIVE';
    } else {
      label = 'UNVERIFIED';
    }
    if (result.ok) {
      live++;
    } else {
      dead++;
      if (!trustworthy) unverified++;
    }
    stdout.writeln('  $label  ${result.status}  $url');
  }

  client.close();
  stdout.writeln('\n$live reachable · $placeholder placeholder · $dead dead');
  if (unverified > 0) {
    stdout.writeln(
      '  ($unverified of those are unverifiable by status code and need a '
      'device check)',
    );
  }
  stdout.writeln(
    'Reachable != working. Only Lazada returns real 404s, so Shopee and '
    'TikTok Shop "UNVERIFIED" rows must be opened on a device by hand.',
  );

  if (dead > 0) {
    stderr.writeln(
      '\nDead links found. The app will still open them and land on an error '
      'page — replace them or set a placeholder before demoing.',
    );
    exit(1);
  }
}

class _Result {
  const _Result(this.ok, this.status);
  final bool ok;
  final String status;
}

Future<_Result> _probe(HttpClient client, String url) async {
  try {
    final req = await client
        .getUrl(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    final res = await req.close().timeout(const Duration(seconds: 15));
    // Drain so the socket can be reused for the next probe.
    await res.drain<void>();
    final hops = res.redirects.isEmpty ? '' : ' (+${res.redirects.length}r)';
    return _Result(
      res.statusCode >= 200 && res.statusCode < 400,
      '${res.statusCode}$hops',
    );
  } on Object catch (e) {
    return _Result(false, e.runtimeType.toString());
  }
}
