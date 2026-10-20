import 'package:flutter_test/flutter_test.dart';
import 'package:humsafar_frontend/core/scheduling/schedule_helpers.dart';

/// TC-3.10-01..09 — unit tests for the Dependent home screen's "what's
/// next" scheduling math (Task 3.10). Pure Dart, no device, no network,
/// no login.
///
/// TC-3.12-01..03 (added 2026-10-20) — unit tests for [formatCountdown],
/// the Wellness Check screen's "Answer within mm:ss" formatting.
void main() {
  group('nextOccurrenceForTime', () {
    test('TC-3.10-01: a daily time later today resolves to today', () {
      final now = DateTime(2026, 10, 20, 8, 0); // Tuesday, 8:00 AM
      final result = nextOccurrenceForTime(time: '14:00', now: now);

      expect(result, DateTime(2026, 10, 20, 14, 0));
    });

    test('TC-3.10-02: a daily time already passed today rolls to tomorrow', () {
      final now = DateTime(2026, 10, 20, 15, 0); // Tuesday, 3:00 PM
      final result = nextOccurrenceForTime(time: '08:00', now: now);

      expect(result, DateTime(2026, 10, 21, 8, 0));
    });

    test('TC-3.10-03: a weekly schedule skips to the next matching weekday', () {
      final now = DateTime(2026, 10, 20, 8, 0); // Tuesday
      // Only on Thursday and Monday - Thursday is sooner.
      final result = nextOccurrenceForTime(time: '09:00', now: now, daysOfWeek: ['thu', 'mon']);

      expect(result, DateTime(2026, 10, 22, 9, 0)); // that Thursday
    });

    test('TC-3.10-04: an empty daysOfWeek list behaves like every day (not "never")', () {
      final now = DateTime(2026, 10, 20, 8, 0);
      final result = nextOccurrenceForTime(time: '14:00', now: now, daysOfWeek: const []);

      expect(result, DateTime(2026, 10, 20, 14, 0));
    });

    test('TC-3.10-05: a malformed time string returns null instead of throwing', () {
      final now = DateTime(2026, 10, 20, 8, 0);

      expect(nextOccurrenceForTime(time: 'not-a-time', now: now), isNull);
      expect(nextOccurrenceForTime(time: '25:00', now: now), isNull);
      expect(nextOccurrenceForTime(time: '08:70', now: now), isNull);
    });
  });

  group('earliestUpcoming', () {
    test('TC-3.10-06: picks the soonest item out of several', () {
      final items = [
        {'drug_name': 'Evening dose', 'time': '20:00'},
        {'drug_name': 'Morning dose', 'time': '08:00'},
        {'drug_name': 'Afternoon dose', 'time': '14:00'},
      ];
      final now = DateTime(2026, 10, 20, 6, 0); // before all three

      final result = earliestUpcoming<Map<String, String>>(
        items: items,
        timeOf: (m) => m['time']!,
        now: now,
      );

      expect(result?.item['drug_name'], 'Morning dose');
      expect(result?.at, DateTime(2026, 10, 20, 8, 0));
    });

    test('TC-3.10-07: an empty list returns null, not a crash', () {
      final result = earliestUpcoming<Map<String, String>>(
        items: const [],
        timeOf: (m) => m['time']!,
        now: DateTime(2026, 10, 20, 8, 0),
      );

      expect(result, isNull);
    });

    test('TC-3.10-08: respects per-item day restrictions when picking the soonest', () {
      final items = [
        {'time': '07:00', 'days': 'fri'}, // next Friday - further away
        {'time': '07:00', 'days': 'wed'}, // tomorrow (Wednesday) - sooner
      ];
      final now = DateTime(2026, 10, 20, 8, 0); // Tuesday, after both times today

      final result = earliestUpcoming<Map<String, String>>(
        items: items,
        timeOf: (m) => m['time']!,
        daysOf: (m) => [m['days']!],
        now: now,
      );

      expect(result?.at, DateTime(2026, 10, 21, 7, 0)); // the Wednesday one
    });
  });

  group('weekdayName', () {
    test('TC-3.10-09: returns the right name in both locales', () {
      final tuesday = DateTime(2026, 10, 20); // confirmed Tuesday elsewhere in this project

      expect(weekdayName(tuesday, 'en'), 'Tuesday');
      expect(weekdayName(tuesday, 'ur'), 'منگل');
    });
  });

  group('formatClockTime', () {
    test('TC-3.10-10: formats midnight, noon, and a regular afternoon time correctly', () {
      expect(formatClockTime(DateTime(2026, 10, 20, 0, 0)), '12:00 AM');
      expect(formatClockTime(DateTime(2026, 10, 20, 12, 0)), '12:00 PM');
      expect(formatClockTime(DateTime(2026, 10, 20, 14, 5)), '2:05 PM');
      expect(formatClockTime(DateTime(2026, 10, 20, 8, 0)), '8:00 AM');
    });
  });

  group('formatCountdown', () {
    test('TC-3.12-01: formats minutes and seconds with zero-padding', () {
      expect(formatCountdown(const Duration(minutes: 29, seconds: 12)), '29:12');
      expect(formatCountdown(const Duration(minutes: 5, seconds: 3)), '05:03');
      expect(formatCountdown(const Duration(seconds: 45)), '00:45');
    });

    test('TC-3.12-02: exactly zero formats as 00:00', () {
      expect(formatCountdown(Duration.zero), '00:00');
    });

    test('TC-3.12-03: a negative duration (deadline passed) clamps to 00:00, not a negative string', () {
      expect(formatCountdown(const Duration(seconds: -1)), '00:00');
      expect(formatCountdown(const Duration(minutes: -5)), '00:00');
    });
  });
}
