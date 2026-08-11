/// Task 1.9 — the two visual modes the app supports.
///
/// `standard`     -> normal Material text sizes and the default color scheme.
/// `highContrast` -> larger text (FR-P2 "large-text") and a high-contrast
///                   color scheme, for low-vision / elderly Dependents and
///                   Guardians. Both modes are meant to meet the NFR-08
///                   contrast targets — this toggle is about how much
///                   further the app goes beyond the baseline.
enum AccessibilityMode { standard, highContrast }
