/// Honest link handling: a URL is "available" only when it is a well-formed
/// http(s) link and not a marked placeholder. Placeholder links are never
/// presented as working marketplace listings (design/04 §2 rules + scope
/// guardrails).
library;

enum LinkAvailability { available, placeholder, missing }

LinkAvailability computeLinkAvailability(String rawUrl) {
  final raw = rawUrl.trim();
  if (raw.isEmpty) return LinkAvailability.missing;
  final uri = Uri.tryParse(raw);
  if (uri == null) return LinkAvailability.missing;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return LinkAvailability.missing;
  if (raw.toLowerCase().contains('placeholder')) {
    return LinkAvailability.placeholder;
  }
  // Seed URLs use this TLD precisely because it can never resolve.
  if (uri.host.toLowerCase() == 'example.invalid') {
    return LinkAvailability.placeholder;
  }
  return LinkAvailability.available;
}
