# Humsafar • Talha — Frontend

Talha's personal working repository for the Humsafar Flutter frontend (Guardian + Dependent apps), part of the Humsafar Intelligent Remote Patient Care & Monitoring Ecosystem FYP.

This is a **personal working/staging repo**, separate from the shared team repo (`mabdullahghafoor/humsafar`). Task numbers below match the team's Master Development Roadmap exactly, so history stays traceable back to the plan even though this repo is solo.

## Status

- Task 0.4 — Flutter project skeleton (folder structure, Riverpod setup, routing skeleton) — done
- Task 1.8 — Navigation shell (Guardian app + Dependent app routing) — done
- Task 1.9 — Theming system (standard mode + large-text/high-contrast toggle) — done
- Task 1.10 — Localization scaffold (English/Urdu, includes in-app language switcher) — done

## Setup

```bash
flutter pub get
flutter run
```

## Structure

```
lib/
├── main.dart
├── core/
│   ├── router/        # go_router configuration
│   └── theme/          # theming (Task 1.9)
├── features/
│   ├── splash/
│   ├── onboarding/      # temporary dev role-picker, removed once real auth lands
│   ├── guardian/
│   └── dependent/
├── providers/           # app-wide Riverpod providers
└── shared/widgets/      # reusable widgets used across more than one feature
```

## Workflow (solo)

Even working alone, commits stay small and traceable to a task number, same convention as the team repo:

```bash
git add <specific files>       # not -A, to avoid ever sweeping in build artifacts
git commit -m "feat: <what> (Task <#>)"
git push
```

## Syncing back to the team repo

This repo is where the frontend actually gets built day to day. When a task here is stable and ready to share, the plan is to copy the relevant contents of `lib/` (and any updated `pubspec.yaml` dependencies) into the `frontend/` folder of the shared team repo, on a proper `feature/talha-<task>` branch, and open a PR into `dev` — same as the rest of the team. Nothing here is meant to stay permanently disconnected from the shared repo; this is a safe place to work without risk of an accidental direct push to the team's `main`, not a replacement for eventually integrating.
