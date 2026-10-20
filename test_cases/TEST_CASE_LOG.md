# Humsafar (Talha's frontend) — Test Case Log

One row per test case, tagged to the task number it came from. Full exhaustive pass happens once the whole app is ready. Updated by Claude as part of every task's delivery zip — this is the one and only test case file for this repo; never duplicated, never versioned as a dated copy.

Status values: `Not Run` · `Pass` · `Fail` · `Fixed` (was Fail, now resolved — re-run to confirm before changing to Pass).

**Standing test-strategy convention (decided 2026-10-20):** the "soft"/smoke-check test case for each task is an **automated Flutter widget test** (added under `test/`) using a fake `ApiClient` — no real backend, no login, no linked Guardian/Dependent accounts, no device. Run with `flutter test`.
- What this catches: screen logic, error-message mapping, loading/empty/error states, wiring bugs.
- What this does *not* catch, and stays deferred to one full team pass before final submission: real on-device rendering, true multi-account flows (Secondary permission gating, invite acceptance), and anything needing real OS-level behavior — background services, push notifications, real calls. Flagged explicitly, task by task, whenever a widget test alone gives weaker confidence than usual because of this.

**Standing delivery convention:** before any manual "run the app" step, confirm the backend is running first (`cd D:\humsafar\backend` → `.\venv\Scripts\Activate.ps1` → `uvicorn app.main:app --reload`, its own terminal).

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
| TC-2.6-08 | Automated widget test (same file) — fake ApiClient returns no location, zone `no_zones` | Shows "No safe zones set up yet" + "No location received yet.", no crash | Pass | Confirmed via `flutter test` 2026-10-20 |

**Named scope decision for 2.6:** read-only screen (view location + zones). Safe-zone create/edit/delete explicitly deferred, not part of this task.

---

## Open cross-cutting items

- Router has no redirect-guard hardening against direct/deep-link access to protected routes.
- No resume path for a Dependent who closes the app mid-KYC before being linked.
- Layout mismatch against Sarim's wireframes 05 ("Share my ID") and 09 ("Link a Dependent") — functional but doesn't match her design. Flagged to Sarim 2026-10-20, not yet fixed.
- Safe-zone create/edit/delete UI — deliberately deferred out of Task 2.6.
- **Full team test pass still required before final submission.** Every "Deferred to full team pass" row above has zero real/device/multi-account confirmation yet. Needs scheduling with Abdullah and Sarim before the project is actually done.
