/// Formats money and dates for the PricePulse UI (Philippine pesos, ₱).
library;

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats a peso amount with thousands separators.
/// Cents are shown only when non-zero (e.g. `₱1,299` / `₱1,299.50`).
String formatPeso(double amount) {
  final negative = amount < 0;
  final abs = amount.abs();
  final hasCents = (abs - abs.roundToDouble()).abs() >= 0.005;
  final str = abs.toStringAsFixed(hasCents ? 2 : 0);
  final parts = str.split('.');
  final digits = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  final body = parts.length == 2 ? '$buffer.${parts[1]}' : '$buffer';
  return '${negative ? '-' : ''}₱$body';
}

/// Short readable date: `Oct 16, 2026`.
String formatDateShort(DateTime date) {
  return '${_months[date.month - 1]} ${date.day}, ${date.year}';
}
