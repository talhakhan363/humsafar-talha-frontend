/// Defines the shape of the Auth operations Abdullah's Task 1.3 will
/// expose (register, login, JWT issue/refresh — per FR-A1 and the SDS
/// Security Design's "JWT-based stateless authentication"). The
/// INTERFACE is written now, against what's already locked in the spec,
/// so every screen that will eventually call this can be built against a
/// stable contract today.
///
/// The concrete implementation is intentionally left unimplemented below
/// — it gets filled in at Task 2.5, once Abdullah's actual request and
/// response shapes are available in his Postman collection. Do NOT guess
/// those shapes and implement this early; an incorrect guess here is
/// worse than an honest "not implemented yet."
abstract class AuthRepository {
  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  });

  Future<void> login({required String email, required String password});

  Future<void> refreshToken();

  Future<void> logout();
}

/// Placeholder implementation — every method throws until Task 2.5 wires
/// it to Abdullah's real endpoints. Exists so the rest of the app (and
/// Riverpod's provider graph) can be built and tested against the
/// interface today, without anything silently pretending to work against
/// a backend that isn't there yet.
class UnimplementedAuthRepository implements AuthRepository {
  const UnimplementedAuthRepository();

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) =>
      throw UnimplementedError("AuthRepository.register — wire to Abdullah's API at Task 2.5");

  @override
  Future<void> login({required String email, required String password}) =>
      throw UnimplementedError("AuthRepository.login — wire to Abdullah's API at Task 2.5");

  @override
  Future<void> refreshToken() =>
      throw UnimplementedError("AuthRepository.refreshToken — wire to Abdullah's API at Task 2.5");

  @override
  Future<void> logout() =>
      throw UnimplementedError("AuthRepository.logout — wire to Abdullah's API at Task 2.5");
}
