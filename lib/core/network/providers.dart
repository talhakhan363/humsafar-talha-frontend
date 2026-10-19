import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_repository.dart';
import '../auth/real_auth_repository.dart';
import '../auth/token_storage.dart';
import 'api_client.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(
    readAccessToken: tokenStorage.readAccessToken,
    readRefreshToken: tokenStorage.readRefreshToken,
    saveTokens: tokenStorage.saveTokens,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return RealAuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    ref: ref,
  );
});
