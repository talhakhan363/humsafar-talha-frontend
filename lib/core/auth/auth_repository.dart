import 'app_user.dart';

/// Real shape, taken directly from docs/api/auth_contract.md and
/// linkage_contract.md (invite_token), confirmed final by Abdullah on
/// 2026-10-16/19 — no longer a guess.
abstract class AuthRepository {
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role, // "guardian" | "dependent"
    String? inviteToken, // Guardians only — makes this a Secondary (Task 1.5)
  });

  Future<AppUser> login({required String email, required String password});

  Future<void> refreshToken();

  Future<void> logout();
}

/// Kept only as a safety net for any code path not yet wired — nothing in
/// the app should construct this directly after Step A; see
/// `providers.dart`, which now returns `RealAuthRepository`.
class UnimplementedAuthRepository implements AuthRepository {
  const UnimplementedAuthRepository();

  @override
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? inviteToken,
  }) =>
      throw UnimplementedError('AuthRepository.register not wired');

  @override
  Future<AppUser> login({required String email, required String password}) => throw UnimplementedError('AuthRepository.login not wired');

  @override
  Future<void> refreshToken() => throw UnimplementedError('AuthRepository.refreshToken not wired');

  @override
  Future<void> logout() => throw UnimplementedError('AuthRepository.logout not wired');
}
