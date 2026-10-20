# Humsafar (Talha's frontend) — Test Case Log

One row per test case, tagged to the task number it came from. Full exhaustive pass happens once the whole app is ready. Updated by Claude as part of every task's delivery zip — this is the one and only test case file for this repo; never duplicated, never versioned as a dated copy.

Status values: `Not Run` · `Pass` · `Fail` · `Fixed` (was Fail, now resolved — re-run to confirm before changing to Pass).

**Standing test-strategy convention (decided 2026-10-20):** the "soft"/smoke-check test case for each task is an **automated Flutter widget/unit test** (added under `test/`) using fakes instead of the real backend/GPS/plugins — no login, no linked Guardian/Dependent accounts, no device. Run with `flutter test`.
- What this catches: screen/service logic, error-message mapping, loading/empty/error states, wiring bugs.
- What this does *not* catch, and stays deferred to one full team pass before final submission: real on-device rendering, true multi-account flows (Secondary permission gating, invite acceptance), and anything needing real OS-level behavior — background services, push notifications, real calls, real GPS/permission dialogs. Flagged explicitly, task by task, whenever a widget test alone gives weaker confidence than usual because of this.

**Standing delivery convention:** before any manual "run the app" step, confirm the backend is running first (`cd D:\humsafar\backend` → `.\venv\Scripts\Activate.ps1` → `uvicorn app.main:app --reload`, its own terminal).

**Standing research convention (added 2026-10-20):** before building each task, Claude pulls the latest `mabdullahghafoor/humsafar` `dev` branch fresh and re-reads the actual contracts/mockups — never from memory — since Abdullah and Sarim push updates frequently.

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
| TC-3.10-01 | Automated unit test (`test/core/scheduling/schedule_helpers_test.dart`) — daily time later today | Resolves to today at that time | Not Run | Needs `flutter test` to confirm |
| TC-3.10-02 | Automated unit test (same file) — daily time already passed today | Rolls to tomorrow | Not Run | Needs `flutter test` to confirm |
| TC-3.10-03 | Automated unit test (same file) — weekly schedule, specific days | Skips to the next matching weekday, not just the next calendar day | Not Run | Needs `flutter test` to confirm |
| TC-3.10-04 | Automated unit test (same file) — empty `days` list | Treated as "every day", not "never" | Not Run | Needs `flutter test` to confirm |
| TC-3.10-05 | Automated unit test (same file) — malformed time strings (`"25:00"`, `"08:70"`, garbage) | Returns null, never throws | Not Run | Needs `flutter test` to confirm |
| TC-3.10-06 | Automated unit test (same file) — several schedule items | Picks the single soonest one correctly | Not Run | Needs `flutter test` to confirm |
| TC-3.10-07 | Automated unit test (same file) — empty item list | Returns null, not a crash | Not Run | Needs `flutter test` to confirm |
| TC-3.10-08 | Automated unit test (same file) — per-item day restrictions mixed together | Picks the genuinely-soonest item even when a different item's raw time looks closer | Not Run | Needs `flutter test` to confirm |
| TC-3.10-09 | Automated unit test (same file) — weekday name | Correct in both English and Urdu | Not Run | Needs `flutter test` to confirm |
| TC-3.10-10 | Automated unit test (same file) — clock formatting | Midnight → "12:00 AM", noon → "12:00 PM", other times formatted correctly | Not Run | Needs `flutter test` to confirm |
| TC-3.10-11 | Automated widget test (`test/features/dependent/safety_action_buttons_test.dart`) — PanicButton | Shows label/subtitle, tapping calls `onTap` | Not Run | Needs `flutter test` to confirm |
| TC-3.10-12 | Automated widget test (same file) — SafetyActionButton | Shows label/subtitle, tapping calls `onTap` | Not Run | Needs `flutter test` to confirm |
| TC-3.10-13 | Automated widget test (same file) — button text under the large-text theme vs standard | Text genuinely scales up (not a hardcoded fontSize silently ignoring the accessibility toggle) | Not Run | Needs `flutter test` to confirm. This is the one that would have caught a real accessibility bug if the buttons had been built with fixed font sizes |
| TC-3.10-14 | Automated widget test (`test/features/dependent/coming_soon_screen_test.dart`) — all 3 `ComingSoonKind` values | Each shows its own correct title + "coming in Task X.XX" message | Not Run | Needs `flutter test` to confirm |
| TC-3.10-15 | Real device: log in as a Dependent linked to a Guardian with active medication + wellness-check schedules | Home screen shows the real "Next: {drug} at {time}" and "Next check: {time}" subtitles, not the empty-state text | Not Run | Deferred to full team pass — needs real schedules set up by a Guardian first |
| TC-3.10-16 | Real device: log in as a Dependent with no medication/wellness schedules set up at all | Shows "No medicine scheduled" / "No wellness check scheduled" instead of blank or crashing | Not Run | Deferred to full team pass |
| TC-3.10-17 | Real device: tap Panic, "I am OK", and "My medicine" in turn | Each opens its own ComingSoonScreen with the right title/message (real screens land in 3.11/3.12/3.13) | Not Run | Deferred to full team pass |
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

## Open cross-cutting items

- Router has no redirect-guard hardening against direct/deep-link access to protected routes.
- No resume path for a Dependent who closes the app mid-KYC before being linked.
- Layout mismatch against Sarim's wireframes 05 ("Share my ID") and 09 ("Link a Dependent") — functional but doesn't match her design. Flagged to Sarim 2026-10-20, not yet fixed.
- Safe-zone create/edit/delete UI — deliberately deferred out of Task 2.6.
- "More" footer links (records, appointments, messages) on the Dependent home screen are non-functional placeholders — real destinations land in later tasks (4.6, Phase 5, etc.).
- **Full team test pass still required before final submission.** Every "Deferred to full team pass" row above has zero real/device/multi-account confirmation yet. Needs scheduling with Abdullah and Sarim before the project is actually done.
