import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
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
/// One named scope cut from the mockup, flagged rather than silently
/// skipped:
/// 1. **No "Call Ali" button.** The mockup's Call button would need the
///    triggering Guardian's phone number, and nothing Task 3.14 reads
///    (alarm_contract.md's `data`/response only carries `triggered_by`,
///    a Guardian user id, not a phone number) resolves that from the
///    Dependent side — `GET /dependents/{id}/guardians` is the Guardian-
///    side screen's own endpoint, not confirmed callable by a Dependent
///    here. Adding that lookup is backend-adjacent follow-up work, not
///    this screen's job.
///
/// **Bug fix (F-13, QA ICP-3 Results v1.1, step 11):** this used to rely
/// entirely on `PushService`'s notification sound for "rings loudly,
/// even on silent" — a plain notification-channel sound plays on the
/// phone's **ringtone/notification** stream, which the Android ringer
/// silent/vibrate toggle *does* mute (that's the whole point of silent
/// mode); it is not the same thing as Do Not Disturb. The **alarm**
/// stream is the one stream Android's own ringer-silent toggle does not
/// touch (why a phone's alarm clock still rings on silent) — this
/// screen now loops [_alarmSound] on that stream itself via
/// `audioplayers`' `AudioContextAndroid(usageType: alarm)`, for as long
/// as the alarm is genuinely active, stopping on a successful Stop, on
/// auto-expiry (`_load`'s own `!active` branch), or on dispose. No new
/// plugin: `audioplayers` is already a dependency (Task 4.8, voice
/// messages). `assets/sounds/alarm.wav` is a short synthesized
/// placeholder tone bundled for this fix, not the final sound design.
///
/// **Unverified against a real build** — this sandbox has no Flutter
/// SDK to run `flutter analyze`/`flutter pub get` against, same
/// disclosed risk as several native-plugin pins in pubspec.yaml. Worth
/// a real-device smoke test before relying on it, and this can only be
/// end-to-end verified once F-16 (real push) ships — right now nothing
/// makes `remote_alarm` actually reach this screen on Ammi's phone.
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
  // (F-13 fix) see the class doc comment.
  final AudioPlayer _alarmSound = AudioPlayer();
  bool _isSoundPlaying = false;

  String get _dependentId => ref.read(currentUserProvider)!.userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _stopAlarmSound();
    _alarmSound.dispose();
    super.dispose();
  }

  /// (F-13 fix) Routes playback through Android's alarm stream, which
  /// the ringer silent/vibrate toggle does not mute — see the class doc
  /// comment for why that is the one stream that actually matters here.
  Future<void> _startAlarmSound() async {
    if (_isSoundPlaying) return;
    _isSoundPlaying = true;
    try {
      // Bug fix (2026-11-07): `audioplayers` 6.6.0's AudioContext
      // constructor isn't const (flutter analyze: "The constructor
      // being called isn't a const constructor" at this line) —
      // dropping `const` on the outer call is the fix, no behavior
      // change. AudioContextAndroid's own constructor IS const, so it
      // keeps its `const` (analyze's prefer_const_constructors info).
      await _alarmSound.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ));
      await _alarmSound.setReleaseMode(ReleaseMode.loop);
      await _alarmSound.play(AssetSource('sounds/alarm.wav'));
    } catch (_) {
      // Never let a platform audio failure take down the alarm screen
      // itself — the visual countdown + Stop button (and whatever the
      // OS's own notification sound did on arrival) still work even if
      // this extra loop can't start on a given device.
      _isSoundPlaying = false;
    }
  }

  Future<void> _stopAlarmSound() async {
    if (!_isSoundPlaying) return;
    _isSoundPlaying = false;
    try {
      await _alarmSound.stop();
    } catch (_) {
      // best-effort, see _startAlarmSound
    }
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
        unawaited(_startAlarmSound());
        _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() => _now = DateTime.now());
          // (F-13 fix) catches auto-expiry even if nobody taps Stop —
          // the countdown reaching zero means the server's own
          // expires_at has passed, so the loop should not outlive it.
          if (_expiresAt != null && !_expiresAt!.isAfter(_now)) {
            unawaited(_stopAlarmSound());
          }
        });
      } else {
        unawaited(_stopAlarmSound());
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
      // Bug fix (2026-11-07, TC-3.14-29): this was `await`ed, so leaving
      // the screen waited on the platform audio call to finish first —
      // in the widget-test environment (no real audio platform channel)
      // that await never resolved, so `context.go('/dependent')` below
      // never ran and the test's navigation check failed. Same fix as
      // `_load()`'s own alarm-sound calls just below: fire-and-forget,
      // consistent with "a platform audio failure never blocks this
      // screen" in the class doc comment — stopping the sound should
      // never be allowed to hold up leaving the screen, on a real
      // device or in a test.
      unawaited(_stopAlarmSound());
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
