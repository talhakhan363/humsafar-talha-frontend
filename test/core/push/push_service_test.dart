// Task 3.14 — TC-3.14-01..03. Only `routeForNotificationType` is unit-
// tested here: it's the one piece of push_service.dart that's a pure
// function (no Firebase plugin involved), per the file's own doc comment.
// The rest of PushService (channel creation, permission requests, token
// fetch/refresh) wraps the firebase_messaging/flutter_local_notifications
// plugins directly and has no fake/mock layer in this project yet, so
// it's exercised manually on a real device instead (see the delivery
// notes' manual QA checklist), same as camera/location plugin wrappers
// elsewhere in this codebase.

import 'package:flutter_test/flutter_test.dart';
import 'package:humsafar_frontend/core/push/push_service.dart';

void main() {
  group('routeForNotificationType (TC-3.14-01..03)', () {
    test('TC-3.14-01: Guardian-facing alert types all route to the Alerts inbox', () {
      for (final type in [
        'geofence_breach',
        'low_battery',
        'device_offline',
        'missed_dose',
        'wellness_check',
        'panic',
        'external_contact',
      ]) {
        expect(routeForNotificationType(type), '/guardian/alerts', reason: 'type=$type');
      }
    });

    test('TC-3.14-02: Dependent-facing self-resolving types route to their own screens', () {
      expect(routeForNotificationType('medication_reminder'), '/dependent/medication');
      expect(routeForNotificationType('medication_due'), '/dependent/medication');
      expect(routeForNotificationType('medication_extended'), '/dependent/medication');
      expect(routeForNotificationType('wellness_check_prompt'), '/dependent/wellness-check');
      expect(routeForNotificationType('remote_alarm'), '/dependent/alarm');
      expect(routeForNotificationType('remote_alarm_stop'), '/dependent/alarm');
    });

    test('TC-3.14-03: unbuilt-screen types and null return null (open the app normally)', () {
      expect(routeForNotificationType('message'), null);
      expect(routeForNotificationType('voice_message'), null);
      expect(routeForNotificationType('incoming_call'), null);
      expect(routeForNotificationType('appointment_update'), null);
      expect(routeForNotificationType('appointment_reminder'), null);
      expect(routeForNotificationType(null), null);
      expect(routeForNotificationType('something_unexpected'), null);
    });
  });
}
