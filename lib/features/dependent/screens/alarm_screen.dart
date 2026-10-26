import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/auth/current_user_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/scheduling/schedule_helpers.dart';
import '../../../core/theme/humsafar_colors.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 3.14 — mockup 24, the Dependent's side of the Remote Alarm
/// Override (`alarm_contract.md`). Reached only via a `remote_alarm` push
/// tap (see `push_service.dart`'s `routeForNotificationType`), so there's
/// no constructor arg: `GET/POST /dependents/{id}/alarm[/stop]` are all
/// "Primary, or the Dependent for themself", and this screen is always
/// the Dependent acting for themself — `dependentId` is just
/// `currentUserProvider`'s own id.
///
/// Two named scope cuts from the mockup, both flagged rather than
/// silently skipped:
/// 1. **No "Call Ali" button.** The mockup's Call button would need the
///    triggering Guardian's phone number, and nothing Task 3.14 reads
///    (alarm_contract.md's `data`/response only carries `triggered_by`,
///    a Guardian user id, not a phone number) resolves that from the
///    Dependent side — `GET /dependents/{id}/guardians` is the Guardian-
///    side screen's own endpoint, not confirmed callable by a Dependent
///    here. Adding that lookup is backend-adjacent follow-up work, not
///    this screen's job.
/// 2. **No native silent-mode bypass / looping ringtone.** "Rings loudly,
///    even on silent" (the mockup's own subtitle) is a platform-level
///    audio override outside what `flutter_local_notifications`'s normal
///    notification sound does. `PushService`'s `critical_alerts` Android
///    channel (max importance, `playSound: true`) already gives this push
///    real sound/heads-up behavior on arrival; this screen's job is the
///    full-screen visual + Stop action once the person has opened it, not
///    a custom audio engine.
class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key});

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> {
  bool _isLoading = true;
  bool _isActive = false;
  DateTime? _expiresAt;
  DateTime _now = DateTime.now();
  Timer? _tickTimer;
  bool _isStopping = false;
  String? _loadError;

  String get _dependentId => ref.read(currentUserProvider)!.userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>('/dependents/$_dependentId/alarm');
      if (!mounted) return;
      final active = response.data?['active'] as bool? ?? false;
      final alarm = response.data?['alarm'] as Map<String, dynamic>?;
      final expiresAt = alarm == null ? null : DateTime.tryParse(alarm['expires_at'] as String? ?? '');
      _tickTimer?.cancel();
      setState(() {
        _isActive = active;
        _expiresAt = expiresAt;
        _now = DateTime.now();
      });
      if (active) {
        _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() => _now = DateTime.now());
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _stopAlarm() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isStopping = true);
    try {
      await ref.read(apiClientProvider).post('/dependents/$_dependentId/alarm/stop');
      _tickTimer?.cancel();
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/dependent');
      }
    } on ApiException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.stopAlarmFailedSnackbar)));
    } finally {
      if (mounted) setState(() => _isStopping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const backgroundColor = HumsafarColors.primaryDark;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(l10n.alarmScreenTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      body: SafeArea(child: _buildBody(l10n)),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: Text(l10n.retryButton)),
            ],
          ),
        ),
      );
    }
    if (!_isActive) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.noActiveAlarmMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.canPop() ? context.pop() : context.go('/dependent'),
                child: Text(l10n.goBackButtonLabel),
              ),
            ],
          ),
        ),
      );
    }

    final remaining = _expiresAt == null ? Duration.zero : _expiresAt!.difference(_now);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    child: const Icon(Icons.notifications, size: 56, color: HumsafarColors.primaryDark),
                  ),
                ),
              ),
            ),
          ),
          Text(
            l10n.alarmLookingForYouTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.alarmScreenSubtitle(formatCountdown(remaining)),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isStopping ? null : _stopAlarm,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: HumsafarColors.primaryDark),
              child: Text(l10n.stopAlarmButtonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
