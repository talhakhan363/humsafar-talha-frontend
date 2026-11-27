import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/scheduling/schedule_helpers.dart';
import '../../../core/theme/accessibility_mode.dart';
import '../../../core/theme/accessibility_mode_provider.dart';
import '../../../core/theme/humsafar_colors.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../guardian/notification_display.dart';

/// Bug fix (F-28 continuation, Sarim's 1.9.5 retest): "the Dependent side
/// has no way in" — `GuardianHomeScreen` has had a bell icon into
/// `AlertsScreen` since this same F-28's first half, but there was no
/// equivalent anywhere in Dependent Mode at all.
///
/// **Deliberately NOT a reuse of `AlertsScreen`.** `notification_contract.md`'s
/// own "Who is told" table (line 18) is explicit: "The Dependent | Never
/// told about their own alert (they use the Dependent Mode screens)" — a
/// Dependent structurally never receives the Guardian-facing
/// critical/escalation types (`panic`, `missed_dose`, `geofence_breach`,
/// ...) that `AlertsScreen`'s Open/Seen tabs and acknowledge flow exist
/// for, and that screen's own `_load()` calls `GET /guardians/me/dependents`
/// to resolve whose alert is whose — a Guardian-only endpoint a Dependent
/// account cannot call. Reusing it as-is would have been wrong, not just
/// inconvenient.
///
/// What a Dependent DOES get, per the same contract, that has no screen
/// of its own yet: every type that is informational rather than
/// self-resolving-via-its-own-push-tap. The critical Dependent-facing
/// types (`medication_reminder`/`medication_due`/`medication_extended`,
/// `wellness_check_prompt`, `incoming_call`, `remote_alarm`) already each
/// open their own dedicated screen straight from the push tap
/// (`push_service.dart`'s `routeForNotificationType`/`incomingCallPushData`)
/// — this screen is for the rest: `appointment_update`,
/// `appointment_reminder`, `booking_update`, `camera_view`, `missed_call`,
/// all `priority: "standard"` — exactly `AlertsScreen`'s own "Notices" tab,
/// just without the Open/Seen/acknowledge machinery that tab's siblings
/// need and this screen's audience never will.
///
/// Read-only by design: `notification_contract.md` never asks for
/// acknowledgment on a `standard` notification (that's an Open/Seen,
/// critical-only concept), so there's nothing here to confirm.
///
/// **Named limitation, flagged rather than silently accepted:**
/// `notification_display.dart`'s `alertTypeLabel`/`alertVisualsFor` are
/// documented there as covering only the Guardian-facing types this
/// screen deliberately does NOT show — every type this screen actually
/// lists falls through to their generic defaults (a plain bell icon,
/// `l10n.alertTypeGeneric` title). The server's own `title`/`body` text
/// (English only, per the contract's own note) is shown underneath, so
/// nothing is unreadable, just not yet localized/iconified per type —
/// the same kind of named, deliberate scope cut `AlertsScreen`'s own
/// doc comment already makes for its own gaps (e.g. "no deeper screen
/// for geofence/battery/..."). A follow-up task can give these five
/// types their own labels/icons in notification_display.dart the same
/// way the Guardian-facing ones already have them.
class DependentNoticesScreen extends ConsumerStatefulWidget {
  const DependentNoticesScreen({super.key});

  @override
  ConsumerState<DependentNoticesScreen> createState() => _DependentNoticesScreenState();
}

class _DependentNoticesScreenState extends ConsumerState<DependentNoticesScreen>
    with SkeletonTimeoutMixin<DependentNoticesScreen> {
  List<Map<String, dynamic>> _notices = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    // Same "a skeleton never loops forever" rule as AlertsScreen/every
    // other skeleton-loading screen in this app — see
    // skeleton_loader.dart's SkeletonTimeoutMixin doc comment.
    startSkeletonTimeout(() {
      setState(() {
        _isLoading = false;
        _loadError = AppLocalizations.of(context)!.cantReachServerError;
      });
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>('/notifications', queryParameters: {'priority': 'standard'});
      if (!mounted) return;
      setState(() {
        _notices = (response.data?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    } finally {
      cancelSkeletonTimeout();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dependentNoticesScreenTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      body: SafeArea(bottom: true, top: false, child: RefreshIndicator(onRefresh: _load, child: _buildBody(l10n))),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: Text(l10n.retryButton)),
            ],
          ),
        ),
      );
    }
    if (_isLoading) {
      return SkeletonShimmer(
        highContrast: ref.watch(accessibilityModeProvider) == AccessibilityMode.highContrast,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          children: const [
            SkeletonListCard(leadingIsCircle: false),
            SkeletonListCard(leadingIsCircle: false),
            SkeletonListCard(leadingIsCircle: false),
          ],
        ),
      );
    }
    if (_notices.isEmpty) {
      return Center(child: Text(l10n.alertsEmptyNoticesMessage, textAlign: TextAlign.center));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      children: _notices.map((n) => _NoticeCard(notification: n)).toList(),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notification});

  final Map<String, dynamic> notification;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = notification['type'] as String? ?? '';
    final visuals = alertVisualsFor(type);
    final sentAt = DateTime.tryParse(notification['sent_at'] as String? ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: visuals.color, width: 4)),
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 3, offset: const Offset(0, 1))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(visuals.icon, color: visuals.color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notificationTitle(l10n, notification),
                    style: TextStyle(fontWeight: FontWeight.bold, color: visuals.color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              sentAt == null ? (notification['body'] as String? ?? '') : formatAlertTimestamp(sentAt, DateTime.now()),
              style: const TextStyle(color: HumsafarColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
