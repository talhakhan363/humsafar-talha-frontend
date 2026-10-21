// Tasks 5.6/5.7/5.8/6.8 — unit tests for the pure, Flutter-independent
// formatting helpers in `format_helpers.dart`. No widget harness needed
// since these are plain functions with no plugin/network dependency.

import 'package:flutter_test/flutter_test.dart';
import 'package:humsafar_frontend/core/formatting/format_helpers.dart';

void main() {
  group('formatFileSize', () {
    test('shows raw bytes under 1 KB', () {
      expect(formatFileSize(900), '900 B');
      expect(formatFileSize(0), '0 B');
    });

    test('shows one decimal under 10 KB, none from 10 KB up', () {
      expect(formatFileSize(1536), '1.5 KB'); // 1.5 KB
      expect(formatFileSize(15360), '15 KB'); // 15 KB
    });

    test('shows MB once past 1024 KB', () {
      expect(formatFileSize(1024 * 1024 * 2), '2.0 MB');
      expect(formatFileSize((1024 * 1024 * 1.2).round()), '1.2 MB');
    });
  });

  group('formatDateYmd', () {
    test('pads month/day/year to the contract\'s YYYY-MM-DD shape', () {
      expect(formatDateYmd(DateTime(2026, 1, 5)), '2026-01-05');
      expect(formatDateYmd(DateTime(900, 11, 23)), '0900-11-23');
    });
  });

  group('formatDateDisplay', () {
    test('uses English month abbreviations for "en"', () {
      expect(formatDateDisplay(DateTime(2026, 10, 21), 'en'), '21 Oct 2026');
    });

    test('uses Urdu month names for "ur"', () {
      expect(formatDateDisplay(DateTime(2026, 10, 21), 'ur'), '21 اکتوبر 2026');
    });
  });

  group('formatPkrOrAsk', () {
    test('returns the caller\'s ask label when value is null', () {
      expect(formatPkrOrAsk(null, 'Ask for price'), 'Ask for price');
    });

    test('formats a whole number with thousands separators', () {
      expect(formatPkrOrAsk(2500, 'Ask'), 'PKR 2,500');
      expect(formatPkrOrAsk(1000000, 'Ask'), 'PKR 1,000,000');
    });

    test('keeps two decimal places for a non-whole value', () {
      expect(formatPkrOrAsk(1999.5, 'Ask'), 'PKR 1,999.50');
    });
  });

  group('formatDistanceKm', () {
    test('returns null when there is no distance', () {
      expect(formatDistanceKm(null), isNull);
    });

    test('shows one decimal under 10 km, none from 10 km up', () {
      expect(formatDistanceKm(2.4), '2.4 km');
      expect(formatDistanceKm(12.7), '13 km');
    });
  });
}
