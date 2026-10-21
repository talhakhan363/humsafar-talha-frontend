import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../push/push_service.dart';
import 'app_user.dart';
import 'auth_repository.dart';
import 'current_user_provider.dart';
import 'token_storage.dart';

class RealAuthRepository implements AuthRepository {
  RealAuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    required Ref ref,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage,
        _ref = ref;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final Ref _ref;

  @override
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? inviteToken,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>('/auth/register', data: {
      'email': email,
      'phone': phone,
      'password': password,
      'full_name': fullName,
      'role': role,
      if (inviteToken != null) 'invite_token': inviteToken,
    });
    // Register does NOT return tokens (auth_contract.md §2) — caller must
    // follow up with login for a Guardian, or go straight to KYC for a
    // Dependent (who can't log in until verified + linked anyway).
    return AppUser.fromJson(response.data!);
  }

  @override
  Future<AppUser> login({required String email, required String password}) async {
    final response = await _apiClient.post<Map<String, dynamic>>('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final body = response.data!;
    await _tokenStorage.saveTokens(
      accessToken: body['access_token'] as String,
      refreshToken: body['refresh_token'] as String,
    );
    final user = AppUser.fromJson(body['user'] as Map<String, dynamic>);
    _ref.read(currentUserProvider.notifier).state = user;
    // Task 3.14 — "call after every login" (notification_contract.md).
    // Best-effort by design (see push_service.dart's doc comment): never
    // allowed to fail a login over a push-registration hiccup.
    await registerPushToken(_ref.read);
    return user;
  }

  @override
  Future<void> refreshToken() async {
    // No-op by design: ApiClient refreshes transparently inside _wrap on a
    // TOKEN_EXPIRED response. This stays on the interface for an explicit
    // "refresh on app resume" caller, not used by Step A/B.
  }

  @override
  Future<void> logout() async {
    // Task 3.14 — "call on logout" (notification_contract.md), and must
    // happen BEFORE clearing tokens below: unregistering needs a still-
    // valid access token to authenticate the DELETE call.
    await unregisterPushToken(_ref.read);
    await _tokenStorage.clear();
    _ref.read(currentUserProvider.notifier).state = null;
  }
}
