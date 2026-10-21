/// Tasks 5.6/5.7/5.8/6.8 — small, pure, Flutter-independent formatting
/// helpers, same spirit as `schedule_helpers.dart` (kept free of any
/// plugin/network dependency so the formatting itself is
/// unit-testable without a device or widget harness, and free of
/// `intl`'s locale-data for the same reason `schedule_helpers.dart`
/// avoids it — see that file's `weekdayName` doc comment).

library;

/// "245 KB" / "1.2 MB" for a record's file size
/// (`records_contract.md`'s `size_bytes`). Below 1 KB shows bytes
/// directly ("900 B") rather than "0.0 KB", since a 0-byte-looking
/// file is worth noticing, not rounding away.
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
}

/// "YYYY-MM-DD" — the exact shape `records_contract.md`'s
/// `record_date` and the export/share `year`/`month` query params
/// want, built from a `DateTime` without `intl`.
String formatDateYmd(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

const _monthNamesEn = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _monthNamesUr = ['جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون', 'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر'];

/// "21 Oct 2026" (or the Urdu month name in `ur`) — for displaying a
/// record date, appointment date or reading date without pulling in
/// `intl`'s locale data (same reasoning as `schedule_helpers.weekdayName`).
String formatDateDisplay(DateTime date, String languageCode) {
  final names = languageCode == 'ur' ? _monthNamesUr : _monthNamesEn;
  return '${date.day} ${names[date.month - 1]} ${date.year}';
}

/// "PKR 2,500" or, when [value] is null (per `directory_contract.md`:
/// "null = ask the provider"), the caller's own "ask" label — kept as
/// a parameter rather than a hardcoded string so both English and Urdu
/// callers can pass their own localized text.
String formatPkrOrAsk(num? value, String askLabel) {
  if (value == null) return askLabel;
  final rounded = value.truncateToDouble() == value ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  final parts = rounded.split('.');
  final digits = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  final whole = buffer.toString();
  return 'PKR ${parts.length > 1 ? '$whole.${parts[1]}' : whole}';
}

/// "2.4 km" for `directory_contract.md`'s `distance_km`, or null when
/// the entry (or the search) has no position — the caller decides what
/// to show instead (nothing, or a "no distance" label).
String? formatDistanceKm(double? km) {
  if (km == null) return null;
  return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
}
