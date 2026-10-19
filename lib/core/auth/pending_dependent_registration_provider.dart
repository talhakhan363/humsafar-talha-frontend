import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Carries a freshly-registered Dependent's id + password forward to the
/// KYC screen. A Dependent has no JWT yet — kyc-verify authenticates with
/// the password directly (kyc_contract.md section 1) — so this is NOT a
/// token and must never be persisted to disk or logged; it lives in memory
/// only for the single register -> KYC hop.
///
/// Known gap, named deliberately: if the app closes before KYC completes,
/// this is lost and there's no resume path yet. Out of scope for today.
class PendingDependentRegistration {
  const PendingDependentRegistration({required this.dependentId, required this.password});
  final String dependentId;
  final String password;
}

final pendingDependentRegistrationProvider = StateProvider<PendingDependentRegistration?>((ref) => null);
