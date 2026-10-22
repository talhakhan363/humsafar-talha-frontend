// Task 3.14 — TC-3.14-01..03. Only `routeForNotificationType` is unit-
// tested here: it's the one piece of push_service.dart that's a pure
// function (no Firebase plugin involved), per the file's own doc comment.
// The rest of PushService (channel creation, permission requests, token
// fetch/refresh) wraps the firebase_messaging/flutter_local_notifications
// plugins directly and has no fake/mock layer in this project yet, so
// it's exercised manually on a real device instead (see the delivery
// notes' manual QA checklist), same as camera/location plugin wrappers
// elsewhere in this codebase.
//
// Modified for Task 4.6 (2026-10-22) — TC-3.14-03's old assertion that
// `message`/`voice_message` return null is no longer true: those two
// types now route to `/messages` (the new inbox, see
// push_service.dart's updated doc comment). Moved out of TC-3.14-03 and
// into a new TC-4.6-01, rather than quietly deleting the old assertion —
// the test case log's Task 4.6 section notes this change explicitly.
//
// Extended for Task 4.7 (2026-10-22) — TC-4.7-13..15, for the new
// `incomingCallPushData` function. TC-3.14-03's existing assertion that
// `routeForNotificationType('incoming_call')` is still `null` is left
// untouched and still true — that type is now handled by this separate
// function instead, not by a change to `routeForNotificationType`
// itself (see push_service.dart's doc comment on both).

import 'package:flutter_test/flutter_test.dart';
import 'package:humsafar_frontend/core/push/push_service.dart';

void main() {
  group('routeForNotificationType (TC-3.14-01..03, TC-4.6-01)', () {
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

    test('TC-3.14-03: still-unbuilt-screen types and null return null (open the app normally)', () {
      expect(routeForNotificationType('incoming_call'), null);
      expect(routeForNotificationType('appointment_update'), null);
      expect(routeForNotificationType('appointment_reminder'), null);
      expect(routeForNotificationType(null), null);
      expect(routeForNotificationType('something_unexpected'), null);
    });

    test('TC-4.6-01: message/voice_message push taps now open the Messages inbox', () {
      expect(routeForNotificationType('message'), '/messages');
      expect(routeForNotificationType('voice_message'), '/messages');
    });
  });

  group('incomingCallPushData (TC-4.7-13..15)', () {
    test('TC-4.7-13: well-formed incoming_call payload is parsed', () {
      final result = incomingCallPushData({
        'type': 'incoming_call',
        'call_id': 'call-42',
        'caller_name': 'Ammi',
        'call_type': 'video',
      });

      expect(result, {'callId': 'call-42', 'callerName': 'Ammi', 'isVideo': true});
    });

    test('TC-4.7-14: call_type "voice" (or anything other than "video") maps to isVideo: false', () {
      final result = incomingCallPushData({
        'type': 'incoming_call',
        'call_id': 'call-43',
        'caller_name': 'Abdullah',
        'call_type': 'voice',
      });

      expect(result, {'callId': 'call-43', 'callerName': 'Abdullah', 'isVideo': false});
    });

    test('TC-4.7-15: wrong type, missing call_id, or missing type all return null', () {
      expect(incomingCallPushData({'type': 'message', 'call_id': 'call-1'}), null);
      expect(incomingCallPushData({'type': 'incoming_call'}), null);
      expect(incomingCallPushData({'call_id': 'call-1', 'caller_name': 'Ammi'}), null);
    });
  });
}
