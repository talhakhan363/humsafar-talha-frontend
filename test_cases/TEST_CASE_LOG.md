# Humsafar (Talha's frontend) — Test Case Log

One row per test case, tagged to the task number it came from. Full exhaustive pass happens once the whole app is ready. Updated by Claude as part of every task's delivery zip — this is the one and only test case file for this repo; never duplicated, never versioned as a dated copy.

Status values: `Not Run` · `Pass` · `Fail` · `Fixed` (was Fail, now resolved — re-run to confirm before changing to Pass).

**Standing test-strategy convention (decided 2026-10-20):** the "soft"/smoke-check test case for each task is an **automated Flutter widget/unit test** (added under `test/`) using fakes instead of the real backend/GPS/plugins — no login, no linked Guardian/Dependent accounts, no device. Run with `flutter test`.
- What this catches: screen/service logic, error-message mapping, loading/empty/error states, wiring bugs.
- What this does *not* catch, and stays deferred to one full team pass before final submission: real on-device rendering, true multi-account flows (Secondary permission gating, invite acceptance), and anything needing real OS-level behavior — background services, push notifications, real calls, real GPS/permission dialogs. Flagged explicitly, task by task, whenever a widget test alone gives weaker confidence than usual because of this.

**Standing delivery convention:** before any manual "run the app" step, confirm the backend is running first (`cd D:\humsafar\backend` → `.\venv\Scripts\Activate.ps1` → `uvicorn app.main:app --reload`, its own terminal).

**Standing research convention (added 2026-10-20):** before building each task, Claude pulls the latest `mabdullahghafoor/humsafar` `dev` branch fresh and re-reads the actual contracts/mockups — never from memory — since Abdullah and Sarim push updates frequently.

**Standing multi-task-batch convention (added 2026-10-20, starting with 3.11+3.12):** when Talha asks for more than one task in a single delivery, each task still gets its own section below with its own test IDs, its own named scope decisions, and its own entries in "Open cross-cutting items" — batching the zip doesn't batch away the per-task bookkeeping.

---

## Task 2.5 — Real Auth/KYC/Linkage/Permission API wiring

| Test ID | Test Case | Expected Result | Status | Notes |
|---|---|---|---|---|
| TC-2.5-01 | Register as Guardian | Lands on Guardian verification screen, not the old dummy role-select | Pass | Confirmed on real device 2026-10-20 |
| TC-2.5-02 | Verify via CNIC not ending in 0 or 9 | Passes immediately, lands on Guardian home with an empty "not linked to anyone" state | Not Run | Deferred to the full pass |
| TC-2.5-03 | Fully close and reopen the app as a verified Guardian | Session restores — lands directly on Guardian home | Pass | Confirmed on real device 2026-10-20 |
| TC-2.5-04 | Register as Dependent | Lands directly on the KYC screen, not role-select | Not Run | Deferred to the full pass |
| TC-2.5-05 | Dependent KYC: tap capture-liveness, use the real camera | Camera opens, takes a photo, shows a thumbnail | Pass | Confirmed on real device 2026-10-20 |
| TC-2.5-06 | Submit Dependent KYC with CNIC not ending in 0 | Shows "Verified, waiting for your Primary Guardian" with the Dependent's ID as selectable text | Not Run | Deferred to the full pass |
| TC-2.5-07 | Guardian links the Dependent using the copied ID | Succeeds, Dependent now appears on Guardian home | Pass | Confirmed on real device 2026-10-20 |
| TC-2.5-08 | Open that Dependent's detail screen as the Primary | Shows self as Primary; Invite/Manage Permissions buttons present | Not Run | Deferred to the full pass |
| TC-2.5-09 | Primary invites a Secondary by phone number | Returns an invite code with a working Copy button | Not Run | Deferred to the full pass |
| TC-2.5-10 | Register a new account using that invite code | Role auto-locks to Guardian; after verifying, shows up as Secondary | Not Run | Deferred to the full pass |
| TC-2.5-11 | Secondary opens the same Dependent's detail screen | Shows "My Access" button; all modules denied by default | Not Run | Deferred to the full pass |
| TC-2.5-12 | Primary toggles one module on in Permissions dashboard | Switch updates with no error | Not Run | Deferred to the full pass |
| TC-2.5-13 | Secondary re-checks "My Access" after the Primary's grant, without logging out | Module now shows granted | Not Run | Tests permissions aren't cached in the token. Deferred to the full pass |
| TC-2.5-14 | Dependent logs in now that they're linked and KYC-verified | Succeeds, lands on Dependent home | Not Run | Deferred to the full pass |

---

## Task 2.5 Step F — Urdu localization

| Test ID | Test Case | Expected Result | Status | Notes |
|---|---|---|---|---|
| TC-2.5-15 | Switch to Urdu, walk all Step C1/C2/E screens | Every button/label/error/snackbar renders in Urdu | Not Run | ~95 keys added to app_en.arb/app_ur.arb, 11 screens wired |

---

## Task 2.6 — Live Map screen (location + geofence overlay)

| Test ID | Test Case | Expected Result | Status | Notes |
|---|---|---|---|---|
| TC-2.6-01 | Automated widget test (`test/features/guardian/live_map_screen_test.dart`) — fake ApiClient throws `NOT_LINKED_TO_DEPENDENT` | Shows "You're not linked to this Dependent." + working Retry, no crash | Pass | Confirmed via `flutter test` 2026-10-20, 8/8 passing |
| TC-2.6-02 | Real geofence + location fix inside it, open Live Map as Primary (real device) | Circle overlay renders; banner shows "Inside a safe zone"; marker teal | Not Run | Deferred to full team pass |
| TC-2.6-03 | Location fix outside the geofence radius | Banner turns amber "Outside all safe zones"; marker amber (not red) | Not Run | Deferred to full team pass |
| TC-2.6-04 | Secondary without `live_location` permission opens Live Map | Shows permission-denied message, no crash | Not Run | Deferred to full team pass |
| TC-2.6-05 | Grant `live_location`, Secondary reopens Live Map | Loads successfully | Not Run | Deferred to full team pass |
| TC-2.6-06 | Location fix >8 min old, reopen on real device | "This location may be out of date." warning appears | Not Run | Deferred to full team pass |
| TC-2.6-07 | Visual check on a real device: map tiles, marker, circle all render correctly | Looks right, not just "doesn't crash" | Not Run | Deferred to full team pass — this is specifically a looks-right check a widget test can't do |
| TC-2.6-08 | Automated widget test (same file) — fake ApiClient returns no location, zone `no_zones` | Shows "No safe zones set up yet" and "No location received yet.", no crash | Pass | Confirmed via `flutter test` 2026-10-20 |

**Named scope decision for 2.6:** read-only screen (view location + zones). Safe-zone create/edit/delete explicitly deferred, not part of this task.

---

## Task 2.7 — Background location service (permissions, adaptive polling)

| Test ID | Test Case | Expected Result | Status | Notes |
|---|---|---|---|---|
| TC-2.7-01 | Automated unit test (`test/core/location/location_polling_service_test.dart`) — fake GPS + fake ApiClient reply with `next_update_interval_s: 10` | Service posts `lat`/`lng`/`battery_level` and reads the interval back without error | Pass | Confirmed via `flutter test` 2026-10-20 |
| TC-2.7-02 | Automated unit test (same file) — fake ApiClient throws on POST | Loop doesn't crash/stop; falls back to the contract's 60s default and keeps running | Pass | Confirmed via `flutter test` 2026-10-20 |
| TC-2.7-03 | Automated unit test (same file) — fake permission `denied` | `start()` returns `denied`, API is never called, loop never starts | Pass | Confirmed via `flutter test` 2026-10-20 |
| TC-2.7-04 | Automated unit test (same file) — fake location services disabled | `start()` returns `serviceDisabled` (distinct from `denied`), API never called | Pass | Confirmed via `flutter test` 2026-10-20 |
| TC-2.7-05 | Automated unit test (same file) — `stop()` called mid-loop | No further polls happen even past the interval the server asked for | Pass | Confirmed via `flutter test` 2026-10-20 |
| TC-2.7-06 | Automated widget test (`test/features/dependent/location_status_banner_test.dart`) — status `granted` | Shows "Location sharing: Active", no button | Pass | Confirmed via `flutter test` 2026-10-20 |
| TC-2.7-07 | Automated widget test (same file) — status `denied` | Shows "Grant Permission" button; tapping it calls the retry callback | Pass | Confirmed via `flutter test` 2026-10-20 |
| TC-2.7-08 | Automated widget test (same file) — status `deniedForever` / `serviceDisabled` | Both show "Open Settings"; tapping calls the settings callback | Pass | Confirmed via `flutter test` 2026-10-20 |
| TC-2.7-09 | Automated widget test (same file) — status `null` | Shows a small spinner, no text/button | Pass | Confirmed via `flutter test` 2026-10-20 |
| TC-2.7-10 | Real device: log in as a Dependent, land on Dependent home, grant location permission when prompted | OS permission dialog appears; banner switches from spinner to "Location sharing: Active" | Not Run | Deferred to full team pass — the one thing the automated tests above can't touch, since Geolocator has no platform channel under `flutter test` |
| TC-2.7-11 | Real device: check Abdullah's backend logs / Postman `GET /dependents/{id}/location` after a few minutes on Dependent home | A real fix shows up with a recent `recorded_at`, and polling interval visibly changes between stationary and moving (walk around with the phone) | Not Run | Deferred to full team pass. Also what finally makes Task 2.6's Live Map show real data instead of Postman-seeded fixtures (TC-2.6-02/03/06/07) |
| TC-2.7-12 | Real device: deny location permission, then deny it again ("don't ask again") | First denial shows "Grant Permission" retry button; second (permanent) denial shows "Open Settings" instead, routing to the app's system settings page | Not Run | Deferred to full team pass |
| TC-2.7-13 | Real device: turn off Location Services entirely (not just app permission), open Dependent home | Shows the "Turn on Location Services..." message with "Open Settings" routing to the OS location settings page (not app settings) | Not Run | Deferred to full team pass |
| TC-2.7-14 | Real device: background the app while location sharing is active, then return to it | Polling visibly stops while backgrounded (no unnecessary battery drain) and resumes on return | Not Run | Deferred to full team pass — confirms the `WidgetsBindingObserver` lifecycle wiring behaves on a real OS, not just in theory |

**Named scope decisions for 2.7:**
- Foreground-only. No Android `ACCESS_BACKGROUND_LOCATION`, no persistent foreground-service notification — scoped to "while the application is active" per FR-C1 and the handbook. Polling starts/stops with the Dependent home screen's lifecycle.
- No offline fix-buffering/queueing. A failed POST just skips that one cycle; the next successful poll continues normally.
- Android only — no iOS `Info.plist` location usage-description keys added (project has been Android-only throughout).
- **Resolved 2026-10-20 (Task 3.10):** the service start/stop calls, originally wired into the Task 1.11 placeholder Dependent home screen, have moved into the real screen built in Task 3.10, as flagged when 2.7 shipped.

---

## Task 2.6 + 2.7 cross-check (why real data is still Postman-only)

Task 2.6's Live Map and Task 2.7's location service are both built and individually tested, but a Dependent's real GPS fix still can't be confirmed end-to-end without a real device (TC-2.7-10/11 above) — that's the one gap linking both tasks' "deferred to full team pass" rows.

---

## Task 3.10 — Dependent Mode home screen

| Test ID | Test Case | Expected Result | Status | Notes |
|---|---|---|---|---|
| TC-3.10-01 | Automated unit test (`test/core/scheduling/schedule_helpers_test.dart`) — daily time later today | Resolves to today at that time | Pass | Confirmed via `flutter test` 2026-10-20 |
| TC-3.10-02 | Automated unit test (same file) — daily time already passed today | Rolls to tomorrow | Pass | Confirmed via `flutter test` 2026-10-20 |
| TC-3.10-03 | Automated unit test (same file) — weekly schedule, specific days | Skips to the next matching weekday, not just the next calendar day | Pass | Confirmed via `flutter test` 2026-10-20 |
| TC-3.10-04 | Automated unit test (same file) — empty `days` list | Treated as "every day", not "never" | Pass | Confirmed via `flutter test` 2026-10-20 |
| TC-3.10-05 | Automated unit test (same file) — malformed time strings (`"25:00"`, `"08:70"`, garbage) | Returns null, never throws | Pass | Confirmed via `flutter test` 2026-10-20 |
| TC-3.10-06 | Automated unit test (same file) — several schedule items | Picks the single soonest one correctly | Pass | Confirmed via `flutter test` 2026-10-20 |
| TC-3.10-07 | Automated unit test (same file) — empty item list | Returns null, not a crash | Pass | Confirmed via `flutter test` 2026-10-20 |
| TC-3.10-08 | Automated unit test (same file) — per-item day restrictions mixed together | Picks the genuinely-soonest item even when a different item's raw time looks closer | Pass | Confirmed via `flutter test` 2026-10-20 |
| TC-3.10-09 | Automated unit test (same file) — weekday name | Correct in both English and Urdu | Pass | Confirmed via `flutter test` 2026-10-20 |
| TC-3.10-10 | Automated unit test (same file) — clock formatting | Midnight → "12:00 AM", noon → "12:00 PM", other times formatted correctly | Pass | Confirmed via `flutter test` 2026-10-20 |
| TC-3.10-11 | Automated widget test (`test/features/dependent/safety_action_buttons_test.dart`) — PanicButton | Shows label/subtitle, tapping calls `onTap` | Pass | Confirmed via `flutter test` 2026-10-20 |
| TC-3.10-12 | Automated widget test (same file) — SafetyActionButton | Shows label/subtitle, tapping calls `onTap` | Pass | Confirmed via `flutter test` 2026-10-20 |
| TC-3.10-13 | Automated widget test (same file) — button text under the large-text theme vs standard | Text genuinely scales up (not a hardcoded fontSize silently ignoring the accessibility toggle) | Pass | Confirmed via `flutter test` 2026-10-20, after a fix to the test itself (compared against the live resolved theme value instead of two separately-built `ThemeData` instances) |
| TC-3.10-14 | Automated widget test (`test/features/dependent/coming_soon_screen_test.dart`) — `ComingSoonKind.medication` | Shows the right title + "coming in Task 3.13" message | Pass | Confirmed via `flutter test` 2026-10-20. Narrowed to `medication` only on 2026-10-20 (Tasks 3.11/3.12) once `panic`/`wellnessCheck` stopped being placeholder kinds — see Task 3.11/3.12 sections below |
| TC-3.10-15 | Real device: log in as a Dependent linked to a Guardian with active medication + wellness-check schedules | Home screen shows the real "Next: {drug} at {time}" and "Next check: {time}" subtitles, not the empty-state text | Not Run | Deferred to full team pass — needs real schedules set up by a Guardian first |
| TC-3.10-16 | Real device: log in as a Dependent with no medication/wellness schedules set up at all | Shows "No medicine scheduled" / "No wellness check scheduled" instead of blank or crashing | Not Run | Deferred to full team pass |
| TC-3.10-17 | Real device: tap Panic, "I am OK", and "My medicine" in turn | Panic opens the real Panic screen (3.11); "I am OK" opens the real Wellness Check screen (3.12); "My medicine" still opens `ComingSoonScreen` (3.13 not built yet) | Not Run | Deferred to full team pass. Updated 2026-10-20 — two of the three destinations are no longer placeholders |
| TC-3.10-18 | Real device: toggle the large-text/high-contrast accessibility mode while on this screen | PANIC/"I am OK"/"My medicine" text visibly grows; button backgrounds/borders still legible; no crash | Not Run | Deferred to full team pass — confirms TC-3.10-13's unit-level guarantee holds visually too |
| TC-3.10-19 | Real device: confirm the location-sharing banner (moved here from the old placeholder) still works on this screen | Same behavior as Task 2.7's TC-2.7-10 — now on the real Home screen instead of the placeholder | Not Run | Deferred to full team pass |

**Named scope decisions for 3.10:**
- Panic / "I am OK" / "My medicine" route to a real destination, but that destination is a named `ComingSoonScreen` placeholder until Tasks 3.11/3.12/3.13 build the actual screens — not a silent gap, same placeholder pattern used since Task 1.11.
- "What's next" is computed from the active *schedule* (`GET .../medications`, `GET .../wellness-checks`), not the dose-list endpoint, since a dose only exists in the system from 15 minutes before it's due — the schedule is the only source that can say "2:00 PM" hours in advance.
- Schedule times are treated as the device's local clock time, matching the backend's `Asia/Karachi` assumption — not corrected for a phone set to a different time zone (named in `schedule_helpers.dart`'s doc comment).
- Weekday names and AM/PM formatting are hand-rolled rather than using `intl`'s locale-aware `DateFormat`, since Urdu locale data for `intl` hasn't been confirmed initialized anywhere else in this project — sidesteps a possible runtime crash in Urdu mode rather than risk it.
- "More: records · appointments · messages" footer is static, non-tappable text labeled "(coming soon)" — those are separate, later tasks/phases (messaging = 4.6, records = Phase 5), not wired here.
- The Task 2.7 location-sharing service/banner moved into this real screen, exactly as flagged when 2.7 shipped.

---

## Task 3.11 — Panic Mode screen

`panic_contract.md` (Task 3.6, FR-D2). Built together with 3.12 in one delivery, per Talha's request to batch tasks — see the standing multi-task-batch convention above.

| Test ID | Test Case | Expected Result | Status | Notes |
|---|---|---|---|---|
| TC-3.11-01 | Automated widget test (`test/features/dependent/panic_hold_button_test.dart`) — hold for the full configured duration | `onHoldComplete` fires exactly once | Pass | Confirmed via `flutter test` 2026-10-20, 49/49 (commit `500973b`) |
| TC-3.11-02 | Automated widget test (same file) — release before the duration elapses | `onHoldComplete` never fires | Pass | Confirmed via `flutter test` 2026-10-20, 49/49 (commit `500973b`) |
| TC-3.11-03 | Automated widget test (same file) — `enabled: false` | A press is ignored entirely | Pass | Confirmed via `flutter test` 2026-10-20, 49/49 (commit `500973b`) |
| TC-3.11-04 | Automated widget test (`test/features/dependent/panic_screen_test.dart`) — fake ApiClient: `GET /panic` → `active: false` | Shows the "Need help? / HOLD" screen | Pass | Confirmed via `flutter test` 2026-10-20, 49/49 (commit `500973b`) |
| TC-3.11-05 | Automated widget test (same file) — fake ApiClient: `GET /panic` → already `active: true` on arrival | Shows "Help is coming" directly, skipping the hold screen (double-tap-safe, matches `already_active`) | Pass | Confirmed via `flutter test` 2026-10-20, 49/49 (commit `500973b`) |
| TC-3.11-06 | Automated widget test (same file) — complete the hold gesture | `POST /dependents/{id}/panic` is called once; screen switches to "Help is coming" with the server's real `notified` count | Pass | Confirmed via `flutter test` 2026-10-20, 49/49 (commit `500973b`) |
| TC-3.11-07 | Automated widget test (same file) — `POST /panic` fails | Error snackbar shown; screen stays on the hold view (not stuck on a broken "active" state) | Pass | Confirmed via `flutter test` 2026-10-20, 49/49 (commit `500973b`) |
| TC-3.11-08 | Automated widget test (same file) — panic `tier: "external_contact"` | Shows "This has reached your emergency contact." note | Pass | Confirmed via `flutter test` 2026-10-20, 49/49 (commit `500973b`) |
| TC-3.11-09 | Automated widget test (same file) — tap "I am safe now" | `POST /panic/resolve` called once; screen navigates away (back to Home in the real app) | Pass | Confirmed via `flutter test` 2026-10-20, 49/49 (commit `500973b`) |
| TC-3.11-10 | Real device: press and hold the real PANIC button for 2 seconds | Ring visibly fills over 2s; releasing early visibly resets it; completing sends the alert | Not Run | Deferred to full team pass — the one thing TC-3.11-01/02 can't show, since those just check the callback fires, not that the animation looks right |
| TC-3.11-11 | Real device + Postman: trigger panic as a Dependent, then `GET /notifications` as the Primary and as a Secondary with no grants | Both show the critical "PANIC ALERT" notification (permissions don't apply to panic, per the contract) | Not Run | Deferred to full team pass. Guardian-side push UI doesn't exist yet (Task 3.14, FCM) — until then this can only be confirmed via Postman/backend, not a real push alert landing on a Guardian's phone |
| TC-3.11-12 | Real device: let a triggered panic sit unacknowledged past the real 5-minute `primary_timeout_s` window | `tier` changes to `external_contact`; the screen's "reached your emergency contact" note appears on the next 15s refresh without needing to reopen the screen | Not Run | Deferred to full team pass — also the one real check on whether "5 minutes" (this screen's copy) actually matches the server's configured timeout, see the named correction below |
| TC-3.11-13 | Real device: toggle large-text/high-contrast mode on this screen | Title/button text visibly grows; red/white contrast still readable; no crash | Not Run | Deferred to full team pass |
| TC-3.11-14 | Native Urdu speaker reads the Panic screen's Urdu strings (`panicNeedHelpTitle` through `panicResolveFailedSnackbar` in `app_ur.arb`) | Phrasing reads naturally, no mistranslation | Not Run | Flagged below — these translations were drafted by Claude, not reviewed by a native speaker yet |

**Named scope decisions / flags for 3.11:**
- **Deviation from Sarim's 21b mockup, contract-grounded:** the mockup's "Help is coming" screen names individual Guardians with per-person "Seen"/"Told" chips. Neither `POST /dependents/{id}/panic` nor `GET /dependents/{id}/panic` returns anything at that granularity — only a `notified` count and one `acknowledged_at` timestamp for the whole event. This screen shows "We told N Guardian(s)" plus a single acknowledged state instead of inventing per-Guardian data the backend doesn't have. Flagged for Sarim/Abdullah — if per-Guardian acknowledgment ever becomes real data, this screen can be upgraded to match 21b exactly.
- **Correction, also contract-grounded:** the mockup's note says "If nobody answers in 10 minutes, your emergency contact gets an SMS." `escalation_contract.md` documents `primary_timeout_s: 300` (5 minutes), and Panic already tells every Guardian in one shot, so a missed panic goes straight from `primary` to `external_contact` after that single 5-minute window — there's no separate secondary wait to add on top. This screen says "5 minutes", the real configured default, not "10". If Abdullah's `.env` ever changes `ESCALATION_PRIMARY_TIMEOUT_S`, this static copy will drift — there's no endpoint a Dependent can read that value from, so this is a known, accepted limitation.
- While a panic is active, the screen polls `GET /dependents/{id}/panic` every 15s so the acknowledged/escalated state stays current without backing out and reopening.
- `PanicHoldButton` uses `onTapDown`/`onTapUp`/`onTapCancel` plus its own `AnimationController`, not Flutter's built-in long-press gesture family — the built-in version has its own internal recognition delay before `onLongPressStart` even fires, which would stack on top of the intended 2-second hold.

---

## Task 3.12 — Wellness Check response screen

`wellness_contract.md` (Task 3.4, FR-D4). Built together with 3.11 in the same delivery.

| Test ID | Test Case | Expected Result | Status | Notes |
|---|---|---|---|---|
| TC-3.12-01 | Automated unit test (`test/core/scheduling/schedule_helpers_test.dart`) — `formatCountdown` with a normal remaining duration | Formats as `mm:ss` with zero-padding | Pass | Confirmed via `flutter test` 2026-10-20, 49/49 (commit `500973b`) |
| TC-3.12-02 | Automated unit test (same file) — `formatCountdown(Duration.zero)` | Formats as `00:00` | Pass | Confirmed via `flutter test` 2026-10-20, 49/49 (commit `500973b`) |
| TC-3.12-03 | Automated unit test (same file) — `formatCountdown` with a negative duration (deadline already passed) | Clamps to `00:00`, never shows a negative time | Pass | Confirmed via `flutter test` 2026-10-20, 49/49 (commit `500973b`) |
| TC-3.12-04 | Automated widget test (`test/features/dependent/wellness_check_screen_test.dart`) — fake ApiClient: `GET .../wellness-check-responses?status=pending` → empty `items` | Shows "There's no wellness check waiting for a response right now."; "I need help" still offered; no "Yes, I am OK" button | Pass | Confirmed via `flutter test` 2026-10-20, 49/49 (commit `500973b`) |
| TC-3.12-05 | Automated widget test (same file) — one pending item with a future `deadline` | Shows "Are you OK?", the countdown chip, and "Yes, I am OK" | Pass | Confirmed via `flutter test` 2026-10-20, 49/49 (commit `500973b`) |
| TC-3.12-06 | Automated widget test (same file) — two pending items with different deadlines | The one with the soonest `deadline` is the one actually answered when "Yes, I am OK" is tapped (`POST` path confirmed) | Pass | Confirmed via `flutter test` 2026-10-20, 49/49 (commit `500973b`) |
| TC-3.12-07 | Automated widget test (same file) — tap "Yes, I am OK" | `POST /wellness-checks/{response_id}/respond` called once; screen navigates away (back to Home in the real app) | Pass | Confirmed via `flutter test` 2026-10-20, 49/49 (commit `500973b`) |
| TC-3.12-08 | Automated widget test (same file) — tap "I need help" | Opens the real Panic screen (3.11), with no pending check required first | Pass | Confirmed via `flutter test` 2026-10-20, 49/49 (commit `500973b`) |
| TC-3.12-09 | Automated widget test (same file) — `POST .../respond` fails | Error snackbar shown; screen stays on the pending view so the Dependent can try again | Pass | Confirmed via `flutter test` 2026-10-20, 49/49 (commit `500973b`) |
| TC-3.12-10 | Real device: Guardian schedules a wellness check 2 minutes out (needs Task 3.15, not built — use Postman against the Dependent's own token in the meantime), then open "I am OK" on the Dependent's phone at that time | Real countdown ticks down live; tapping "Yes, I am OK" closes it server-side | Not Run | Deferred to full team pass — also the first real (non-Postman) confirmation that the countdown math and the server's `deadline` agree |
| TC-3.12-11 | Real device: let a prompted check's grace period lapse with no answer and no recent device activity | Check becomes `escalated`; Primary Guardian is alerted (Postman/backend-log check, since 3.14's push UI doesn't exist yet) | Not Run | Deferred to full team pass |
| TC-3.12-12 | Real device: toggle large-text/high-contrast mode on this screen | Title/button text visibly grows; no crash | Not Run | Deferred to full team pass |
| TC-3.12-13 | Native Urdu speaker reads the Wellness Check screen's Urdu strings (`wellnessCheckScreenTitle` through `wellnessCheckRespondFailedSnackbar` in `app_ur.arb`) | Phrasing reads naturally, no mistranslation | Not Run | Same flag as TC-3.11-14 — batch this review with 3.11's once there's a convenient moment, rather than two separate passes |

**Named scope decisions for 3.12:**
- The mockup assumes entry from a push notification carrying a live `response_id` (Task 3.14's FCM work, not built yet). Until then, Home's "I am OK" button opens this screen with nothing extra attached, so it looks up whichever check is `pending` for the Dependent via `GET /dependents/{id}/wellness-check-responses?status=pending` (allowed per the contract's "Read checks and history" row) and answers that one.
- If more than one check is somehow pending, the one with the soonest `deadline` is shown — the mockup only has room for one card, and in practice at most one is normally open.
- If none are pending (opened proactively, not from a prompt), the screen says so plainly rather than showing a countdown for nothing.
- Per Sarim's 3.9 design note, "I need help" always opens the Panic screen, independent of whether a check is pending — not gated behind having an active prompt.
- The on-screen countdown is local UI only, computed from the server's `deadline`; it does not drive the actual grace-period/escalation logic (that's entirely server-side), so the countdown hitting zero is informational, not an error state — the Dependent can still answer late.

---

## Task 3.13 — Medication Confirmation screen

`medication_contract.md`'s two-step confirm flow (FR-F1.3, mockups 23/23b). Built together with 3.15 in one delivery — 3.14 (the natural next task) swapped out because it needs a Firebase project + service-account key only Talha can set up; see the standing multi-task-batch convention above.

| Test ID | Test Case | Expected Result | Status | Notes |
|---|---|---|---|---|
| TC-3.13-01 | Automated widget test (`test/features/dependent/medication_confirm_screen_test.dart`) — fake ApiClient: `GET .../medication-doses?status=pending` → empty `items` | Shows "There's no medicine due right now."; no prompt/confirm UI | Not Run | Needs `flutter test` to confirm |
| TC-3.13-02 | Automated widget test (same file) — fake ApiClient throws on the initial GET | Shows the error message + a working Retry that re-fetches | Not Run | Needs `flutter test` to confirm |
| TC-3.13-03 | Automated widget test (same file) — a dose is due, opened without `skipPrompt` | Shows the step-1 "It's time for your medicine" prompt first; tapping "I took it" calls `POST .../confirm-request` and moves to the step-2 confirm view with the countdown chip | Not Run | Needs `flutter test` to confirm |
| TC-3.13-04 | Automated widget test (same file) — opened with `skipPrompt: true` (Home already asked) | Skips the step-1 prompt entirely and lands straight on step 2, firing `confirm-request` automatically | Not Run | Needs `flutter test` to confirm |
| TC-3.13-05 | Automated widget test (same file) — full happy path: step 1 → step 2 → confirm | `POST .../confirm` sends the `confirm_token`; screen shows "Marked as taken"; tapping "Done" returns to Home | Not Run | Needs `flutter test` to confirm |
| TC-3.13-06 | Automated widget test (same file) — the confirm token is already expired | Shows "This confirmation window expired." + "Try again" instead of the Confirm button; tapping it re-requests a fresh token | Not Run | Needs `flutter test` to confirm |
| TC-3.13-07 | Automated widget test (same file) — `POST .../confirm-request` fails from the step-1 prompt | Shows an error snackbar, stays on the step-1 prompt so the Dependent can just tap "I took it" again | Not Run | Needs `flutter test` to confirm |
| TC-3.13-08 | Automated widget test (same file) — `POST .../confirm` fails on step 2 | Shows an error snackbar, stays on step 2 (not stuck or bounced to a generic error screen) | Not Run | Needs `flutter test` to confirm |
| TC-3.13-09 | Real device: a dose is currently due, open "My medicine" from Home | Home's button already reads "I took my medicine · Step 1 of 2"; tapping it lands straight on the step-2 confirm view (mockup 23b), not the step-1 prompt (23) | Not Run | Deferred to full team pass |
| TC-3.13-10 | Real device: no dose due, open "My medicine" from Home | Shows "There's no medicine due right now." | Not Run | Deferred to full team pass |
| TC-3.13-11 | Real device: let the real 2-minute confirm token actually expire by waiting | Same "Try again" behavior as TC-3.13-06, confirmed against real server-side token expiry instead of a forced `expires_in_s: -5` | Not Run | Deferred to full team pass |
| TC-3.13-12 | Real device: toggle large-text/high-contrast mode on this screen | Title/button text visibly grows; no crash | Not Run | Deferred to full team pass |
| TC-3.13-13 | Native Urdu speaker reads this screen's Urdu strings (`medicationScreenTitle` through `medicineConfirmFailedSnackbar` in `app_ur.arb`) | Phrasing reads naturally, no mistranslation | Not Run | Same standing flag as TC-3.11-14/TC-3.12-13 |

**Named scope decisions for 3.13:**
- One screen covers both mockups 23 and 23b, because Sarim's Home-screen v0.2 update changes which mockup a given entry point lands on — see `medication_confirm_screen.dart`'s doc comment and `skipPrompt`. Opened from Home when a dose is already due, the screen skips straight to step 2 (23b); opened any other way, it shows step 1 first (23).
- Self-resolves which dose it's about via `GET .../medication-doses?status=pending`, same reasoning as 3.12's Wellness Check — a dose only exists in that list from 15 minutes before it's due, and self-resolving means this screen works whether Home linked straight to it or (once 3.14 ships) a push notification did.
- If more than one dose is somehow pending at once, the soonest `scheduled_for` wins — same tie-break pattern used in 3.10/3.12.
- The Guardian-side "extend +30 min" action (`POST .../medication-doses/{id}/extend`), noted as an open discussion point in Sarim's 3.9 README, is a Guardian action, not a Dependent one — deferred to Task 3.14's Guardian alert UI, not built here.
- `ComingSoonScreen` and its test (`coming_soon_screen.dart`/`coming_soon_screen_test.dart`) are deleted as of this task — confirmed via a repo-wide grep that only `app_router.dart` and the screen's own test referenced it, and this was the last of the three Task 3.10 placeholders (Panic and Wellness Check already replaced it in 3.11/3.12). See the delivery message for the exact deletion commands. The now-dead `medicationComingSoonMessage` l10n key was removed from both `.arb` files at the same time.

---

## Task 3.15 — Guardian-side schedule configuration

Two screens, one per contract — `medication_contract.md`'s schedule endpoints and `wellness_contract.md`'s Guardian-side endpoints. No standalone `schedule_contract.md` exists; Guardian-side scheduling for both lives inside their respective existing contracts. Built together with 3.13 in the same delivery; swapped in for 3.14 per the standing multi-task-batch convention above.

| Test ID | Test Case | Expected Result | Status | Notes |
|---|---|---|---|---|
| TC-3.15-01 | Automated unit test (`test/core/scheduling/schedule_helpers_test.dart`) — `formatHHMM` with valid "HH:MM" strings | Formats the same way `formatClockTime` does (midnight/noon/other times) | Not Run | Needs `flutter test` to confirm |
| TC-3.15-02 | Automated unit test (same file) — `formatHHMM` with malformed strings | Returned unchanged, never throws | Not Run | Needs `flutter test` to confirm |
| TC-3.15-03 | Automated widget test (`test/features/guardian/medication_schedule_screen_test.dart`) — Primary, a daily schedule | List item shows "{drug} · {dosage}" and "{time} · Daily" | Not Run | Needs `flutter test` to confirm |
| TC-3.15-04 | Automated widget test (same file) — a weekly schedule | Days shown abbreviated and localized, e.g. "Weekly (Mon, Wed, Fri)" | Not Run | Needs `flutter test` to confirm |
| TC-3.15-05 | Automated widget test (same file) — Secondary without `medication_management` | Read-only: denial note shown, no Add button, toggle switch disabled | Not Run | Needs `flutter test` to confirm |
| TC-3.15-06 | Automated widget test (same file) — Secondary WITH `medication_management` | Full access: Add button present, toggle switch enabled, no denial note | Not Run | Needs `flutter test` to confirm |
| TC-3.15-07 | Automated widget test (same file) — toggle a schedule off | `PUT .../medications/{id}` sent with `{active: false}`; switch keeps the new value | Not Run | Needs `flutter test` to confirm |
| TC-3.15-08 | Automated widget test (same file) — toggle fails (`MODULE_ACCESS_DENIED`) | Switch reverts to its original value; mapped denial message shown, not the raw server message | Not Run | Needs `flutter test` to confirm |
| TC-3.15-09 | Automated widget test (same file) — Add form, required fields left empty | Save is blocked with an inline "This field is required"; no `POST` sent | Not Run | Needs `flutter test` to confirm |
| TC-3.15-10 | Automated widget test (same file) — Add form, Weekly selected with no day picked | Save is blocked with "Pick at least one day for a weekly schedule."; no `POST` sent | Not Run | Needs `flutter test` to confirm |
| TC-3.15-11 | Automated widget test (same file) — Add form, valid daily entry | `POST .../medications` sent with the right body (no stray `days` key for a daily schedule); "Saved." shown; list reloads | Not Run | Needs `flutter test` to confirm |
| TC-3.15-12 | Automated widget test (`test/features/guardian/wellness_schedule_screen_test.dart`) — Primary, empty schedule | Shows "No wellness check times scheduled yet." plus the "Use default schedule" shortcut | Not Run | Needs `flutter test` to confirm |
| TC-3.15-13 | Automated widget test (same file) — tap "Use default schedule" | `POST .../wellness-checks/default-schedule` sent; "Saved." shown; list reloads | Not Run | Needs `flutter test` to confirm |
| TC-3.15-14 | Automated widget test (same file) — default-schedule call fails with an unmapped error code | Raw server message shown as-is (no generic fallback swallowing it) | Not Run | Needs `flutter test` to confirm |
| TC-3.15-15 | Automated widget test (same file) — Secondary without `emergency_alerts` | Read-only: denial note shown, no Add button, no "Use default schedule" shortcut either, toggle disabled | Not Run | Needs `flutter test` to confirm |
| TC-3.15-16 | Automated widget test (same file) — Secondary WITH `emergency_alerts` | Full access: Add button present, toggle enabled, no denial note | Not Run | Needs `flutter test` to confirm |
| TC-3.15-17 | Automated widget test (same file) — toggle a check off | `PUT .../wellness-checks/{id}` sent with `{active: false}` | Not Run | Needs `flutter test` to confirm |
| TC-3.15-18 | Automated widget test (same file) — Add form fails with `WELLNESS_LIMIT_REACHED` | Mapped "You can have at most 3 wellness check times." shown, not the raw message or the generic fallback | Not Run | Needs `flutter test` to confirm |
| TC-3.15-19 | Automated widget test (same file) — Add form, valid new time | `POST .../wellness-checks` sent with `{times: [time], grace_period_min: ...}`; "Saved." shown; list reloads | Not Run | Needs `flutter test` to confirm |
| TC-3.15-20 | Real device: Primary grants/denies `medication_management`/`emergency_alerts` to a Secondary via the real Permissions dashboard (3.5), then that Secondary opens both schedule screens | Access flips between read-only and full exactly as the automated permission tests predict | Not Run | Deferred to full team pass — the one real multi-account confirmation the widget tests above can't do |
| TC-3.15-21 | Real device: use the real time picker in both Add forms | Picks a time correctly; the picked value round-trips through Save into the right request body | Not Run | Deferred to full team pass — `showTimePicker`'s native dialog isn't exercised by the widget tests above |
| TC-3.15-22 | Real device: toggle large-text/high-contrast mode on both screens | Text visibly grows on both; no crash | Not Run | Deferred to full team pass |
| TC-3.15-23 | Native Urdu speaker reads both screens' Urdu strings (`medicationScheduleButton` through `daySunLabel` in `app_ur.arb`) | Phrasing reads naturally, no mistranslation | Not Run | Same standing flag as TC-3.11-14/TC-3.12-13/TC-3.13-13 |

**Named scope decisions for 3.15:**
- No Sarim mockup exists for either screen ("No Sarim dependency" per the task list) — both are styled consistently with `permissions_dashboard_screen.dart`/`my_access_screen.dart` rather than following a specific design.
- Permission model on both contracts: any Guardian can read; only create/edit/toggle need the specific module (`medication_management` / `emergency_alerts`). Rather than duplicating permission logic client-side as the real security boundary, both screens follow `live_map_screen.dart`'s established pattern — attempt the write, map a `MODULE_ACCESS_DENIED` failure to a clear message. The upfront `GET .../permissions/me` check (Secondary only) is a UX nicety so a Secondary without the grant sees a read-only screen instead of being told no only after tapping Add — it is not the real gate; the backend remains that.
- `DELETE` exists on both contracts but has the identical effect to `PUT {active: false}` (both are a soft-off) — one Active switch is used instead of a second control that does the same thing under a different name.
- Wellness-check creation is incremental-add (`POST .../wellness-checks` adds to the existing schedule, erroring `WELLNESS_LIMIT_REACHED`/`WELLNESS_TIME_EXISTS` rather than replacing it) — this screen's Add form always posts exactly one new time per call, matching that semantics rather than trying to resend the whole list.
- "Use default schedule" is only offered while the wellness schedule is empty, since calling it against an existing schedule just 409s (`SCHEDULE_ALREADY_EXISTS`) for no benefit.

---

## Open cross-cutting items

- Router has no redirect-guard hardening against direct/deep-link access to protected routes.
- No resume path for a Dependent who closes the app mid-KYC before being linked.
- Layout mismatch against Sarim's wireframes 05 ("Share my ID") and 09 ("Link a Dependent") — functional but doesn't match her design. Flagged to Sarim 2026-10-20, not yet fixed.
- Safe-zone create/edit/delete UI — deliberately deferred out of Task 2.6.
- "More" footer links (records, appointments, messages) on the Dependent home screen are non-functional placeholders — real destinations land in later tasks (4.6, Phase 5, etc.).
- **New Urdu strings from Tasks 3.11/3.12 (Panic + Wellness Check, ~26 keys) were drafted by Claude, not reviewed by a native Urdu speaker.** Same caveat applies to every other Urdu string in this app so far, but flagging these specifically since Panic/Wellness Check are the highest-stakes screens in the app to get wrong — worth a deliberate read-through by Talha or Sarim before the final demo, not just a "looks fine" skim.
- **Guardian-side confirmation that Panic/Wellness Check alerts actually reach a person is Postman/backend-log only until Task 3.14 (FCM) ships** — there is no Guardian-facing push notification UI yet, so TC-3.11-11 and TC-3.12-11 can't be fully end-to-end confirmed on a real device until then.
- **New Urdu strings from Tasks 3.13/3.15 (~37 keys total) were drafted by Claude, not reviewed by a native Urdu speaker** — same standing caveat as the 3.11/3.12 note above, now applying to the Medication Confirmation and both schedule screens too.
- **`ComingSoonScreen`/`ComingSoonKind` and `coming_soon_screen_test.dart` are deleted as of Task 3.13** — confirmed via a repo-wide grep that nothing but `app_router.dart` and the screen's own test referenced it, and `/dependent/medication` was its last live use. If a merge conflict or a stray import resurrects a reference to either name, that's a sign something didn't get the delete correctly, not that the class is still meant to exist.
- **3.14 (Firebase/FCM) is still not built** — swapped out of this batch and the 3.11/3.12 batch before it, same reason both times (needs a Firebase project + service-account key only Talha can set up). Until it ships, Guardian-side push confirmation for Panic/Wellness Check/Medication all stay Postman/backend-log only (see the row above), and neither Medication nor Wellness Check screens can be opened from a real push notification yet — only from Home or (for Medication) the schedule screens' own entry points.
- **Full team test pass still required before final submission.** Every "Deferred to full team pass" row above has zero real/device/multi-account confirmation yet. Needs scheduling with Abdullah and Sarim before the project is actually done.
