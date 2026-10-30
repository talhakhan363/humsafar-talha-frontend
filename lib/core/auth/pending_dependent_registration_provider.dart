import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Carries a freshly-registered Dependent's id + password forward to the
/// KYC screen. A Dependent has no JWT yet — kyc-verify authenticates with
/// the password directly (kyc_contract.md section 1).
///
/// Bug fix (2026-10-30, found live while click-testing ahead of 1.8): this
/// used to be in-memory only, with this very doc comment naming the exact
/// gap — "if the app closes before KYC completes, this is lost and
/// there's no resume path yet." That happened for real: a dropped debug-
/// tether connection mid-Submit left a throwaway test account
/// (`kyccheck.test@humsafar.dev`) permanently stuck — can't re-register
/// (EMAIL_ALREADY_REGISTERED), can't log in (ACCOUNT_NOT_ACTIVATED), and
/// nothing in the UI led back to KYC. A real Dependent could hit the same
/// gap from a crash, a reboot, or the OS killing a backgrounded app, not
/// just a dev tether.
///
/// Fix: this is now ALSO persisted to [FlutterSecureStorage] (same
/// encrypted-at-rest mechanism as token_storage.dart — this is short-
/// lived, pre-verification credential-adjacent data, so it gets the same
/// treatment as the JWTs, deliberately not shared_preferences) by
/// [PendingDependentRegistrationStorage], written on register and cleared
/// on a verified KYC result. splash_screen.dart checks that storage on
/// every cold start, before falling back to /role-select: if a pending
/// registration is still there, the app routes straight back into
/// /kyc/dependent instead of stranding the user.
///
/// This closes the gap for every FUTURE interruption on the same device.
/// It cannot — and from the frontend alone, never could — recover an
/// account that was already stuck before this fix shipped, since the
/// secure-storage write never happened for that one:
/// `kyccheck.test@humsafar.dev` stays stuck (flagged in the Progress
/// Tracker; it is a throwaway test account, not a real user).
class PendingDependentRegistration {
  const PendingDependentRegistration({required this.dependentId, required this.password});
  final String dependentId;
  final String password;
}

final pendingDependentRegistrationProvider = StateProvider<PendingDependentRegistration?>((ref) => null);

/// Secure, encrypted-at-rest persistence for [PendingDependentRegistration]
/// — see that class's doc comment above for why this exists and what it
/// does and does not fix.
class PendingDependentRegistrationStorage {
  PendingDependentRegistrationStorage({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _idKey = 'humsafar_pending_dependent_id';
  static const _passwordKey = 'humsafar_pending_dependent_password';

  Future<void> save(PendingDependentRegistration pending) async {
    await _storage.write(key: _idKey, value: pending.dependentId);
    await _storage.write(key: _passwordKey, value: pending.password);
  }

  Future<PendingDependentRegistration?> read() async {
    final id = await _storage.read(key: _idKey);
    final password = await _storage.read(key: _passwordKey);
    if (id == null || password == null) return null;
    return PendingDependentRegistration(dependentId: id, password: password);
  }

  Future<void> clear() async {
    await _storage.delete(key: _idKey);
    await _storage.delete(key: _passwordKey);
  }
}

final pendingDependentRegistrationStorageProvider =
    Provider<PendingDependentRegistrationStorage>((ref) => PendingDependentRegistrationStorage());
