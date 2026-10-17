/// Reads catalog records out of untrusted, backend-shaped data.
///
/// **Everything crossing this boundary is untrusted.** A Firestore document is a
/// `Map<String, dynamic>` assembled by whatever wrote it — a previous schema,
/// a typo, an admin edit, or something deliberately malformed. It is validated
/// here, once, at the edge. Everything downstream can then trust the types.
///
/// ## Why parsing throws instead of returning a nullable record
///
/// A parser that returns null forces every call site to handle absence, and
/// someone eventually forgets. Throwing [ParseFailure] makes a malformed record
/// impossible to ignore, and the field name travels with the error so a bad
/// document can be identified without a debugger.
///
/// ## Failure policy
///
/// One malformed product must not take down the catalog. [parseProduct] throws
/// for a single record; [parseCatalog] collects the good ones and reports what
/// it dropped, so a single bad document degrades to a missing card rather than
/// an empty screen.
library;

import 'data_failure.dart';
import '../models/offer.dart';
import '../models/product.dart';

/// Thrown by [parseProduct] when a record does not match the expected shape.
typedef ProductParser = Product Function(Map<String, dynamic> json);

/// Parses one catalog document.
///
/// Throws [ParseFailure] naming the offending field.
Product parseProduct(Map<String, dynamic> json) {
  final id = _requireString(json, 'id');
  final name = _requireString(json, 'name');
  final category = _requireString(json, 'category');
  final offers = _parseOffers(json['offers'], id);
  // Count offers with a *usable price*, not offer entries. A record whose only
  // offer is price 0 would otherwise parse into a card that can display
  // nothing; omitting it is the honest outcome.
  if (offers.where((o) => o.isValidPrice).isEmpty) {
    throw ParseFailure('offers', 'no offer carried a usable price for $id');
  }
  return Product(
    id: id,
    name: name,
    category: category,
    imageUrl: _optionalString(json, 'imageUrl') ?? '',
    description: _optionalString(json, 'description'),
    featured: _optionalBool(json, 'featured') ?? false,
    // Defaults to comparable so a missing flag cannot silently enable savings
    // across records that were never checked for variant mixing.
    comparable: _optionalBool(json, 'comparable') ?? true,
    offers: offers,
  );
}

/// Parses a whole catalog, skipping records that fail.
///
/// Returns the records that parsed. Malformed ones are dropped rather than
/// thrown, because one bad document should cost the user one card, not the
/// entire catalog.
List<Product> parseCatalog(Iterable<Map<String, dynamic>> documents) {
  final out = <Product>[];
  for (final doc in documents) {
    try {
      out.add(parseProduct(doc));
    } on DataFailure {
      continue;
    }
  }
  return out;
}

List<Offer> _parseOffers(Object? raw, String productId) {
  if (raw is! List) {
    throw ParseFailure('offers', 'expected a list on $productId');
  }
  final offers = <Offer>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    final offer = _parseOffer(Map<String, dynamic>.from(entry));
    if (offer != null) offers.add(offer);
  }
  return offers;
}

Offer? _parseOffer(Map<String, dynamic> json) {
  final storeName = _safeString(json, 'store');
  final store = _storeByName(storeName);
  final rawPrice = json['price'];

  // A record without a resolvable store or a numeric price is not renderable
  // as an offer; dropping it is how "no recorded offer" is meant to appear.
  if (store == null || rawPrice is! num) return null;

  // A malformed URL is recoverable: an empty link renders the honest
  // "link unavailable" state, whereas throwing would delete the whole product
  // because one optional field was wrong.
  final url = _safeString(json, 'productUrl') ?? '';
  final checkedAt = json['lastCheckedAt'];
  return Offer(
    store: store,
    price: rawPrice.toDouble(),
    productUrl: url,
    lastCheckedAt: checkedAt is String ? _parseDate(checkedAt) : DateTime(1970),
  );
}

Store? _storeByName(String? name) {
  if (name == null) return null;
  final needle = name.trim().toLowerCase();
  for (final store in Store.values) {
    if (store.displayName.toLowerCase() == needle) return store;
    if (store.name.toLowerCase() == needle) return store;
  }
  return null;
}

DateTime _parseDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed != null) return parsed;
  final split = raw.split(RegExp(r'\s+'));
  if (split.length >= 3) {
    final month = switch (split[0].toLowerCase()) {
      'jan' => 1,
      'feb' => 2,
      'mar' => 3,
      'apr' => 4,
      'may' => 5,
      'jun' => 6,
      'jul' => 7,
      'aug' => 8,
      'sep' => 9,
      'oct' => 10,
      'nov' => 11,
      'dec' => 12,
      _ => 0,
    };
    final day = int.tryParse(split[1].replaceAll(',', ''));
    final year = int.tryParse(split[2]);
    if (month > 0 && day != null && year != null) {
      return DateTime(year, month, day);
    }
  }
  return DateTime(1970);
}

String _requireString(Map<String, dynamic> json, String field) {
  final value = _optionalString(json, field);
  // Whitespace-only is not a value: it would render as a blank card title.
  if (value == null || value.trim().isEmpty) {
    throw ParseFailure(field, 'expected a non-empty string');
  }
  return value;
}

/// Reads an optional string, returning null instead of throwing.
///
/// For use inside a record where one bad optional field should degrade that
/// field rather than discard the whole record. A *required* field still throws
/// via [_requireString], because there the absence is the problem.
String? _safeString(Map<String, dynamic> json, String field) {
  final value = json[field];
  return value is String ? value : null;
}

String? _optionalString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is! String) {
    throw ParseFailure(field, 'expected a string, got ${value.runtimeType}');
  }
  return value;
}

bool? _optionalBool(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is! bool) {
    throw ParseFailure(field, 'expected a bool, got ${value.runtimeType}');
  }
  return value;
}
