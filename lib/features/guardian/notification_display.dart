import 'package:flutter/material.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../core/theme/humsafar_colors.dart';

/// Task 3.14 — small, pure (no network, no BuildContext-dependent state)
/// helpers for turning one `GET /notifications` item (notification_contract.md)
/// into display strings/colors. Shared between GuardianHomeScreen's "Needs
/// attention" preview and AlertsScreen's full list so the two don't grow
/// two slightly-different copies of the same type→label mapping.
///
/// Only the alert `type`s a Guardian can receive are mapped here (per
/// notification_contract.md's "Who is told" table): `panic`,
/// `missed_dose`, `wellness_check`, `geofence_breach`, `low_battery`,
/// `device_offline`, `external_contact`. Anything else falls back to the
/// server's own `title`/`body` text untranslated — this screen never
/// receives the Dependent-facing or Phase-4/5 types (`medication_due`,
/// `message`, `incoming_call`, ...), so a fallback is enough, not a gap.

/// Localized label for a notification's `type`.
String alertTypeLabel(AppLocalizations l10n, String type) {
  switch (type) {
    case 'panic':
      return l10n.alertTypePanic;
    case 'missed_dose':
      return l10n.alertTypeMissedDose;
    case 'wellness_check':
      return l10n.alertTypeWellnessCheck;
    case 'geofence_breach':
      return l10n.alertTypeGeofenceBreach;
    case 'low_battery':
      return l10n.alertTypeLowBattery;
    case 'device_offline':
      return l10n.alertTypeDeviceOffline;
    case 'external_contact':
      return l10n.alertTypeExternalContact;
    default:
      return l10n.alertTypeGeneric;
  }
}

/// Icon + accent color for a notification's `type`, matching mockup 08's
/// red (panic) / amber (everything else critical) left-edge coloring.
({IconData icon, Color color}) alertVisualsFor(String type) {
  switch (type) {
    case 'panic':
      // Fix #2 (Design Handoff v1.0, section 3): tokenized, kept red on
      // purpose — this is literally the Panic alert type, matching the
      // handoff's "red for Panic and critical alerts" rule. Every other
      // type below moved to the warning token (amber), per this
      // function's own doc comment on mockup 08's convention.
      return (icon: Icons.warning_rounded, color: HumsafarColors.danger);
    case 'missed_dose':
      return (icon: Icons.medication_outlined, color: HumsafarColors.warning);
    case 'wellness_check':
      return (icon: Icons.favorite_border, color: HumsafarColors.warning);
    case 'geofence_breach':
      return (icon: Icons.location_off_outlined, color: HumsafarColors.warning);
    case 'low_battery':
      return (icon: Icons.battery_alert_outlined, color: HumsafarColors.warning);
    case 'device_offline':
      return (icon: Icons.phonelink_erase_outlined, color: HumsafarColors.warning);
    case 'external_contact':
      return (icon: Icons.sms_outlined, color: HumsafarColors.warning);
    default:
      return (icon: Icons.notifications_outlined, color: HumsafarColors.muted);
  }
}

/// "Level 1 · Primary" / "Level 2 · Secondary" / "Level 3 · SMS sent"
/// (mockup 08), straight from the notification's own `data.tier` — no
/// extra `GET /dependents/{id}/escalations` call needed, since
/// escalation_contract.md's three tier values (`primary`, `secondary`,
/// `external_contact`) are exactly notification_contract.md's own
/// `data.tier` values for an alert that has climbed the chain. Null
/// (panic's own `data` has no `tier`, nor do geofence/battery/offline,
/// which don't climb the chain at all) means "don't show a badge".
String? tierBadgeLabel(AppLocalizations l10n, String? tier) {
  switch (tier) {
    case 'primary':
      return l10n.tierLevel1PrimaryLabel;
    case 'secondary':
      return l10n.tierLevel2SecondaryLabel;
    case 'external_contact':
      return l10n.tierLevel3SmsLabel;
    default:
      return null;
  }
}
