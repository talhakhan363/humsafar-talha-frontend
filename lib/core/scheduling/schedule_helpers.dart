/// Task 3.10 — pure, Flutter-independent helpers for the Dependent home
/// screen's "what's next" display (next medication dose, next wellness
/// check). Kept free of any plugin/network dependency so the scheduling
/// math itself is unit-testable without a device or widget harness.
/// Task 3.12 adds [formatCountdown] for the Wellness Check screen's
/// "Answer within mm:ss", same reasoning.

library;

/// Computes the next time a given "HH:MM" (24-hour, local clock) recurs
/// from [now], optionally restricted to specific weekdays (lowercase
/// 3-letter abbreviations: mon, tue, wed, thu, fri, sat, sun — matching
/// `medication_contract.md`'s `days` format). A null or empty
/// [daysOfWeek] means every day. Returns null if [time] isn't a valid
/// "HH:MM" string.
///
/// Treats [time] as the device's local clock time. The backend's
/// schedule times are local clock time in the server's own zone
/// (`Asia/Karachi` per `medication_contract.md` / `wellness_contract.md`)
/// — this assumes the Dependent's phone is set to the same zone, which
/// holds for this project's real users. Named simplification: not
/// corrected for a phone set to a different time zone.
DateTime? nextOccurrenceForTime({
  required String time,
  required DateTime now,
  List<String>? daysOfWeek,
}) {
  final parts = time.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

  for (var dayOffset = 0; dayOffset < 8; dayOffset++) {
    final day = DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));
    final candidate = DateTime(day.year, day.month, day.day, hour, minute);
    if (!candidate.isAfter(now)) continue;
    if (daysOfWeek != null && daysOfWeek.isNotEmpty) {
      if (!daysOfWeek.contains(_weekdayAbbrev(candidate.weekday))) continue;
    }
    return candidate;
  }
  return null;
}

String _weekdayAbbrev(int weekday) {
  const abbrevs = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  return abbrevs[weekday - 1];
}

/// Picks whichever item in [items] has the soonest next occurrence —
/// used for both medication schedules and wellness checks on the home
/// screen, so the "what's next" logic is written once. Null if none of
/// the items resolve to a future time (for example an empty list, or
/// every `time` string is malformed).
({T item, DateTime at})? earliestUpcoming<T>({
  required List<T> items,
  required String Function(T) timeOf,
  List<String>? Function(T)? daysOf,
  required DateTime now,
}) {
  T? bestItem;
  DateTime? bestAt;
  for (final item in items) {
    final at = nextOccurrenceForTime(time: timeOf(item), now: now, daysOfWeek: daysOf?.call(item));
    if (at == null) continue;
    if (bestAt == null || at.isBefore(bestAt)) {
      bestAt = at;
      bestItem = item;
    }
  }
  if (bestItem == null || bestAt == null) return null;
  return (item: bestItem, at: bestAt);
}

const _weekdayNamesEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _weekdayNamesUr = ['پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'];

/// Weekday name for the home screen's date line. A small inline lookup
/// rather than `intl`'s locale-aware date formatters — this project
/// hasn't confirmed Urdu locale data is initialized for `intl`'s
/// `DateFormat` (it isn't called anywhere else in the app yet), and
/// getting that wrong would throw at runtime in Urdu mode. [languageCode]
/// is `Localizations.localeOf(context).languageCode` ("en" or "ur").
String weekdayName(DateTime date, String languageCode) {
  final names = languageCode == 'ur' ? _weekdayNamesUr : _weekdayNamesEn;
  return names[date.weekday - 1];
}

/// Formats a clock time as "h:mm AM/PM", for the same reason as
/// [weekdayName] — no `intl` locale-data dependency. AM/PM is kept as a
/// universal abbreviation in both languages rather than translated.
String formatClockTime(DateTime time) {
  final hour24 = time.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = hour24 < 12 ? 'AM' : 'PM';
  return '$hour12:$minute $suffix';
}

/// Task 3.12 — formats a countdown as "mm:ss" for the Wellness Check
/// screen's "Answer within mm:ss" chip (mockup screen 22). Clamped to
/// "00:00" once [remaining] reaches zero or goes negative (the deadline
/// has passed) rather than showing a negative time, since the screen
/// still lets the Dependent answer late — the countdown going to zero is
/// not an error state, just informational.
String formatCountdown(Duration remaining) {
  final clamped = remaining.isNegative ? Duration.zero : remaining;
  final minutes = clamped.inMinutes;
  final seconds = clamped.inSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
