import 'package:flutter_test/flutter_test.dart';

import 'package:pricepulse/utils/formatters.dart';

void main() {
  group('formatPeso', () {
    test('whole amounts have no decimals', () {
      expect(formatPeso(1299), '₱1,299');
      expect(formatPeso(0), '₱0');
      expect(formatPeso(899), '₱899');
    });

    test('thousands separators', () {
      expect(formatPeso(1000000), '₱1,000,000');
      expect(formatPeso(15999.0), '₱15,999');
    });

    test('cents shown only when non-zero', () {
      expect(formatPeso(1299.50), '₱1,299.50');
      expect(formatPeso(1299.0), '₱1,299');
    });

    test('negative amounts are prefixed', () {
      expect(formatPeso(-149.0), '-₱149');
    });
  });

  group('formatDateShort', () {
    test('renders "Oct 16, 2026" style', () {
      expect(formatDateShort(DateTime(2026, 10, 16)), 'Oct 16, 2026');
      expect(formatDateShort(DateTime(2026, 1, 5)), 'Jan 5, 2026');
    });
  });
}
